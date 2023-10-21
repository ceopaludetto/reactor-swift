import ReactiveStreams

final class FluxMapPublisher<T, R>: Publisher {
	typealias Item = R

	private let mapper: (T) throws -> R
	private let source: any Publisher<T>

	init(_ mapper: @escaping (T) throws -> R, _ publisher: some Publisher<T>) {
		self.mapper = mapper
		self.source = publisher
	}

	func subscribe(_ subscriber: some Subscriber<Item>) {
		self.source.subscribe(FluxMapOperator(self.mapper, subscriber))
	}
}

final class FluxMapOperator<T, R>: BaseOperator, Subscriber, Subscription {
	typealias Item = T

	private let actual: any Subscriber<R>

	private let mapper: (T) throws -> R

	init(_ mapper: @escaping (T) throws -> R, _ actual: some Subscriber<R>) {
		self.mapper = mapper
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
				try self.actual.onNext(self.mapper(element))
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
	func map<R>(_ mapper: @escaping (T) throws -> R) -> Flux<R> {
		Flux<R>(publisher: FluxMapPublisher(mapper, publisher))
	}
}
