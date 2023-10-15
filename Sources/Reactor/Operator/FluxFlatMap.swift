import Atomics
import ReactiveStreams

private enum FluxFlatMapSourceMode {
  case normal, sync, async
}

public struct FluxFlatMapOptions {
  var maxConcurrency: UInt = .max
  var prefetch: UInt = 128
  var delayError: Bool = false

  public init(maxConcurrency: UInt = .max, prefetch: UInt = 128, delayError: Bool = false) {
    self.maxConcurrency = maxConcurrency
    self.prefetch = prefetch
    self.delayError = delayError
  }
}

internal class FlatMapPublisher<T, R>: Publisher {
  typealias Item = R

  private let mapper: (T) throws -> any Publisher<R>
  private let source: any Publisher<T>
  private let options: FluxFlatMapOptions

  init(
    _ mapper: @escaping (T) throws -> any Publisher<R>,
    _ publisher: some Publisher<T>,
    _ options: FluxFlatMapOptions
  ) {
    self.mapper = mapper
    self.source = publisher
    self.options = options
  }

  func subscribe(_ subscriber: some Subscriber<Item>) {
    self.source.subscribe(FluxFlatMapMainOperator(mapper, subscriber, options))
  }
}

internal class FluxFlatMapMainOperator<T, R>: Subscriber, Subscription {
  typealias Item = T

  private let mapper: (T) throws -> any Publisher<R>

  private var actual: any Subscriber<R>
  private var subscription: (any Subscription)?
  private let options: FluxFlatMapOptions

  private var done: Bool = false

  private let wip: ManagedAtomic<UInt> = .init(0)
  private let requested: ManagedAtomic<UInt> = .init(0)
  private let cancelled: ManagedAtomic<Bool> = .init(false)

  init(
    _ mapper: @escaping (T) throws -> any Publisher<R>,
    _ actual: any Subscriber<R>,
    _ options: FluxFlatMapOptions
  ) {
    self.mapper = mapper
    self.actual = actual
    self.options = options
  }

  func onSubscribe(_ subscription: some Subscription) {
    self.subscription = subscription
    actual.onSubscribe(self)

    subscription.request(options.maxConcurrency)
  }

  func onNext(_ element: T) {
    if done {
      return
    }

    do {
      let publisher = try mapper(element)
      publisher.subscribe(FluxFlatMapInnerOperator(self, options.prefetch))
    } catch {
      subscription?.cancel()
      onError(error)
    }
  }

  func onError(_ error: Error) {

  }

  func onComplete() {
    if done {
      return
    }

    done = true
    drain()
  }

  func request(_ demand: UInt) {
    #validateDemand(demand, cancel, actual.onError)

    if let new = Validator.addCap(demand, requested) {

    }
  }

  func cancel() {
    if !cancelled.load(ordering: .relaxed) {
      cancelled.store(true, ordering: .relaxed)

      if wip.loadThenWrappingIncrement(by: 1, ordering: .relaxed) == 0 {
        subscription?.cancel()
      }
    }
  }

  func drain() {
    if wip.loadThenWrappingIncrement(by: 1, ordering: .relaxed) != 0 {
      return
    }

    drainLoop()
  }

  private func drainLoop() {
    var missed: UInt = 1

    while true {

    }
  }

  func innerNext() {}

  func innerError() {}

  func innerComplete() {}
}

internal class FluxFlatMapInnerOperator<T, R>: Subscriber, Subscription {
  typealias Item = R

  private var subscription: (any Subscription)?
  private var parent: FluxFlatMapMainOperator<T, R>

  private var produced: UInt = 0
  private var prefetch: UInt
  private var limit: UInt

  private var sourceMode: FluxFlatMapSourceMode = .normal

  private let done: ManagedAtomic<Bool> = .init(false)

  init(_ parent: FluxFlatMapMainOperator<T, R>, _ prefetch: UInt) {
    self.parent = parent
    self.prefetch = prefetch
    self.limit = prefetch - (prefetch >> 2)
  }

  func onSubscribe(_ subscription: some Subscription) {
    self.subscription = subscription
    subscription.request(prefetch)
  }

  func onNext(_ element: R) {
    if sourceMode == .async {
      parent.drain()
      return
    }

    parent.innerNext()
  }

  func onError(_ error: Error) {

  }

  func onComplete() {

  }

  func request(_ demand: UInt) {
    if sourceMode != .sync {
      let p: UInt = produced + demand
      if p >= limit {
        produced = 0
        subscription?.request(p)

        return
      }

      produced = p
    }
  }

  func cancel() {
    // TODO: cancel
  }
}

extension Flux {
  public func flatMap<R>(
    _ mapper: @escaping (T) throws -> any Publisher<R>,
    options: FluxFlatMapOptions = .init()
  ) -> Flux<R> {
    return Flux<R>(publisher: FlatMapPublisher(mapper, publisher, options))
  }

  public func flatMap<R, C: AsPublisher<R>>(
    _ mapper: @escaping (T) throws -> C,
    options: FluxFlatMapOptions = .init()
  ) -> Flux<R> {
    return flatMap({ try mapper($0).asPublisher() }, options: options)
  }
}
