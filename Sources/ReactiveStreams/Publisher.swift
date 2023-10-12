public protocol Publisher<Item>: AnyObject {
  associatedtype Item

  func subscribe(_ subscriber: some Subscriber<Item>)
}
