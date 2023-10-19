import ReactiveStreams

class FluxEmptyPublisher<T>: Publisher {
	typealias Item = T

	func subscribe(_ subscriber: some Subscriber<Item>) {
		subscriber.onSubscribe(EmptySubscription())
		subscriber.onComplete()
	}
}

public extension Flux {
	static func empty() -> Flux<T> {
		Flux(publisher: FluxEmptyPublisher())
	}
}
