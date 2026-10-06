import AppKit
import ChatBubbles
import SwiftUI

extension ScreenshotScene {
    /// The window size in points.
    var windowSize: CGSize {
        CGSize(width: 1180, height: 760)
    }
}

/// A soft background with the app as a window card: a title bar with traffic lights, then Huddle
/// with the sidebar of chats and the Launch Crew conversation.
private struct ScreenshotBackdrop: View {
    let scene: ScreenshotScene
    let store: ChatStore

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.74, green: 0.86, blue: 1.0), Color(red: 0.86, green: 0.80, blue: 1.0)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    Circle().fill(Color(red: 1.0, green: 0.37, blue: 0.34))
                    Circle().fill(Color(red: 1.0, green: 0.74, blue: 0.18))
                    Circle().fill(Color(red: 0.16, green: 0.79, blue: 0.25))
                    Spacer()
                }
                .frame(height: 12)
                .padding(.horizontal, 14)
                .frame(height: 30)
                .background(Color(red: 0.93, green: 0.93, blue: 0.94))

                MacWorkspaceView(store: store)
            }
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.black.opacity(0.12), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
            .padding(32)
        }
        .frame(width: scene.windowSize.width, height: scene.windowSize.height)
        .ignoresSafeArea()
        .environment(\.colorScheme, .light)
        .typingIndicatorFrozen(at: 0.3)
    }
}

/// The window a screenshot scene is shown in, and the renderer that turns it into a PNG.
@MainActor
final class ScreenshotWindow {
    private let window: NSWindow

    init(scene: ScreenshotScene, renderPath: String?) {
        let store = ChatStore.screenshot(scene)

        // A borderless window: no title bar inset and no rounded window corners in the capture.
        window = NSWindow(
            contentRect: NSRect(origin: .zero, size: scene.windowSize),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.title = "Huddle – \(scene.rawValue)"
        window.hasShadow = false
        window.appearance = NSAppearance(named: .aqua)
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: ScreenshotBackdrop(scene: scene, store: store))
        window.setContentSize(scene.windowSize)
        window.center()

        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate()
        window.makeKeyAndOrderFront(nil)

        Task {
            // The WindowGroup's own window is hidden by WindowHider; make sure nothing else is shown.
            try? await Task.sleep(for: .seconds(1))
            for other in NSApplication.shared.windows where other !== self.window && other.isVisible {
                other.orderOut(nil)
            }
            // Give SwiftUI and AppKit time to lay out, scroll to the newest message and draw the symbols.
            try? await Task.sleep(for: .seconds(2))
            if let renderPath {
                self.render(to: renderPath)
            }
        }
    }

    /// Draws the window's content view into a 2x bitmap, refuses a blank result, writes the PNG
    /// and quits. Exits with status 1 on any failure so the CI script can retry or give up.
    private func render(to path: String) {
        guard let view = window.contentView else { return fail("The window has no content view") }
        view.layoutSubtreeIfNeeded()
        view.displayIfNeeded()

        let bounds = view.bounds
        let scale: CGFloat = 2
        guard bounds.width > 0, bounds.height > 0,
              let bitmap = NSBitmapImageRep(
                  bitmapDataPlanes: nil,
                  pixelsWide: Int(bounds.width * scale),
                  pixelsHigh: Int(bounds.height * scale),
                  bitsPerSample: 8,
                  samplesPerPixel: 4,
                  hasAlpha: true,
                  isPlanar: false,
                  colorSpaceName: .deviceRGB,
                  bytesPerRow: 0,
                  bitsPerPixel: 0
              )
        else { return fail("Could not create a bitmap for \(bounds)") }

        // The bitmap's size in points against its pixel size makes the view draw at 2x.
        bitmap.size = bounds.size
        view.cacheDisplay(in: bounds, to: bitmap)

        guard Self.distinctColorCount(in: bitmap) > 24 else {
            return fail("The rendered image is blank")
        }
        guard let png = bitmap.representation(using: .png, properties: [:]) else {
            return fail("Could not encode the PNG")
        }
        do {
            try png.write(to: URL(fileURLWithPath: path), options: .atomic)
        } catch {
            return fail("Could not write \(path): \(error.localizedDescription)")
        }
        print("Rendered \(path) (\(bitmap.pixelsWide)x\(bitmap.pixelsHigh), \(png.count) bytes)")
        exit(0)
    }

    /// Samples a grid of pixels. A blank or single-color image has only a handful of colors.
    private static func distinctColorCount(in bitmap: NSBitmapImageRep) -> Int {
        var colors = Set<UInt32>()
        let step = max(1, min(bitmap.pixelsWide, bitmap.pixelsHigh) / 60)
        for y in stride(from: 0, to: bitmap.pixelsHigh, by: step) {
            for x in stride(from: 0, to: bitmap.pixelsWide, by: step) {
                guard let color = bitmap.colorAt(x: x, y: y)?.usingColorSpace(.deviceRGB) else { continue }
                colors.insert(channel(color.redComponent) << 16 | channel(color.greenComponent) << 8 | channel(color.blueComponent))
            }
        }
        return colors.count
    }

    private static func channel(_ component: CGFloat) -> UInt32 {
        UInt32(min(255, max(0, (component * 255).rounded())))
    }

    private func fail(_ message: String) {
        FileHandle.standardError.write(Data("Screenshot failed: \(message)\n".utf8))
        exit(1)
    }
}
