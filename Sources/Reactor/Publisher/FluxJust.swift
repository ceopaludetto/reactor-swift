import ReactiveStreams

final class FluxJustPublisher<T, S: Sequence<T>>: Publisher {
	typealias Item = T

	private let items: S

	init(_ items: S) {
		self.items = items
	}

	func subscribe(_ subscriber: some Subscriber<Item>) {
		let subscription = FluxJustSubscription<T, S>(
			subscriber: subscriber,
			iterator: items.makeIterator()
		)

		if subscription.isExhausted {
			subscriber.onSubscribe(EmptySubscription())
			subscriber.onComplete()

			subscription.cancel()
			return
		}

		subscriber.onSubscribe(subscription)
	}
}

final class FluxJustSubscription<T, S: Sequence<T>>: Subscription {
	private var actual: any Subscriber<T>
	private var iterator: PeekableIterator<S.Iterator>

	private var lock: UnfairLock = .allocate()

	private var requested: UInt = 0
	private var recursion: Bool = false
	private var cancelled: Bool = false

	init(subscriber: any Subscriber<T>, iterator: S.Iterator) {
		self.actual = subscriber
		self.iterator = PeekableIterator(iterator)
	}

	deinit {
		self.lock.deallocate()
	}

	fileprivate var isExhausted: Bool {
		self.iterator.peek() == nil
	}

	func request(_ demand: UInt) {
		if case let .failure(error) = Validator.demand(demand) {
			self.cancel()
			self.actual.onError(error)

			return
		}

		self.lock.lock()
		self.requested ~+= demand

		if self.recursion {
			self.lock.unlock()
			return
		}

		while !self.cancelled, self.requested > 0 {
			if let next = iterator.next() {
				self.requested -= 1
				self.recursion = true
				self.lock.unlock()

				self.actual.onNext(next)
				self.lock.lock()

				self.recursion = false
			}

			if self.iterator.peek() == nil {
				self.cancelled = true

				self.lock.unlock()
				self.actual.onComplete()

				return
			}
		}

		self.lock.unlock()
	}

	func cancel() {
		self.lock.lock()
		defer { lock.unlock() }

		self.cancelled = true
	}
}

public extension Flux {
	static func just(_ items: some Sequence<T>) -> Flux<T> {
		Flux(publisher: FluxJustPublisher(items))
	}
}
