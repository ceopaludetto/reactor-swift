import Foundation
import ReactiveStreams

internal class FlatMapPublisher<T, R>: Publisher {
  typealias Item = R

  private let mapper: (T) throws -> any Publisher<R>
  private let source: any Publisher<T>
  private let maxConcurrency: UInt

  init(
    _ mapper: @escaping (T) throws -> any Publisher<R>,
    _ publisher: some Publisher<T>,
    _ maxConcurrency: UInt
  ) {
    self.mapper = mapper
    self.source = publisher
    self.maxConcurrency = maxConcurrency
  }

  func subscribe(_ subscriber: some Subscriber<Item>) {
    self.source.subscribe(FluxFlatMapOperator(mapper, subscriber, maxConcurrency))
  }
}

/// This flatMap implementation is highly inspired by OpenCombine's implementation:
/// https://github.com/OpenCombine/OpenCombine/blob/master/Sources/OpenCombine/Publishers/Publishers.FlatMap.swift
///
/// Only small changes were made to make it work with ReactiveStreams.
internal class FluxFlatMapOperator<T, R>: Subscriber, Subscription {
  typealias Item = T

  private let mapper: (T) throws -> any Publisher<R>
  private let actual: any Subscriber<R>

  private var subscription: (any Subscription)?
  private var subscriptions: [Int: any Subscription] = [:]

  private let maxConcurrency: UInt

  // locks
  private let lock: NSLock = .init()
  private let downstreamLock: NSRecursiveLock = .init()
  private let outerLock: NSRecursiveLock = .init()

  // states
  private var buffer: [(Int, R)] = []
  private var downstreamRecursive: Bool = false
  private var innerRecursive: Bool = false
  private var requested: UInt = 0
  private var nextInnerIndex: Int = 0
  private var pendingSubscriptions: Int = 0

  private var outerFinished: Bool = false
  private var done: Bool = false

  init(
    _ mapper: @escaping (T) throws -> any Publisher<R>,
    _ actual: any Subscriber<R>,
    _ maxConcurrency: UInt
  ) {
    self.mapper = mapper
    self.actual = actual
    self.maxConcurrency = maxConcurrency
  }

  func onSubscribe(_ subscription: some Subscription) {
    lock.lock()

    guard self.subscription == nil, !done else {
      lock.unlock()
      subscription.cancel()

      return
    }

    self.subscription = subscription
    lock.unlock()

    actual.onSubscribe(self)
    subscription.request(maxConcurrency)
  }

  func onNext(_ item: T) {
    lock.lock()
    let done = self.done
    lock.unlock()

    if done {
      return
    }

    var child: any Publisher<R>
    do {
      child = try self.mapper(item)

    } catch {
      onError(error)
      return
    }

    lock.lock()

    let innerIndex = nextInnerIndex
    nextInnerIndex += 1
    pendingSubscriptions += 1

    lock.unlock()
    child.subscribe(FluxFlatMapInnerOperator(self, innerIndex))
  }

  func onError(_ error: Error) {
    lock.lock()

    self.subscription = nil
    self.outerFinished = true

    let alredyDone = done
    done = true

    for (_, subscription) in self.subscriptions {
      subscription.cancel()
    }

    subscriptions = [:]
    lock.unlock()

    if alredyDone {
      return
    }

    downstreamLock.lock()
    self.actual.onError(error)
    downstreamLock.unlock()
  }

  func onComplete() {
    lock.lock()

    self.subscription = nil
    self.outerFinished = true

    releaseLockThenSendCompletionDownstreamIfNeeded(outerFinished: outerFinished)
  }

  func request(_ demand: UInt) {
    #validateDemand(demand, cancel, actual.onError)

    if downstreamRecursive {
      self.requested ~+= demand
      return
    }

    lock.lock()
    if done {
      lock.unlock()
      return
    }

    defer { releaseLockThenSendCompletionDownstreamIfNeeded(outerFinished: outerFinished) }

    if demand == .max {
      self.requested = .max

      let buffer = self.buffer
      let subscriptions = self.subscriptions

      lock.unlock()

      downstreamLock.lock()
      downstreamRecursive = true

      for (_, item) in buffer {
        self.actual.onNext(item)
      }

      downstreamRecursive = false
      downstreamLock.unlock()

      for (_, subscription) in subscriptions {
        subscription.request(.max)
      }

      lock.lock()
      return
    }

    self.requested ~+= demand
    while !buffer.isEmpty && self.requested > 0 {
      let (index, value) = buffer.removeFirst()
      self.requested -= 1

      let subscription = self.subscriptions[index]
      lock.unlock()

      downstreamLock.lock()
      downstreamRecursive = true

      self.actual.onNext(value)

      downstreamRecursive = false
      downstreamLock.unlock()

      if let subscription = subscription {
        innerRecursive = true
        subscription.request(1)
        innerRecursive = false
      }

      lock.lock()
    }
  }

