import ReactiveStreams

final class FluxSkipUntilPublisher<T>: Publisher {
	typealias Item = T

	private let predicate: (T) throws -> Bool
	private let source: any Publisher<T>

	init(_ predicate: @escaping (T) throws -> Bool, _ publisher: some Publisher<T>) {
		self.predicate = predicate
		self.source = publisher
	}

	func subscribe(_ subscriber: some Subscriber<Item>) {
		self.source.subscribe(FluxTakeUntilOperator(self.predicate, subscriber))
	}
}

final class FluxSkipUntilOperator<T>: BaseOperator, Subscriber, Subscription {
	typealias Item = T

	private let actual: any Subscriber<T>

	private let predicate: (T) throws -> Bool

	init(_ predicate: @escaping (T) throws -> Bool, _ actual: any Subscriber<T>) {
		self.predicate = predicate
		self.actual = actual
	}

	func onSubscribe(_ subscription: some Subscription) {
		self.tryLock(.subscription(subscription)) {
			self.actual.onSubscribe(self)
		}
	}

	func onNext(_ element: T) {
		self.tryLock(.next) {
			self.actual.onNext(element)

			runCatching(self.onError) {
				if try self.predicate(element) {
					self.subscription?.cancel()
					self.onComplete()

					return
				}
			}
		}
	}

	func onError(_ error: Error) {
		self.tryLock(.terminal) {
			self.actual.onError(error)
		}
	}

	func onComplete() {
		self.tryLock(.terminal) {
			self.actual.onComplete()
		}
	}

	func request(_ demand: UInt) {
		self.subscription?.request(demand)
	}

	func cancel() {
		self.subscription?.cancel()
	}
}

public extension Flux {
	func skipUntil(_ predicate: @escaping (T) throws -> Bool) -> Flux<T> {
		Flux(publisher: FluxSkipUntilPublisher(predicate, publisher))
	}
}
