import AppKit
import SwiftUI
import Observation

/// Owns a single dashboard drag. AppKit captures input; SwiftUI renders card offsets.
@MainActor @Observable final class AccountDragging {
    private(set) var activeID: String?
    private(set) var offsets: [String: CGFloat] = [:]
    private(set) var moving = false
    private(set) var finishing = false
    @ObservationIgnored private var markers: [String: WeakMarker] = [:]
    @ObservationIgnored private var ids: [String] = []
    @ObservationIgnored private var layout: AccountDragLayout?
    @ObservationIgnored private weak var scroll: NSScrollView?
    @ObservationIgnored private weak var window: NSWindow?
    @ObservationIgnored private var origin = NSPoint.zero
    @ObservationIgnored private var pointer = NSPoint.zero
    @ObservationIgnored private var startScroll = NSPoint.zero
    @ObservationIgnored private var firstTop: CGFloat = 0
    @ObservationIgnored private var sourceTop: CGFloat = 0
    @ObservationIgnored private var monitor: Any?
    @ObservationIgnored private var timer: Timer?
    @ObservationIgnored private var observers: [NSObjectProtocol] = []
    @ObservationIgnored private var commit: ((Int) async -> Void)?

    private final class WeakMarker {
        weak var view: NSView?
        init(_ view: NSView) { self.view = view }
    }

    func register(_ view: NSView, id: String) { markers[id] = WeakMarker(view) }
    func unregister(_ view: NSView, id: String) {
        if markers[id]?.view === view {
            markers.removeValue(forKey: id)
            cancel()
        }
    }

    func begin(id: String, ids: [String], event: NSEvent, commit: @escaping (Int) async -> Void) {
        guard activeID == nil, let source = markers[id]?.view,
              let scroll = source.enclosingScrollView, let document = scroll.documentView,
              let window = source.window, let index = ids.firstIndex(of: id) else { return }
        let views = ids.compactMap { markers[$0]?.view }
        guard views.count == ids.count, views.allSatisfy({ $0.window === window }),
              let layout = AccountDragLayout(heights: views.map { $0.bounds.height }, sourceIndex: index, spacing: 20) else { return }
        self.scroll = scroll; self.window = window; self.ids = ids; self.layout = layout
        self.commit = commit
        startScroll = scroll.contentView.bounds.origin
        pointer = event.locationInWindow
        origin = pointInDocument(pointer, document)
        firstTop = topOfView(views[0], in: document)
        sourceTop = topOfView(source, in: document)
        activeID = id
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDragged, .leftMouseUp, .keyDown]) { [weak self] event in
            guard let self, self.activeID != nil, !self.finishing else { return event }
            if event.type == .keyDown {
                if event.keyCode == 53 { self.cancel(); return nil }
                return event
            }
            guard event.window === self.window else { self.cancel(); return event }
            self.pointer = event.locationInWindow
            self.update()
            if event.type == .leftMouseUp { self.finish(save: self.moving && self.insideViewport) }
            return nil
        }
        for name in [NSWindow.didResizeNotification, NSWindow.didResignKeyNotification, NSWindow.willCloseNotification] {
            observers.append(NotificationCenter.default.addObserver(forName: name, object: window, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.cancel() }
            })
        }
        timer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        if let timer { RunLoop.main.add(timer, forMode: .common) }
    }

    private func pointInDocument(_ point: NSPoint, _ document: NSView) -> NSPoint {
        let p = document.convert(point, from: nil)
        return NSPoint(x: p.x, y: document.isFlipped ? p.y : document.bounds.maxY - p.y)
    }
    private func topOfView(_ view: NSView, in document: NSView) -> CGFloat {
        let rect = document.convert(view.bounds, from: view)
        return document.isFlipped ? rect.minY : document.bounds.maxY - rect.maxY
    }
    private var insideViewport: Bool {
        guard let scroll else { return false }
        return scroll.contentView.bounds.contains(scroll.contentView.convert(pointer, from: nil))
    }
    private func update() {
        guard !finishing, let id = activeID, let document = scroll?.documentView, var layout else { return }
        let current = pointInDocument(pointer, document)
        let delta = current.y - origin.y
        if !moving {
            guard abs(delta) + abs(current.x - origin.x) >= 5 else { return }
            moving = true
        }
        // Pointer motion is immediate; only displaced neighbors animate.
        var transaction = Transaction(); transaction.disablesAnimations = true
        withTransaction(transaction) { offsets[id] = delta }
        guard insideViewport else { return }
        if layout.move(centerY: sourceTop - firstTop + delta + layout.heights[layout.sourceIndex] / 2) {
            withAnimation(.timingCurve(0.215, 0.61, 0.355, 1, duration: 0.11)) {
                for (index, other) in ids.enumerated() where other != id {
                    offsets[other] = layout.tops[index] - layout.originalTops[index]
                }
            }
        }
        self.layout = layout
    }
    private func tick() {
        guard moving, !finishing, insideViewport, let scroll, let document = scroll.documentView else { return }
        let rect = scroll.contentView.convert(scroll.contentView.bounds, to: nil)
        let step = AccountDragLayout.scrollStep(pointerY: -pointer.y, top: -rect.maxY, bottom: -rect.minY)
        if step != 0 {
            var point = scroll.contentView.bounds.origin
            let maxY = max(document.bounds.minY, document.bounds.maxY - scroll.contentView.bounds.height)
            point.y = min(maxY, max(document.bounds.minY, point.y + (document.isFlipped ? step : -step)))
            scroll.contentView.scroll(to: point)
            scroll.reflectScrolledClipView(scroll.contentView)
        }
        update()
    }
    func cancel() { if activeID != nil && !finishing { finish(save: false) } }
    private func finish(save: Bool) {
        guard let layout, let id = activeID, !finishing else { return }
        finishing = true
        stopInput()
        if !save, let scroll {
            scroll.contentView.scroll(to: startScroll)
            scroll.reflectScrolledClipView(scroll.contentView)
        }
        withAnimation(.timingCurve(0.215, 0.61, 0.355, 1, duration: 0.14)) {
            if save { offsets[id] = layout.tops[layout.sourceIndex] - layout.originalTops[layout.sourceIndex] }
            else { offsets = [:] }
        }
        let commit = self.commit
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(140))
            if save && layout.slot != layout.sourceIndex { await commit?(layout.slot) }
            var transaction = Transaction(); transaction.disablesAnimations = true
            withTransaction(transaction) {
                offsets = [:]; activeID = nil; moving = false; finishing = false
            }
            self.layout = nil; self.commit = nil; ids = []; scroll = nil; window = nil
        }
    }
    private func stopInput() {
        timer?.invalidate(); timer = nil
        if let monitor { NSEvent.removeMonitor(monitor); self.monitor = nil }
        observers.forEach(NotificationCenter.default.removeObserver); observers = []
    }
}

