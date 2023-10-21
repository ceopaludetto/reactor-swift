import ReactiveStreams

public protocol PublisherConvertible<Item> {
	associatedtype Item
	func toPublisher() -> any Publisher<Item>
}
