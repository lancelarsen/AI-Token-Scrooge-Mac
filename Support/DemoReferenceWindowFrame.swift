import SwiftUI
import AppKit

/// Applies an explicit capture size after this dashboard actually attaches to
/// its window. App activation can happen before SwiftUI creates that window.
struct DemoReferenceWindowFrame: NSViewRepresentable {
    let size: NSSize

    func makeNSView(context: Context) -> FrameView { FrameView(size: size) }
    func updateNSView(_ view: FrameView, context: Context) {}

    final class FrameView: NSView {
        let requestedSize: NSSize
        private weak var sizedWindow: NSWindow?

        init(size: NSSize) {
            requestedSize = size
            super.init(frame: .zero)
        }
        required init?(coder: NSCoder) { nil }
        override func hitTest(_ point: NSPoint) -> NSView? { nil }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            guard let window, sizedWindow !== window else { return }
            DispatchQueue.main.async { [weak self, weak window] in
                guard let self, let window, self.window === window,
                      self.sizedWindow !== window else { return }
                self.sizedWindow = window
                var frame = window.frame
                frame.origin.y += frame.height - self.requestedSize.height
                frame.size = self.requestedSize
                window.setFrame(frame, display: true)
            }
        }
    }
}
