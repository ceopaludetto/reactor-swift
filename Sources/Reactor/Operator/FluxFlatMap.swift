import ReactiveStreams

final class FlatMapPublisher<T, R>: Publisher {
	typealias Item = R

	private let mapper: (T) throws -> any Publisher<R>
	private let source: any Publisher<T>
	private let maxConcurrency: UInt

	init(
		_ mapper: @escaping (T) throws -> any Publisher<R>,
		_ publisher: some Publisher<T>,
		_ maxConcurrency: UInt
	) {
		self.mapper = mapper
		self.source = publisher
		self.maxConcurrency = maxConcurrency
	}

	func subscribe(_ subscriber: some Subscriber<Item>) {
		self.source.subscribe(FluxFlatMapOperator(self.mapper, subscriber, self.maxConcurrency))
	}
}

/// This flatMap implementation is highly inspired by OpenCombine's implementation:
/// https://github.com/OpenCombine/OpenCombine/blob/master/Sources/OpenCombine/Publishers/Publishers.FlatMap.swift
///
/// Only small changes were made to make it work with ReactiveStreams.
final class FluxFlatMapOperator<T, R>: Subscriber, Subscription {
	typealias Item = T

	private let mapper: (T) throws -> any Publisher<R>
	private let actual: any Subscriber<R>

	private var subscription: (any Subscription)?
	private var subscriptions: [Int: any Subscription] = [:]

	private let maxConcurrency: UInt

	// locks
	private let lock: UnfairLock = .allocate()
	private let downstreamLock: UnfairRecursiveLock = .allocate()
	private let outerLock: UnfairRecursiveLock = .allocate()

	// states
	private var buffer: [(Int, R)] = []
	private var downstreamRecursive: Bool = false
	private var innerRecursive: Bool = false
	private var requested: UInt = 0
	private var nextInnerIndex: Int = 0
	private var pendingSubscriptions: Int = 0

	private var outerFinished: Bool = false
	private var done: Bool = false

	init(
		_ mapper: @escaping (T) throws -> any Publisher<R>,
		_ actual: any Subscriber<R>,
		_ maxConcurrency: UInt
	) {
		self.mapper = mapper
		self.actual = actual
		self.maxConcurrency = maxConcurrency
	}

	deinit {
		self.lock.deallocate()
		self.downstreamLock.deallocate()
		self.outerLock.deallocate()
	}

	func onSubscribe(_ subscription: some Subscription) {
		self.lock.lock()

		guard self.subscription == nil, !self.done else {
			self.lock.unlock()
			subscription.cancel()

			return
		}

		self.subscription = subscription
		self.lock.unlock()

		self.actual.onSubscribe(self)
		subscription.request(self.maxConcurrency)
	}

	func onNext(_ item: T) {
		self.lock.lock()
		let done = done
		self.lock.unlock()

		if done {
			return
		}

		var child: any Publisher<R>
		do {
			child = try self.mapper(item)

		} catch {
			self.onError(error)
			return
		}

		self.lock.lock()

		let innerIndex = self.nextInnerIndex
		self.nextInnerIndex += 1
		self.pendingSubscriptions += 1

		self.lock.unlock()
		child.subscribe(FluxFlatMapInnerOperator(self, innerIndex))
	}

	func onError(_ error: Error) {
		self.lock.lock()

		self.subscription = nil
		self.outerFinished = true

		let alredyDone = self.done
		self.done = true

		for (_, subscription) in self.subscriptions {
			subscription.cancel()
		}

		self.subscriptions = [:]
		self.lock.unlock()

		if alredyDone {
			return
		}

		self.downstreamLock.lock()
		self.actual.onError(error)
		self.downstreamLock.unlock()
	}

	func onComplete() {
		self.lock.lock()

		self.subscription = nil
		self.outerFinished = true

		self.releaseLockThenSendCompletionDownstreamIfNeeded(outerFinished: self.outerFinished)
	}

	func request(_ demand: UInt) {
		if case let .failure(error) = Validator.demand(demand) {
			self.cancel()
			self.actual.onError(error)

			return
		}

		if self.downstreamRecursive {
			self.requested ~+= demand
			return
		}

		self.lock.lock()
		if self.done {
			self.lock.unlock()
			return
		}

		defer { releaseLockThenSendCompletionDownstreamIfNeeded(outerFinished: outerFinished) }

		if demand == .max {
			self.requested = .max

			let buffer = buffer
			let subscriptions = subscriptions

			self.lock.unlock()

			self.downstreamLock.lock()
			self.downstreamRecursive = true

			for (_, item) in buffer {
				self.actual.onNext(item)
			}

			self.downstreamRecursive = false
			self.downstreamLock.unlock()

			for (_, subscription) in subscriptions {
				subscription.request(.max)
			}

			self.lock.lock()
			return
		}

		self.requested ~+= demand
		while !self.buffer.isEmpty, self.requested > 0 {
			let (index, value) = self.buffer.removeFirst()
			self.requested -= 1

			let subscription = self.subscriptions[index]
			self.lock.unlock()

			self.downstreamLock.lock()
			self.downstreamRecursive = true

			self.actual.onNext(value)

			self.downstreamRecursive = false
			self.downstreamLock.unlock()

			if let subscription {
				self.innerRecursive = true
				subscription.request(1)
				self.innerRecursive = false
			}

			self.lock.lock()
		}
	}

