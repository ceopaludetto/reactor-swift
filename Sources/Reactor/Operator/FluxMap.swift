import Foundation
import ReactiveStreams

class FluxMapPublisher<T, R>: Publisher {
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

class FluxMapOperator<T, R>: Subscriber, Subscription {
	typealias Item = T

	private let mapper: (T) throws -> R
	private let actual: any Subscriber<R>

	private var subscription: (any Subscription)?

	private var lock: NSLock = .init()
	private var done: Bool = false

	init(_ mapper: @escaping (T) throws -> R, _ actual: any Subscriber<R>) {
		self.mapper = mapper
		self.actual = actual
	}

	func onSubscribe(_ subscription: some Subscription) {
		// TODO: It's possible to write a macro who reassign the subscription?
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
			try self.actual.onNext(self.mapper(element))
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
	func map<R>(_ mapper: @escaping (T) throws -> R) -> Flux<R> {
		Flux<R>(publisher: FluxMapPublisher(mapper, publisher))
	}
}