  func cancel() {
    lock.lock()

    if self.done {
      lock.unlock()
      return
    }

    self.done = true
    lock.unlock()

    // cancel every inner subscription
    for (_, subscription) in self.subscriptions {
      subscription.cancel()
    }

    // cancel outer subscription
    self.subscription?.cancel()
  }

  func innerSubscribe(_ subscription: some Subscription, _ index: Int) {
    lock.lock()

    self.pendingSubscriptions -= 1
    self.subscriptions[index] = subscription

    let demand: UInt = self.requested == .max ? .max : 1

    lock.unlock()
    subscription.request(demand)
  }

  func innerNext(_ item: R, _ index: Int) {
    lock.lock()

    if self.requested == .max {
      lock.unlock()

      downstreamLock.lock()
      downstreamRecursive = true

      self.actual.onNext(item)

      downstreamRecursive = false
      downstreamLock.unlock()

      return
    }

    if self.requested == 0 || innerRecursive {
      buffer.append((index, item))
      lock.unlock()
      return
    }

    self.requested -= 1
    lock.unlock()

    downstreamLock.lock()
    downstreamRecursive = true

    self.actual.onNext(item)

    downstreamRecursive = false
    downstreamLock.unlock()

    self.request(1)
  }

  func innerError(_ error: Error, _ index: Int) {
    lock.lock()

    if done {
      lock.unlock()
      return
    }

    done = true
    lock.unlock()

    for (i, subscription) in self.subscriptions where i != index {
      subscription.cancel()
    }

    downstreamLock.lock()
    self.actual.onError(error)
    downstreamLock.unlock()
  }

  func innerComplete(_ index: Int) {
    lock.lock()
    subscriptions.removeValue(forKey: index)

    let downstreamCompleted =
      releaseLockThenSendCompletionDownstreamIfNeeded(outerFinished: outerFinished)

    if !downstreamCompleted {
      requestOneMorePublisher()
    }
  }

  private func requestOneMorePublisher() {
    if maxConcurrency != .max {
      outerLock.lock()
      subscription?.request(1)
      outerLock.unlock()
    }
  }

  @discardableResult
  private func releaseLockThenSendCompletionDownstreamIfNeeded(
    outerFinished: Bool
  ) -> Bool {
    if !done && outerFinished && buffer.isEmpty
      && subscriptions.count + pendingSubscriptions == 0
    {
      done = true
      lock.unlock()
      downstreamLock.lock()
      self.actual.onComplete()
      downstreamLock.unlock()
      return true
    }

    lock.unlock()
    return false
  }
}

private class FluxFlatMapInnerOperator<T, R>: Subscriber {
  typealias Item = R

  private let parent: FluxFlatMapOperator<T, R>
  private let index: Int

  init(_ parent: FluxFlatMapOperator<T, R>, _ index: Int) {
    self.parent = parent
    self.index = index
  }

  func onSubscribe(_ subscription: some Subscription) {
    self.parent.innerSubscribe(subscription, self.index)
  }

  func onNext(_ item: R) {
    self.parent.innerNext(item, self.index)
  }

  func onError(_ error: Error) {
    self.parent.innerError(error, self.index)
  }

  func onComplete() {
    self.parent.innerComplete(self.index)
  }
}

extension Flux {
  public func flatMap<R>(
    maxConcurrency: UInt = .max,
    _ mapper: @escaping (T) throws -> any Publisher<R>
  ) -> Flux<R> {
    return Flux<R>(publisher: FlatMapPublisher(mapper, publisher, maxConcurrency))
  }

  public func flatMap<R, C: AsPublisher<R>>(
    maxConcurrency: UInt = .max,
    _ mapper: @escaping (T) throws -> C
  ) -> Flux<R> {
    return flatMap(maxConcurrency: maxConcurrency) { try mapper($0).asPublisher() }
  }
}
