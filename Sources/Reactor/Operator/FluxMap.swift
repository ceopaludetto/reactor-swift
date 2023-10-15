import ReactiveStreams

internal class FluxMapPublisher<T, R>: Publisher {
  typealias Item = R

  private let mapper: (T) throws -> R
  private let source: any Publisher<T>

  init(_ mapper: @escaping (T) throws -> R, _ publisher: some Publisher<T>) {
    self.mapper = mapper
    self.source = publisher
  }

  func subscribe(_ subscriber: some Subscriber<Item>) {
    self.source.subscribe(FluxMapOperator(mapper, subscriber))
  }
}

internal class FluxMapOperator<T, R>: Subscriber, Subscription {
  typealias Item = T

  private let mapper: (T) throws -> R

  private var actual: any Subscriber<R>
  private var subscription: (any Subscription)?

  private var done: Bool = false

  init(_ mapper: @escaping (T) throws -> R, _ actual: any Subscriber<R>) {
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

    do {
      actual.onNext(try mapper(element))
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
  public func map<R>(_ mapper: @escaping (T) throws -> R) -> Flux<R> {
    return Flux<R>(publisher: FluxMapPublisher(mapper, self.publisher))
  }
}
