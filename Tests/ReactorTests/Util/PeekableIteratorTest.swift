import Testing

@testable import Reactor

struct PeekableIteratorTest {
	@Test
	func shouldActAsANormalIterator() {
		var iterator = PeekableIterator([1, 2, 3].makeIterator())

		#expect(iterator.next() == 1)
		#expect(iterator.next() == 2)
		#expect(iterator.next() == 3)
		#expect(iterator.next() == nil)
	}

	@Test
	func shouldAllowPeeking() {
		var iterator = PeekableIterator([1, 2, 3].makeIterator())

		// next call should retun the same value as current peek
		#expect(iterator.peek() == 1)
		#expect(iterator.peek() == 1)
		#expect(iterator.next() == 1)
	}

	@Test
	func shouldAllowPeekingAtTheEnd() {
		var iterator = PeekableIterator([1, 2, 3].makeIterator())

		#expect(iterator.next() == 1)
		#expect(iterator.next() == 2)
		#expect(iterator.next() == 3)

		#expect(iterator.peek() == nil)
		#expect(iterator.next() == nil)
	}

	@Test
	func shouldAllowPeekingAtTheEndOfAnEmptyIterator() {
		var iterator = PeekableIterator([].makeIterator())

		#expect(iterator.peek() == nil)
		#expect(iterator.next() == nil)

		#expect(iterator.next() == nil)
	}
}
