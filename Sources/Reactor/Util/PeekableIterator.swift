struct PeekableIterator<Iterator: IteratorProtocol>: IteratorProtocol {
	typealias Element = Iterator.Element

	private var iterator: Iterator
	private var nextElement: Element?

	init(_ iterator: Iterator) {
		self.iterator = iterator
	}

	mutating func peek() -> Element? {
		if self.nextElement == nil {
			self.nextElement = self.iterator.next()
		}

		return self.nextElement
	}

	mutating func next() -> Element? {
		if let result = nextElement {
			self.nextElement = nil
			return result
		}

		return self.iterator.next()
	}
}
