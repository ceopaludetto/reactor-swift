import ReactiveStreams

internal class FluxTakeUntilPublisher<T>: Publisher {
  typealias Item = T

  private let predicate: (T) throws -> Bool
  private let source: any Publisher<T>

  init(_ predicate: @escaping (T) throws -> Bool, _ publisher: some Publisher<T>) {
    self.predicate = predicate
    self.source = publisher
  }

  func subscribe(_ subscriber: some Subscriber<Item>) {
    self.source.subscribe(FluxTakeUntilOperator(predicate, subscriber))
  }
}

internal class FluxTakeUntilOperator<T>: Subscriber, Subscription {
  typealias Item = T

  private let predicate: (T) throws -> Bool

  private var actual: any Subscriber<T>
  private var subscription: (any Subscription)?

  private var done: Bool = false

  init(_ predicate: @escaping (T) throws -> Bool, _ actual: any Subscriber<T>) {
    self.predicate = predicate
    self.actual = actual
  }

  func onSubscribe(_ subscription: some ReactiveStreams.Subscription) {
    self.subscription = subscription
    actual.onSubscribe(self)
  }

  func onNext(_ element: T) {
    if done {
      return
    }

    actual.onNext(element)

    do {
      if try predicate(element) {
        subscription?.cancel()
        onComplete()

        return
      }
    } catch {
      onError(error)
    }
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
    subscription?.request(demand)
  }

  func cancel() {
    subscription?.cancel()
  }
}

extension Flux {
  public func takeUntil(_ predicate: @escaping (T) throws -> Bool) -> Flux<T> {
    return Flux(publisher: FluxTakeUntilPublisher(predicate, publisher))
  }
}
