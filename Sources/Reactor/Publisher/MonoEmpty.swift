import ReactiveStreams

final class MonoEmptyPublisher<T>: Publisher {
	typealias Item = T

	func subscribe(_ subscriber: some Subscriber<Item>) {
		subscriber.onSubscribe(EmptySubscription())
		subscriber.onComplete()
	}
}

public extension Mono {
	static func empty() -> Mono<T> {
		Mono(publisher: MonoEmptyPublisher())
	}
}
