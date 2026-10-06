import SwiftUI

/// A chat bubble: a rectangle with its own radius on every corner and an optional tail at the
/// bottom corner on the sender's side.
///
/// The tail is drawn in a strip `tailWidth` wide on the sender's side, and the body of the bubble
/// fills the rest of the rectangle. Pad the content by `tailWidth` on that side.
///
/// ```swift
/// Text("Hi!")
///     .padding(12)
///     .padding(.trailing, 6)
///     .background(BubbleShape(position: .last, isOutgoing: true).fill(.blue))
/// ```
public struct BubbleShape: Shape {
    public let corners: BubbleCorners
    public let side: BubbleSide
    public let showsTail: Bool
    public let tailWidth: CGFloat

    public init(corners: BubbleCorners, side: BubbleSide, showsTail: Bool = true, tailWidth: CGFloat = 6) {
        self.corners = corners
        self.side = side
        self.showsTail = showsTail
        self.tailWidth = tailWidth
    }

    /// The shape of a bubble at `position`, with the tail when the position ends a group.
    public init(
        position: BubblePosition,
        isOutgoing: Bool,
        radius: CGFloat = 18,
        groupedRadius: CGFloat = 5,
        showsTail: Bool = true,
        tailWidth: CGFloat = 6
    ) {
        self.init(
            corners: BubbleCorners(position: position, isOutgoing: isOutgoing, radius: radius, groupedRadius: groupedRadius),
            side: isOutgoing ? .trailing : .leading,
            showsTail: showsTail && position.isGroupEnd,
            tailWidth: tailWidth
        )
    }

    nonisolated public func path(in rect: CGRect) -> Path {
        BubbleGeometry.path(in: rect, corners: corners, side: side, showsTail: showsTail, tailWidth: tailWidth)
    }
}

/// The geometry of ``BubbleShape``, kept outside the view so it has no actor isolation.
enum BubbleGeometry {
    static func path(in rect: CGRect, corners: BubbleCorners, side: BubbleSide, showsTail: Bool, tailWidth: CGFloat) -> Path {
        switch side {
        case .trailing:
            return trailingPath(in: rect, corners: corners, showsTail: showsTail, tailWidth: tailWidth)
        case .leading:
            // Draw the trailing bubble with mirrored corners, then flip it horizontally.
            let path = trailingPath(in: rect, corners: corners.mirrored, showsTail: showsTail, tailWidth: tailWidth)
            let flip = CGAffineTransform(a: -1, b: 0, c: 0, d: 1, tx: rect.minX + rect.maxX, ty: 0)
            return path.applying(flip)
        }
    }

    /// A bubble whose tail points to the bottom trailing corner.
    private static func trailingPath(in rect: CGRect, corners: BubbleCorners, showsTail: Bool, tailWidth: CGFloat) -> Path {
        let tail = max(0, min(tailWidth, rect.width / 3))
        let body = CGRect(x: rect.minX, y: rect.minY, width: max(0, rect.width - tail), height: rect.height)
        guard body.width > 0, body.height > 0 else { return Path() }

        let radii = corners.clamped(to: min(body.width, body.height) / 2)
        var path = Path()
        path.move(to: CGPoint(x: body.minX + radii.topLeading, y: body.minY))
        path.addLine(to: CGPoint(x: body.maxX - radii.topTrailing, y: body.minY))
        path.addArc(
            tangent1End: CGPoint(x: body.maxX, y: body.minY),
            tangent2End: CGPoint(x: body.maxX, y: body.maxY),
            radius: radii.topTrailing
        )

        if showsTail && tail > 0 {
            // Down the trailing edge, out to the tip in the bottom trailing corner of `rect`, then
            // back along a soft curve into the bottom edge.
            let tailHeight = max(0, min(16, body.height - radii.topTrailing))
            let tip = CGPoint(x: rect.maxX, y: body.maxY)
            let rejoin = CGPoint(x: max(body.minX + radii.bottomLeading, body.maxX - tail * 2), y: body.maxY)
            path.addLine(to: CGPoint(x: body.maxX, y: body.maxY - tailHeight))
            path.addCurve(
                to: tip,
                control1: CGPoint(x: body.maxX, y: body.maxY - tailHeight * 0.3),
                control2: CGPoint(x: body.maxX + tail * 0.3, y: body.maxY - 0.5)
            )
            path.addQuadCurve(
                to: rejoin,
                control: CGPoint(x: body.maxX - tail * 0.5, y: body.maxY - 3.5)
            )
        } else {
            path.addLine(to: CGPoint(x: body.maxX, y: body.maxY - radii.bottomTrailing))
            path.addArc(
                tangent1End: CGPoint(x: body.maxX, y: body.maxY),
                tangent2End: CGPoint(x: body.minX, y: body.maxY),
                radius: radii.bottomTrailing
            )
        }

        path.addLine(to: CGPoint(x: body.minX + radii.bottomLeading, y: body.maxY))
        path.addArc(
            tangent1End: CGPoint(x: body.minX, y: body.maxY),
            tangent2End: CGPoint(x: body.minX, y: body.minY),
            radius: radii.bottomLeading
        )
        path.addLine(to: CGPoint(x: body.minX, y: body.minY + radii.topLeading))
        path.addArc(
            tangent1End: CGPoint(x: body.minX, y: body.minY),
            tangent2End: CGPoint(x: body.maxX, y: body.minY),
            radius: radii.topLeading
        )
        path.closeSubpath()
        return path
    }
}
