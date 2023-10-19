import Foundation
import ReactiveStreams

internal class FluxIndexPublisher<T, R>: Publisher {
  typealias Item = R

  private let source: any Publisher<T>
  private let mapper: (UInt, T) throws -> R

  init(_ mapper: @escaping (UInt, T) throws -> R, _ publisher: some Publisher<T>) {
    self.mapper = mapper
    self.source = publisher
  }

  func subscribe(_ subscriber: some Subscriber<Item>) {
    self.source.subscribe(FluxIndexOperator(mapper, subscriber))
  }
}

internal class FluxIndexOperator<T, R>: Subscriber, Subscription {
  typealias Item = T

  private let mapper: (UInt, T) throws -> R
  private let actual: any Subscriber<R>

  private var subscription: (any Subscription)?

  private let lock: NSLock = .init()
  private var done: Bool = false
  private var index: UInt = 0

  init(_ mapper: @escaping (UInt, T) throws -> R, _ actual: any Subscriber<R>) {
    self.mapper = mapper
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

    defer { index += 1 }
    do {
      actual.onNext(try mapper(index, element))
    } catch {
      onError(error)
    }
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
    subscription?.request(demand)
  }

  func cancel() {
    subscription?.cancel()
  }
}

extension Flux {
  public func index() -> Flux<(UInt, T)> {
    return Flux<(UInt, T)>(publisher: FluxIndexPublisher({ ($0, $1) }, publisher))
  }

  public func index<R>(_ mapper: @escaping (UInt, T) throws -> R) -> Flux<R> {
    return Flux<R>(publisher: FluxIndexPublisher(mapper, publisher))
  }
}
