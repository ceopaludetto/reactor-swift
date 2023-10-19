import Foundation
import Nimble
import ReactiveStreams

enum CallType: Equatable {
	case onSubscribe, onNext, onError, onComplete
}

class AssertSubscriber<T>: Subscriber {
	typealias Item = T

	let timeout: TimeInterval

	var registeredCalls: [CallType] = []

	let produced: BlockingQueue<T> = .init()
	let errors: BlockingQueue<Error> = .init()

	let subscription: ConditionalVariable<Subscription> = .init()
	let completion: ConditionalVariable<Bool> = .init()

	var customOnNextCallbacks: [(T) -> Void] = []

	required init(timeout: TimeInterval = 10) {
		self.timeout = timeout
	}

	func onSubscribe(_ subscription: some Subscription) {
		logger.debug("onSubscribe()")

		self.subscription.dispatch(subscription)
		self.registeredCalls.append(.onSubscribe)
	}

	func onNext(_ element: T) {
		logger.debug("onNext(\(element))")
		self.produced.add(element)

		for callback in self.customOnNextCallbacks {
			callback(element)
		}

		self.registeredCalls.append(.onNext)
	}

	func onError(_ error: Error) {
		logger.debug("onError(\(error))")
		self.errors.add(error)

		self.registeredCalls.append(.onError)
	}

	func onComplete() {
		logger.debug("onComplete()")

		self.completion.dispatch(true)
		self.registeredCalls.append(.onComplete)
	}

	func requestNext(_ demand: UInt = 1) {
		guard let subscription = subscription.waitForValue() else {
			fatalError("Subscription not set")
		}

		subscription.request(demand)
	}

	func cancel() {
		guard let subscription = subscription.waitForValue() else {
			fatalError("Subscription not set")
		}

		subscription.cancel()
	}

	@discardableResult
	func expectSubscription() -> Subscription {
		let subscription = subscription.waitForValue(self.timeout)
		expect(self.subscription).notTo(beNil())

		return subscription!
	}

	@discardableResult
	func expectNext(_ elements: Int) -> [T] {
		let produced = produced.takeAll(self.timeout)

		expect(produced)
			.to(haveCount(elements), description: "expectNext called but no elements produced")

		return produced
	}

	@discardableResult
	func expectNextOrNone(_ elements: Int) -> [T] {
		let produced = produced.takeAll(self.timeout)

		if !produced.isEmpty {
			expect(produced)
				.to(haveCount(elements), description: "expectNext called but no elements produced")

			return produced
		}

		return []
	}

	@discardableResult
	func expectNext() -> T {
		let item = self.expectNext(1).first
		expect(item).notTo(beNil())

		return item!
	}

	@discardableResult
	func expectAnyError() -> Error? {
		let captured = self.errors.take(self.timeout)
		expect(captured).notTo(beNil())

		return captured
	}

	@discardableResult
	func expectError<E: Error>(_: E) -> Error? {
		let captured = self.errors.take(self.timeout)
		expect(captured).to(beAKindOf(E.self))

		return captured
	}

	func expectNoErrors() {
		expect(self.errors.takeAll(self.timeout)).to(beEmpty())
	}

	func expectNone() {
		expect(self.produced.takeAll(self.timeout)).to(beEmpty())
	}

	func expectCompletion() {
		let completed = self.completion.waitForValue(self.timeout)
		expect(completed).to(beTrue())
	}

	func registerCustomOnNextCallback(_ callback: @escaping (T) -> Void) {
		self.customOnNextCallbacks.append(callback)
	}
}
