struct PeekableIterator<Iterator: IteratorProtocol>: IteratorProtocol {
  typealias Element = Iterator.Element

  private var iterator: Iterator
  private var nextElement: Element?

  init(_ iterator: Iterator) {
    self.iterator = iterator
  }

  mutating func peek() -> Element? {
    if nextElement == nil {
      nextElement = iterator.next()
    }

    return nextElement
  }

  mutating func next() -> Element? {
    if let result = nextElement {
      nextElement = nil
      return result
    }

    return iterator.next()
  }
}
