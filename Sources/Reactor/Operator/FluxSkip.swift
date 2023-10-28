import ReactiveStreams

final class FluxSkipPublisher<T>: Publisher {
	typealias Item = T

	private let skip: UInt
	private let source: any Publisher<T>

	init(_ skip: UInt, _ publisher: some Publisher<T>) {
		self.skip = skip
		self.source = publisher
	}

	func subscribe(_ subscriber: some Subscriber<Item>) {
		self.source.subscribe(FluxSkipOperator(self.skip, subscriber))
	}
}

final class FluxSkipOperator<T>: BaseOperator, Subscriber, Subscription {
	typealias Item = T

	private var actual: any Subscriber<T>

	private let skip: UInt
	private var produced: UInt = 0

	init(_ skip: UInt, _ actual: any Subscriber<T>) {
		self.skip = skip
		self.actual = actual
	}

	func onSubscribe(_ subscription: some Subscription) {
		self.tryLock(.subscription(subscription)) {
			self.actual.onSubscribe(self)
		}
	}

	func onNext(_ element: T) {
		self.tryLock(.next) {
			if self.produced < self.skip {
				self.produced += 1
				return
			}

			self.actual.onNext(element)
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
	func skip(_ skip: UInt) -> Flux<T> {
		Flux<T>(publisher: FluxSkipPublisher(skip, publisher))
	}
}
