import Foundation
import ReactiveStreams

class AsyncSubscriber<T>: Subscriber {
	typealias Item = T

	private var task: Task<[T], Error>?
	private var produced: [T] = []
	private var continuation: CheckedContinuation<[T], Error>?

	func onSubscribe(_ subscription: some Subscription) {
		self.task = Task { try await withCheckedThrowingContinuation { self.continuation = $0 } }
		subscription.request(.max)
	}

	func onNext(_ element: T) {
		self.produced.append(element)
	}

	func onError(_ error: Error) {
		self.continuation?.resume(throwing: error)
	}

	func onComplete() {
		self.continuation?.resume(returning: self.produced)
	}

	func awaitList() async throws -> [T] {
		try await self.task!.value
	}
}

public extension Flux {
	func awaitList() async throws -> [T] {
		let subscriber = AsyncSubscriber<T>()
		subscribe(subscriber)

		return try await subscriber.awaitList()
	}
}

public extension Mono {
	func awaitSingle() async throws {
		let subscriber = AsyncSubscriber<T>()
		subscribe(subscriber)

		// return try await subscriber.awaitList().first!
	}
}
