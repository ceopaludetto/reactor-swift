import Foundation
import ReactiveStreams

class FluxTakePublisher<T>: Publisher {
	typealias Item = T

	private let take: UInt
	private let source: any Publisher<T>

	init(_ take: UInt, _ publisher: some Publisher<T>) {
		self.take = take
		self.source = publisher
	}

	func subscribe(_ subscriber: some Subscriber<Item>) {
		self.source.subscribe(FluxTakeOperator(self.take, subscriber))
	}
}

class FluxTakeOperator<T>: Subscriber, Subscription {
	typealias Item = T

	private let take: UInt
	private let actual: any Subscriber<T>

	private var subscription: (any Subscription)?

	private var lock: NSLock = .init()
	private var produced: UInt = 0
	private var done: Bool = false

	init(_ take: UInt, _ actual: any Subscriber<T>) {
		self.take = take
		self.actual = actual
	}

	func onSubscribe(_ subscription: some Subscription) {
		self.lock.lock()

		guard self.subscription == nil, !self.done else {
			self.lock.unlock()
			self.subscription?.cancel()

			return
		}

		self.subscription = subscription
		self.lock.unlock()

		self.actual.onSubscribe(self)
	}

	func onNext(_ element: T) {
		#guardLock(self.lock, self.done, .next)

		if self.produced == self.take {
			self.subscription?.cancel()
			self.onComplete()

			return
		}

		self.produced += 1
		self.actual.onNext(element)
	}

	func onError(_ error: Error) {
		#guardLock(self.lock, self.done, .terminal)
		self.actual.onError(error)
	}

	func onComplete() {
		#guardLock(self.lock, self.done, .terminal)
		self.actual.onComplete()
	}

	func request(_ demand: UInt) {
		if demand > self.take {
			self.subscription?.request(.max)
			return
		}

		self.subscription?.request(demand)
	}

	func cancel() {
		self.subscription?.cancel()
	}
}

public extension Flux {
	func take(_ take: UInt) -> Flux<T> {
		Flux(publisher: FluxTakePublisher(take, publisher))
	}
}
