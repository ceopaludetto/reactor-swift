import ReactiveStreams

final class FluxIndexPublisher<T, R>: Publisher {
	typealias Item = R

	private let source: any Publisher<T>
	private let mapper: (UInt, T) throws -> R

	init(_ mapper: @escaping (UInt, T) throws -> R, _ publisher: some Publisher<T>) {
		self.mapper = mapper
		self.source = publisher
	}

	func subscribe(_ subscriber: some Subscriber<Item>) {
		self.source.subscribe(FluxIndexOperator(self.mapper, subscriber))
	}
}

final class FluxIndexOperator<T, R>: BaseOperator, Subscriber, Subscription {
	typealias Item = T

	private let actual: any Subscriber<R>

	private let mapper: (UInt, T) throws -> R
	private var index: UInt = 0

	init(_ mapper: @escaping (UInt, T) throws -> R, _ actual: any Subscriber<R>) {
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
			defer { self.index += 1 }
			runCatching(self.onError) {
				try self.actual.onNext(self.mapper(self.index, element))
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
	func index() -> Flux<(UInt, T)> {
		Flux<(UInt, T)>(publisher: FluxIndexPublisher({ ($0, $1) }, publisher))
	}

	func index<R>(_ mapper: @escaping (UInt, T) throws -> R) -> Flux<R> {
		Flux<R>(publisher: FluxIndexPublisher(mapper, publisher))
	}
}