struct AccountDragMarker: NSViewRepresentable {
    let id: String
    let dragging: AccountDragging
    func makeNSView(context: Context) -> Marker {
        let view = Marker()
        view.onResize = { [weak dragging] in dragging?.cancel() }
        dragging.register(view, id: id)
        context.coordinator.id = id; context.coordinator.dragging = dragging
        return view
    }
    func updateNSView(_ view: Marker, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator() }
    static func dismantleNSView(_ view: Marker, coordinator: Coordinator) {
        coordinator.dragging?.unregister(view, id: coordinator.id)
    }
    final class Marker: NSView {
        var onResize: (() -> Void)?
        override func hitTest(_ point: NSPoint) -> NSView? { nil }
        override func setFrameSize(_ newSize: NSSize) {
            let changed = frame.size != newSize && frame.width > 0 && frame.height > 0
            super.setFrameSize(newSize)
            if changed { Task { @MainActor [weak self] in self?.onResize?() } }
        }
    }
    final class Coordinator {
        var id = ""
        weak var dragging: AccountDragging?
    }
}

struct AccountDragGrip: NSViewRepresentable {
    let label: String
    let begin: (NSEvent) -> Void
    func makeNSView(context: Context) -> Grip { Grip() }
    func updateNSView(_ view: Grip, context: Context) {
        view.begin = begin
        view.setAccessibilityElement(true)
        view.setAccessibilityRole(.group)
        view.setAccessibilityLabel(label)
    }
    final class Grip: NSView {
        var begin: ((NSEvent) -> Void)?
        override var acceptsFirstResponder: Bool { true }
        override func mouseDown(with event: NSEvent) { begin?(event) }
    }
}
