public protocol Subscriber<Item>: AnyObject {
  associatedtype Item

  func onSubscribe(_ subscription: some Subscription)
  func onNext(_ element: Item)
  func onError(_ error: Error)
  func onComplete()
}
