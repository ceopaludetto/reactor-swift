import Nimble
import Quick

@testable import Reactor

class PeekableIteratorTest: QuickSpec {
  override class func spec() {
    describe("PeekableIterator") {
      it("should act as a normal iterator") {
        var iterator = PeekableIterator([1, 2, 3].makeIterator())

        expect(iterator.next()).to(equal(1))
        expect(iterator.next()).to(equal(2))
        expect(iterator.next()).to(equal(3))
        expect(iterator.next()).to(beNil())
      }

      it("should allow peeking") {
        var iterator = PeekableIterator([1, 2, 3].makeIterator())

        // next call should retun the same value as current peek
        expect(iterator.peek()).to(equal(1))
        expect(iterator.peek()).to(equal(1))
        expect(iterator.next()).to(equal(1))
      }

      it("should allow peeking at the end") {
        var iterator = PeekableIterator([1, 2, 3].makeIterator())

        expect(iterator.next()).to(equal(1))
        expect(iterator.next()).to(equal(2))
        expect(iterator.next()).to(equal(3))

        expect(iterator.peek()).to(beNil())
        expect(iterator.next()).to(beNil())
      }

      it("should allow peeking at the end of an empty iterator") {
        var iterator = PeekableIterator([].makeIterator())

        expect(iterator.peek()).to(beNil())
        expect(iterator.peek()).to(beNil())

        expect(iterator.next()).to(beNil())
      }
    }
  }
}
