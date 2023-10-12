import ReactiveStreams

internal struct FlatMapOptions {
  let maxConcurrency: UInt = .max
  let prefetch: UInt = 128
  let delayError: Bool = false
}

internal class FlatMapPublisher<T, R>: Publisher {
  typealias Item = R

  private let mapper: (T) throws -> any Publisher<R>
  private let source: any Publisher<T>
  private let options: FlatMapOptions

  init(
    _ mapper: @escaping (T) throws -> any Publisher<R>,
    _ publisher: some Publisher<T>,
    options: FlatMapOptions = FlatMapOptions()
  ) {
    self.mapper = mapper
    self.source = publisher
    self.options = options
  }

  func subscribe(_ subscriber: some Subscriber<Item>) {
    self.source.subscribe(FlatMapOperator(mapper, subscriber))
  }
}

internal class FlatMapOperator<T, R>: Subscriber, Subscription {
  typealias Item = T

  private let mapper: (T) throws -> any Publisher<R>

  private var actual: any Subscriber<R>
  private var subscription: (any Subscription)?

  private var done: Bool = false

  init(_ mapper: @escaping (T) throws -> any Publisher<R>, _ actual: any Subscriber<R>) {
    self.mapper = mapper
    self.actual = actual
  }

  func onSubscribe(_ subscription: some Subscription) {
    self.subscription = subscription
    actual.onSubscribe(self)
  }

  func onNext(_ element: T) {

  }

  func onError(_ error: Error) {

  }

  func onComplete() {

  }

  func request(_ demand: UInt) {

  }

  func cancel() {

  }
}

extension Flux {
  public func flatMap<R>(_ mapper: @escaping (T) throws -> any Publisher<R>) -> Flux<R> {
    return Flux<R>(publisher: FlatMapPublisher(mapper, publisher))
  }

  public func flatMap<R, C: AsPublisher<R>>(_ mapper: @escaping (T) throws -> C) -> Flux<R> {
    return flatMap { try mapper($0).asPublisher() }
  }
}
