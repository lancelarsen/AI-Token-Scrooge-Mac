import SwiftUI
import QuartzCore

/// A non-interactive tracking surface: event buttons and scrolling retain hit testing.
struct HistoryPointerTracking: NSViewRepresentable {
    var severity: ReminderSeverity? = nil
    var plainText = false
    var resetContent: ResetTooltipContent? = nil
    var text: String? = nil
    var pinned = false
    var anchor: CGPoint? = nil
    var onMove: (CGPoint?) -> Void

    func makeNSView(context: Context) -> TrackingView {
        let view = TrackingView()
        view.onMove = onMove
        return view
    }

    func updateNSView(_ view: TrackingView, context: Context) {
        view.onMove = onMove
        view.pinned = pinned
        view.severity = severity
        view.plainText = plainText
        view.resetContent = resetContent
        if let anchor { view.pointer = anchor }
        view.popupText = text
        view.showPopup(text)
    }
    static func dismantleNSView(_ view: TrackingView, coordinator: ()) { view.stopObserving(); view.hidePopup() }

    final class TrackingView: NSView {
        var onMove: ((CGPoint?) -> Void)?
        private var area: NSTrackingArea?
        private var popup: NSPanel?
        private struct ContentKey: Equatable {
            let text: String
            let severity: ReminderSeverity?
            let plainText: Bool
            let reset: ResetTooltipContent?
            let width: CGFloat
        }
        private var renderedContent: ContentKey?
        private static weak var popupOwner: TrackingView?
        private var dismissalObserver: NSObjectProtocol?
        private var pressMonitor: Any?
        var pointer = NSPoint.zero
        var pinned = false
        var severity: ReminderSeverity?
        var plainText = false
        var resetContent: ResetTooltipContent?
        var popupText: String?
        private var thresholdPlacement = ThresholdPopupPlacement()
        func hidePopup() { popup?.orderOut(nil); thresholdPlacement.reset() }
        func showPopup(_ text: String?) {
            guard let text, let window, window.isKeyWindow, let screen = window.screen else { hidePopup(); return }
            guard !isHiddenOrHasHiddenAncestor,
                  !bounds.intersection(visibleRect).isEmpty,
                  !convert(bounds, to: nil).intersection(window.contentLayoutRect).isEmpty else {
                hidePopup()
                return
            }
            if let previous = Self.popupOwner, previous !== self { previous.hidePopup() }
            Self.popupOwner = self
            let panel = popup ?? NSPanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: true)
            if popup == nil {
                panel.isOpaque = false; panel.backgroundColor = .clear
                panel.title = "Usage History Details"
                panel.hasShadow = true; panel.ignoresMouseEvents = true
                panel.level = .floating; popup = panel
            }
            panel.hasShadow = severity == nil
            panel.title = severity != nil ? "Alert Threshold Details" : plainText ? "Help Details" : "Usage History Details"
            // Keep details within the owning app, including when it occupies only part of a screen.
            let contentBounds = window.convertToScreen(window.contentLayoutRect)
            let visible = contentBounds.intersection(screen.visibleFrame).insetBy(dx: severity == nil ? 8 : 4, dy: severity == nil ? 8 : 0)
            guard visible.width > 0, visible.height > 0 else { hidePopup(); return }
            let lines = text.split(separator: "\n", maxSplits: 1).map(String.init)
            let lineWidths = text.components(separatedBy: "\n").enumerated().map { index, line in
                (line as NSString).size(withAttributes: [.font: ReferenceTypography.measuringFont(ofSize: index == 0 && !plainText ? 14 : 13,
                    weight: index == 0 && !plainText ? .semibold : .regular)]).width
            }
            let popupWidth = resetContent?.width(available: visible.width) ?? (plainText ? ReferenceHelpTooltip.width(for: text, availableWidth: visible.width) :
                min(420, visible.width, ceil((lineWidths.max() ?? 0) + 30 + (severity == nil ? 0 : 26))))
            let contentKey = ContentKey(text: text, severity: severity, plainText: plainText,
                                        reset: resetContent, width: popupWidth)
            if renderedContent != contentKey || panel.contentView == nil {
                let content = NSHostingView(rootView:
                Group {
                    if let resetContent {
                        ReferenceResetTooltip(content: resetContent, width: popupWidth)
                    } else if plainText {
                        ReferenceHelpTooltip(text: text, width: popupWidth)
                    } else {
                        VStack(alignment: .leading, spacing: 5) {
                            HStack(spacing: 8) {
                                if let severity { ThresholdReadoutIcon(severity: severity) }
                                Text(lines.first ?? "").font(.reference(size: 14, weight: .semibold)).foregroundStyle(severity == nil ? Color(hex: "#F2F1F5") : .white)
                            }
                            if lines.count > 1 { Text(lines[1]).font(.reference(size: 13)).foregroundStyle(Theme.dialogText) }
                        }.padding(.horizontal, 14).padding(.vertical, 10).padding(1).frame(width: popupWidth, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .background(Color(hex: "#222329"), in: RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color(hex: "#65577F"), lineWidth: 1))
                    }
                })
                panel.contentView = content
                renderedContent = contentKey
            }
            guard let content = panel.contentView else { return }
            let size = content.fittingSize
            let anchor = window.convertPoint(toScreen: convert(pointer, to: nil))
            let x = min(max(visible.minX, anchor.x - size.width / 2), visible.maxX - size.width)
            let above = anchor.y + (severity == nil ? 14 : 2)
            let y = min(max(visible.minY, above + size.height <= visible.maxY ? above : anchor.y - size.height - 18), visible.maxY - size.height)
            let frame = severity == nil ? NSRect(origin: NSPoint(x: x, y: y), size: size) :
                thresholdPlacement.frame(anchor: anchor, size: size, contentBounds: contentBounds.intersection(screen.visibleFrame))
            panel.setFrame(frame, display: true)
            panel.orderFront(nil)
        }
        override var isFlipped: Bool { true }
        override func hitTest(_ point: NSPoint) -> NSView? { nil }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            stopObserving()
            if let window {
                dismissalObserver = NotificationCenter.default.addObserver(forName: NSWindow.didResignKeyNotification, object: window, queue: .main) { [weak self] _ in
                    MainActor.assumeIsolated {
                        self?.hidePopup()
                        self?.onMove?(nil)
                    }
                }
                pressMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]) { [weak self] event in
                    guard let self, self.plainText, event.window === self.window else { return event }
                    self.hidePopup()
                    self.onMove?(nil)
                    return event
                }
            }
            // Tracking areas need the hosting window to deliver ordinary pointer movement.
            window?.acceptsMouseMovedEvents = true
            if window == nil { hidePopup() } else { showPopup(popupText) }
        }

        func stopObserving() {
            if let dismissalObserver { NotificationCenter.default.removeObserver(dismissalObserver) }
            dismissalObserver = nil
            if let pressMonitor { NSEvent.removeMonitor(pressMonitor) }
            pressMonitor = nil
        }

        override func updateTrackingAreas() {
            super.updateTrackingAreas()
            if let area { removeTrackingArea(area) }
            let replacement = NSTrackingArea(rect: .zero,
                options: [.mouseMoved, .mouseEnteredAndExited, .activeAlways, .inVisibleRect],
                owner: self, userInfo: nil)
            addTrackingArea(replacement)
            area = replacement
            if popup?.isVisible == true { showPopup(popupText) }
        }

        override func mouseEntered(with event: NSEvent) { mouseMoved(with: event) }
        override func mouseMoved(with event: NSEvent) {
            guard !pinned, window?.isKeyWindow == true else { return }
            pointer = convert(event.locationInWindow, from: nil)
            onMove?(pointer)
        }
        override func mouseExited(with event: NSEvent) { if !pinned { hidePopup(); onMove?(nil) } }
    }
}


