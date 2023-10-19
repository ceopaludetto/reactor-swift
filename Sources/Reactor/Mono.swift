import ReactiveStreams

@ReactivePublisher
public struct Mono<T> {}

public extension Mono {
	func subscribe(_ subscriber: some Subscriber<T>) {
		publisher.subscribe(subscriber)
	}

	func subscribe(_ onNext: @escaping (T) -> Void) {
		let subscriber = CallbackSubscriber(onNext: onNext)
		self.subscribe(subscriber)
	}
}
