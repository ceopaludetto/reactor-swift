import ReactiveStreams

class ScalarSubscription<T>: Subscription {
	private var actual: any Subscriber<T>
	private let item: T

	private let lock: UnfairLock = .allocate()
	private var cancelled: Bool = false

	init(subscriber: any Subscriber<T>, item: T) {
		self.actual = subscriber
		self.item = item
	}

	deinit {
		self.lock.deallocate()
	}

	func request(_ demand: UInt) {
		if case let .failure(error) = Validator.demand(demand) {
			self.cancel()
			self.actual.onError(error)

			return
		}

		self.lock.lock()
		defer { lock.unlock() }

		self.actual.onNext(self.item)
		self.actual.onComplete()

		self.cancelled = true
	}

	func cancel() {
		self.lock.lock()
		defer { lock.unlock() }

		self.cancelled = true
	}
}