/// Routes wheel events only within the visible Horizon card, leaving other views untouched.
struct HorizonWheelRouting: NSViewRepresentable {
    var onScroll: (Double) -> Void
    func makeNSView(context: Context) -> WheelView {
        let view = WheelView()
        view.onScroll = onScroll
        return view
    }
    func updateNSView(_ view: WheelView, context: Context) { view.onScroll = onScroll }
    static func dismantleNSView(_ view: WheelView, coordinator: ()) { view.stopMonitoring() }

    final class WheelView: NSView {
        var onScroll: ((Double) -> Void)?
        private var monitor: Any?
        private var motionDisplayLink: CADisplayLink?
        private var motion = HorizonWheelMotion()
        private var lastFrame = 0.0
        override func hitTest(_ point: NSPoint) -> NSView? { nil }
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            stopMonitoring()
            guard window != nil else { return }
            monitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
                guard let self, let window = self.window,
                      event.window === window, window.attachedSheet == nil,
                      !self.isHiddenOrHasHiddenAncestor,
                      self.bounds.intersection(self.visibleRect).contains(self.convert(event.locationInWindow, from: nil)) else { return event }
                let delta = Self.horizontalDelta(x: event.scrollingDeltaX, y: event.scrollingDeltaY, precise: event.hasPreciseScrollingDeltas)
                if event.hasPreciseScrollingDeltas || NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
                    self.stopAnimation()
                    self.onScroll?(delta)
                } else {
                    self.motion.enqueue(delta)
                    self.startAnimation()
                }
                return nil
            }
        }
        override func viewDidHide() {
            super.viewDidHide()
            stopAnimation()
        }
        private func startAnimation() {
            guard motionDisplayLink == nil else { return }
            lastFrame = CACurrentMediaTime()
            // Follow the refresh cadence of the display hosting this view instead
            // of issuing unsynchronized 120 Hz updates on every kind of screen.
            let next = displayLink(target: self, selector: #selector(advanceScroll(_:)))
            motionDisplayLink = next
            next.add(to: .main, forMode: .common)
        }
        @objc private func advanceScroll(_ link: CADisplayLink) {
            guard let window, window.attachedSheet == nil, !isHiddenOrHasHiddenAncestor else { stopAnimation(); return }
            let now = link.targetTimestamp
            let delta = motion.step(seconds: now - lastFrame)
            lastFrame = now
            if delta != 0 { onScroll?(delta) }
            if motion.remaining == 0 { stopAnimation() }
        }
        private func stopAnimation() { motionDisplayLink?.invalidate(); motionDisplayLink = nil; motion.cancel() }
        func stopMonitoring() {
            stopAnimation()
            if let monitor { NSEvent.removeMonitor(monitor) }
            monitor = nil
        }
        static func horizontalDelta(x: Double, y: Double, precise: Bool) -> Double {
            // Keep native horizontal gestures; map vertical wheels to the same axis.
            -(abs(x) > abs(y) ? x : y) * (precise ? 1 : 20)
        }
    }
}
