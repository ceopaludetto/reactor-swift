import ReactiveStreams

public protocol AsPublisher<Item> {
	associatedtype Item
	func asPublisher() -> any Publisher<Item>
}
