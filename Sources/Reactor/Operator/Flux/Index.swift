import ReactiveStreams

internal class IndexPublisher<T, R>: Publisher {
  typealias Item = R

  private let source: any Publisher<T>
  private let mapper: (UInt, T) throws -> R

  init(_ mapper: @escaping (UInt, T) throws -> R, _ publisher: some Publisher<T>) {
    self.mapper = mapper
    self.source = publisher
  }

  func subscribe(_ subscriber: some Subscriber<Item>) {
    self.source.subscribe(IndexOperator(mapper, subscriber))
  }
}

internal class IndexOperator<T, R>: Subscriber, Subscription {
  typealias Item = T

  private let mapper: (UInt, T) throws -> R

  private var actual: any Subscriber<R>
  private var subscription: (any Subscription)?

  private var done: Bool = false
  private var index: UInt = 0

  init(_ mapper: @escaping (UInt, T) throws -> R, _ actual: any Subscriber<R>) {
    self.mapper = mapper
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

    defer { index += 1 }
    do {
      actual.onNext(try mapper(index, element))
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
  public func index() -> Flux<(UInt, T)> {
    return Flux<(UInt, T)>(publisher: IndexPublisher({ ($0, $1) }, publisher))
  }

  public func index<R>(_ mapper: @escaping (UInt, T) throws -> R) -> Flux<R> {
    return Flux<R>(publisher: IndexPublisher(mapper, publisher))
  }
}
