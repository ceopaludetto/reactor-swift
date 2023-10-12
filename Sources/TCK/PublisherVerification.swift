import ReactiveStreams

public protocol PublisherVerification {
  associatedtype Item

  func createPublisher(_ elements: UInt) -> any Publisher<Item>

  func createFailedPublisher() -> (any Publisher<Item>)?

  func maxElementsFromPublisher() -> UInt
}
