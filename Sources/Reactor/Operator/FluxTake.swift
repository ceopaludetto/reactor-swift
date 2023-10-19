import Foundation
import ReactiveStreams

internal class FluxTakePublisher<T>: Publisher {
  typealias Item = T

  private let take: UInt
  private let source: any Publisher<T>

  init(_ take: UInt, _ publisher: some Publisher<T>) {
    self.take = take
    self.source = publisher
  }

  func subscribe(_ subscriber: some Subscriber<Item>) {
    self.source.subscribe(FluxTakeOperator(take, subscriber))
  }
}

internal class FluxTakeOperator<T>: Subscriber, Subscription {
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
    lock.lock()

    guard self.subscription == nil, !done else {
      lock.unlock()
      self.subscription?.cancel()

      return
    }

    self.subscription = subscription
    lock.unlock()

    actual.onSubscribe(self)
  }

  func onNext(_ element: T) {
    #guardLock(self.lock, self.done, .next)

    if produced == take {
      subscription?.cancel()
      onComplete()

      return
    }

    produced += 1
    actual.onNext(element)
  }

  func onError(_ error: Error) {
    #guardLock(self.lock, self.done, .terminal)
    actual.onError(error)
  }

  func onComplete() {
    #guardLock(self.lock, self.done, .terminal)
    actual.onComplete()
  }

  func request(_ demand: UInt) {
    if demand > take {
      subscription?.request(.max)
      return
    }

    subscription?.request(demand)
  }

  func cancel() {
    subscription?.cancel()
  }
}

extension Flux {
  public func take(_ take: UInt) -> Flux<T> {
    return Flux(publisher: FluxTakePublisher(take, self.publisher))
  }
}
