import CoreGraphics
import SwiftUI
import Testing
@testable import ChatBubbles

@MainActor
@Suite("Bubble corners")
struct BubbleCornersTests {
    private func corners(_ position: BubblePosition, outgoing: Bool) -> BubbleCorners {
        BubbleCorners(position: position, isOutgoing: outgoing, radius: 18, groupedRadius: 5)
    }

    @Test func singleBubblesAreRoundEverywhere() {
        #expect(corners(.single, outgoing: true) == BubbleCorners(all: 18))
        #expect(corners(.single, outgoing: false) == BubbleCorners(all: 18))
    }

    @Test func outgoingGroupsTightenTheTrailingSide() {
        #expect(corners(.first, outgoing: true) == BubbleCorners(topLeading: 18, topTrailing: 18, bottomLeading: 18, bottomTrailing: 5))
        #expect(corners(.middle, outgoing: true) == BubbleCorners(topLeading: 18, topTrailing: 5, bottomLeading: 18, bottomTrailing: 5))
        #expect(corners(.last, outgoing: true) == BubbleCorners(topLeading: 18, topTrailing: 5, bottomLeading: 18, bottomTrailing: 18))
    }

    @Test func incomingGroupsTightenTheLeadingSide() {
        #expect(corners(.first, outgoing: false) == BubbleCorners(topLeading: 18, topTrailing: 18, bottomLeading: 5, bottomTrailing: 18))
        #expect(corners(.middle, outgoing: false) == BubbleCorners(topLeading: 5, topTrailing: 18, bottomLeading: 5, bottomTrailing: 18))
        #expect(corners(.last, outgoing: false) == BubbleCorners(topLeading: 5, topTrailing: 18, bottomLeading: 18, bottomTrailing: 18))
    }

    @Test func incomingIsTheMirrorOfOutgoing() {
        for position in BubblePosition.allCases {
            #expect(corners(position, outgoing: false) == corners(position, outgoing: true).mirrored)
        }
    }

    @Test func clampingKeepsSmallBubblesValid() {
        let clamped = BubbleCorners(topLeading: 30, topTrailing: -2, bottomLeading: 10, bottomTrailing: 18).clamped(to: 12)
        #expect(clamped == BubbleCorners(topLeading: 12, topTrailing: 0, bottomLeading: 10, bottomTrailing: 12))
    }

    @Test func onlyGroupEndsGetATail() {
        let tails = BubblePosition.allCases.map { position in
            BubbleShape(position: position, isOutgoing: true).showsTail
        }
        #expect(tails == [true, false, false, true])
        let withoutTails = BubbleShape(position: .last, isOutgoing: true, showsTail: false)
        #expect(withoutTails.showsTail == false)
    }

    @Test func theShapeStaysInsideItsRect() {
        let rect = CGRect(x: 0, y: 0, width: 200, height: 60)
        for position in BubblePosition.allCases {
            for outgoing in [true, false] {
                let shape = BubbleShape(position: position, isOutgoing: outgoing)
                let bounds = shape.path(in: rect).boundingRect
                #expect(bounds.minX >= rect.minX - 0.5)
                #expect(bounds.maxX <= rect.maxX + 0.5)
                #expect(bounds.minY >= rect.minY - 0.5)
                #expect(bounds.maxY <= rect.maxY + 0.5)
            }
        }
    }

    @Test func theTailReachesTheSendersEdge() {
        let rect = CGRect(x: 0, y: 0, width: 200, height: 60)
        let outgoing = BubbleShape(position: .last, isOutgoing: true).path(in: rect).boundingRect
        #expect(abs(outgoing.maxX - rect.maxX) < 0.5)
        let incoming = BubbleShape(position: .last, isOutgoing: false).path(in: rect).boundingRect
        #expect(abs(incoming.minX - rect.minX) < 0.5)
        // Without a tail the strip on the sender's side stays empty.
        let middle = BubbleShape(position: .middle, isOutgoing: true).path(in: rect).boundingRect
        #expect(abs(middle.maxX - (rect.maxX - 6)) < 0.5)
    }

    @Test func anEmptyRectGivesAnEmptyPath() {
        let path = BubbleShape(position: .single, isOutgoing: true).path(in: .zero)
        #expect(path.isEmpty)
    }
}
