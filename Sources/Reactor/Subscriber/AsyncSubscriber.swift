import Foundation
import ReactiveStreams

internal class AsyncSubscriber<T>: Subscriber {
  typealias Item = T

  private var task: Task<[T], Error>?
  private var produced: [T] = []
  private var continuation: CheckedContinuation<[T], Error>?

  func onSubscribe(_ subscription: some Subscription) {
    task = Task {
      try await withCheckedThrowingContinuation { self.continuation = $0 }
    }

    subscription.request(.max)
  }

  func onNext(_ element: T) {
    produced.append(element)
  }

  func onError(_ error: Error) {
    self.continuation?.resume(throwing: error)
  }

  func onComplete() {
    self.continuation?.resume(returning: produced)
  }

  func awaitList() async throws -> [T] {
    return try await task!.value
  }
}

extension Flux {
  public func awaitList() async throws -> [T] {
    let subscriber = AsyncSubscriber<T>()
    subscribe(subscriber)

    return try await subscriber.awaitList()
  }
}

extension Mono {
  public func awaitSingle() async throws -> T {
    let subscriber = AsyncSubscriber<T>()
    subscribe(subscriber)

    return try await subscriber.awaitList().first!
  }
}
