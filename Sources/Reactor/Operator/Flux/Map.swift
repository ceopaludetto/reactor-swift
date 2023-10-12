import ReactiveStreams

internal class MapPublisher<T, R>: Publisher {
  typealias Item = R

  private let transform: (T) throws -> R
  private let source: any Publisher<T>

  init(_ transform: @escaping (T) -> R, _ publisher: some Publisher<T>) {
    self.transform = transform
    self.source = publisher
  }

  func subscribe(_ subscriber: some Subscriber<Item>) {
    self.source.subscribe(MapOperator(transform, subscriber))
  }
}

internal class MapOperator<T, R>: Subscriber, Subscription {
  typealias Item = T

  private let transform: (T) throws -> R

  private var actual: any Subscriber<R>
  private var subscription: (any Subscription)?

  private var done: Bool = false

  init(_ transform: @escaping (T) throws -> R, _ actual: any Subscriber<R>) {
    self.transform = transform
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
      actual.onNext(try transform(element))
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
  public func map<R>(_ transform: @escaping (T) -> R) -> Flux<R> {
    return Flux<R>(publisher: MapPublisher(transform, self.publisher))
  }
}
