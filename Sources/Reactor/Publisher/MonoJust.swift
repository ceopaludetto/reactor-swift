import ReactiveStreams

class MonoJustPublisher<T>: Publisher {
	typealias Item = T

	private let item: T

	init(_ item: T) {
		self.item = item
	}

	func subscribe(_ subscriber: some Subscriber<Item>) {
		subscriber.onSubscribe(ScalarSubscription(subscriber: subscriber, item: self.item))
	}
}

public extension Mono {
	static func just(_ item: T) -> Mono<T> {
		Mono(publisher: MonoJustPublisher(item))
	}
}
