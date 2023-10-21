import ReactiveStreams

final class MonoErrorPublisher<T>: Publisher {
	typealias Item = T

	private let error: Error

	init(_ error: Error) {
		self.error = error
	}

	func subscribe(_ subscriber: some Subscriber<Item>) {
		subscriber.onSubscribe(EmptySubscription())
		subscriber.onError(self.error)
	}
}

public extension Mono {
	static func error(_ error: some Error) -> Mono<T> {
		Mono(publisher: MonoErrorPublisher(error))
	}
}
