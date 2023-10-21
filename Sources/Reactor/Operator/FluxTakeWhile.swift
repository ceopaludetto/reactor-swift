import ReactiveStreams

final class FluxTakeWhilePublisher<T>: Publisher {
	typealias Item = T

	private let predicate: (T) throws -> Bool
	private let source: any Publisher<T>

	init(_ predicate: @escaping (T) throws -> Bool, _ publisher: some Publisher<T>) {
		self.predicate = predicate
		self.source = publisher
	}

	func subscribe(_ subscriber: some Subscriber<Item>) {
		self.source.subscribe(FluxTakeWhileOperator(self.predicate, subscriber))
	}
}

final class FluxTakeWhileOperator<T>: BaseOperator, Subscriber, Subscription {
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
			runCatching(self.onError) {
				if try !self.predicate(element) {
					self.subscription?.cancel()
					self.onComplete()

					return
				}

				self.actual.onNext(element)
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
	func takeWhile(_ predicate: @escaping (T) throws -> Bool) -> Flux<T> {
		Flux(publisher: FluxTakeWhilePublisher(predicate, publisher))
	}
}
