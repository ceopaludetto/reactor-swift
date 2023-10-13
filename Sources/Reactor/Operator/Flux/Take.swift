import Atomics
import ReactiveStreams

internal class TakePublisher<T>: Publisher {
  typealias Item = T

  private let take: UInt
  private let source: any Publisher<T>

  init(_ take: UInt, _ publisher: some Publisher<T>) {
    self.take = take
    self.source = publisher
  }

  func subscribe(_ subscriber: some Subscriber<Item>) {
    self.source.subscribe(TakeOperator(take, subscriber))
  }
}

internal class TakeOperator<T>: Subscriber, Subscription {
  typealias Item = T

  private let take: UInt

  private var actual: any Subscriber<T>
  private var subscription: (any Subscription)?

  private var produced: UInt = 0
  private var done: Bool = false

  init(_ take: UInt, _ actual: any Subscriber<T>) {
    self.take = take
    self.actual = actual
  }

  func onSubscribe(_ subscription: some Subscription) {
    self.subscription = subscription
    actual.onSubscribe(self)
  }

  func onNext(_ element: T) {
    if done {
      return
    }

    if produced == take {
      subscription?.cancel()
      onComplete()

      return
    }

    produced += 1
    actual.onNext(element)
  }

  func onError(_ error: Error) {
    if done {
      return
    }

    done = true
    actual.onError(error)
  }

  func onComplete() {
    if done {
      return
    }

    done = true
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
    return Flux(publisher: TakePublisher(take, self.publisher))
  }
}
