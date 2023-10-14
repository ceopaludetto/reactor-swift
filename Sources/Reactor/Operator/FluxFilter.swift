import ReactiveStreams

internal class FluxFilterPublisher<T>: Publisher {
  typealias Item = T

  private let predicate: (T) throws -> Bool
  private let source: any Publisher<T>

  init(_ predicate: @escaping (T) -> Bool, _ publisher: some Publisher<T>) {
    self.predicate = predicate
    self.source = publisher
  }

  func subscribe(_ subscriber: some Subscriber<Item>) {
    self.source.subscribe(FluxFilterOperator(predicate, subscriber))
  }
}

internal class FluxFilterOperator<T>: Subscriber, Subscription {
  typealias Item = T

  private let predicate: (T) throws -> Bool

  private var actual: any Subscriber<T>
  private var subscription: (any Subscription)?

  private var done: Bool = false

  init(_ predicate: @escaping (T) throws -> Bool, _ actual: any Subscriber<T>) {
    self.predicate = predicate
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

    do {
      if try predicate(element) {
        actual.onNext(element)
        return
      }

      subscription?.request(1)
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
  public func filter(_ predicate: @escaping (T) -> Bool) -> Flux<T> {
    return Flux(publisher: FluxFilterPublisher(predicate, self.publisher))
  }
}
