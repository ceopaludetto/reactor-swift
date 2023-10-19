import Foundation
import ReactiveStreams

class FluxIndexPublisher<T, R>: Publisher {
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

class FluxIndexOperator<T, R>: Subscriber, Subscription {
	typealias Item = T

	private let mapper: (UInt, T) throws -> R
	private let actual: any Subscriber<R>

	private var subscription: (any Subscription)?

	private let lock: NSLock = .init()
	private var done: Bool = false
	private var index: UInt = 0

	init(_ mapper: @escaping (UInt, T) throws -> R, _ actual: any Subscriber<R>) {
		self.mapper = mapper
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

		defer { index += 1 }
		do {
			try self.actual.onNext(self.mapper(self.index, element))
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
	func index() -> Flux<(UInt, T)> {
		Flux<(UInt, T)>(publisher: FluxIndexPublisher({ ($0, $1) }, publisher))
	}

	func index<R>(_ mapper: @escaping (UInt, T) throws -> R) -> Flux<R> {
		Flux<R>(publisher: FluxIndexPublisher(mapper, publisher))
	}
}
