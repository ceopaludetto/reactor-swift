import Foundation
import ReactiveStreams

@ReactivePublisher
public struct Flux<T> {}

public extension Flux {
	func subscribe(_ subscriber: some Subscriber<T>) {
		publisher.subscribe(subscriber)
	}

	func subscribe(_ onNext: @escaping (T) -> Void) {
		let subscriber = CallbackSubscriber(onNext: onNext)
		self.subscribe(subscriber)
	}
}