	func cancel() {
		self.lock.lock()

		if self.done {
			self.lock.unlock()
			return
		}

		self.done = true
		self.lock.unlock()

		// cancel every inner subscription
		for (_, subscription) in self.subscriptions {
			subscription.cancel()
		}

		// cancel outer subscription
		self.subscription?.cancel()
	}

	func innerSubscribe(_ subscription: some Subscription, _ index: Int) {
		self.lock.lock()

		self.pendingSubscriptions -= 1
		self.subscriptions[index] = subscription

		let demand: UInt = self.requested == .max ? .max : 1

		self.lock.unlock()
		subscription.request(demand)
	}

	func innerNext(_ item: R, _ index: Int) {
		self.lock.lock()

		if self.requested == .max {
			self.lock.unlock()

			self.downstreamLock.lock()
			self.downstreamRecursive = true

			self.actual.onNext(item)

			self.downstreamRecursive = false
			self.downstreamLock.unlock()

			return
		}

		if self.requested == 0 || self.innerRecursive {
			self.buffer.append((index, item))
			self.lock.unlock()
			return
		}

		self.requested -= 1
		self.lock.unlock()

		self.downstreamLock.lock()
		self.downstreamRecursive = true

		self.actual.onNext(item)

		self.downstreamRecursive = false
		self.downstreamLock.unlock()

		self.request(1)
	}

	func innerError(_ error: Error, _ index: Int) {
		self.lock.lock()

		if self.done {
			self.lock.unlock()
			return
		}

		self.done = true
		self.lock.unlock()

		for (i, subscription) in self.subscriptions where i != index {
			subscription.cancel()
		}

		self.downstreamLock.lock()
		self.actual.onError(error)
		self.downstreamLock.unlock()
	}

	func innerComplete(_ index: Int) {
		self.lock.lock()
		self.subscriptions.removeValue(forKey: index)

		let downstreamCompleted =
			self.releaseLockThenSendCompletionDownstreamIfNeeded(outerFinished: self.outerFinished)

		if !downstreamCompleted {
			self.requestOneMorePublisher()
		}
	}

	private func requestOneMorePublisher() {
		if self.maxConcurrency != .max {
			self.outerLock.lock()
			self.subscription?.request(1)
			self.outerLock.unlock()
		}
	}

	@discardableResult
	private func releaseLockThenSendCompletionDownstreamIfNeeded(outerFinished: Bool) -> Bool {
		if !self.done, outerFinished, self.buffer.isEmpty, self.subscriptions.count + self.pendingSubscriptions == 0 {
			self.done = true
			self.lock.unlock()
			self.downstreamLock.lock()
			self.actual.onComplete()
			self.downstreamLock.unlock()
			return true
		}

		self.lock.unlock()
		return false
	}
}

private class FluxFlatMapInnerOperator<T, R>: Subscriber {
	typealias Item = R

	private let parent: FluxFlatMapOperator<T, R>
	private let index: Int

	init(_ parent: FluxFlatMapOperator<T, R>, _ index: Int) {
		self.parent = parent
		self.index = index
	}

	func onSubscribe(_ subscription: some Subscription) {
		self.parent.innerSubscribe(subscription, self.index)
	}

	func onNext(_ item: R) {
		self.parent.innerNext(item, self.index)
	}

	func onError(_ error: Error) {
		self.parent.innerError(error, self.index)
	}

	func onComplete() {
		self.parent.innerComplete(self.index)
	}
}

public extension Flux {
	func flatMap<R>(
		maxConcurrency: UInt = .max,
		_ mapper: @escaping (T) throws -> any Publisher<R>
	) -> Flux<R> {
		Flux<R>(publisher: FlatMapPublisher(mapper, publisher, maxConcurrency))
	}

	func flatMap<R>(
		maxConcurrency: UInt = .max,
		_ mapper: @escaping (T) throws -> some PublisherConvertible<R>
	) -> Flux<R> {
		self.flatMap(maxConcurrency: maxConcurrency) { try mapper($0).toPublisher() }
	}
}
