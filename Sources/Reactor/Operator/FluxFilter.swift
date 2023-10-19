import Foundation
import ReactiveStreams

class FluxFilterPublisher<T>: Publisher {
	typealias Item = T

	private let predicate: (T) throws -> Bool
	private let source: any Publisher<T>

	init(_ predicate: @escaping (T) throws -> Bool, _ publisher: some Publisher<T>) {
		self.predicate = predicate
		self.source = publisher
	}

	func subscribe(_ subscriber: some Subscriber<Item>) {
		self.source.subscribe(FluxFilterOperator(self.predicate, subscriber))
	}
}

class FluxFilterOperator<T>: Subscriber, Subscription {
	typealias Item = T

	private let predicate: (T) throws -> Bool

	private var actual: any Subscriber<T>
	private var subscription: (any Subscription)?

	private let lock: NSLock = .init()
	private var done: Bool = false

	init(_ predicate: @escaping (T) throws -> Bool, _ actual: any Subscriber<T>) {
		self.predicate = predicate
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

		do {
			if try self.predicate(element) {
				self.actual.onNext(element)
				return
			}

			self.subscription?.request(1)
		} catch {
			self.onError(error)
		}
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
		self.subscription?.request(demand)
	}

	func cancel() {
		self.subscription?.cancel()
	}
}

public extension Flux {
	func filter(_ predicate: @escaping (T) throws -> Bool) -> Flux<T> {
		Flux(publisher: FluxFilterPublisher(predicate, publisher))
	}
}
