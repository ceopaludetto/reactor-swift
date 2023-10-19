import Foundation
import ReactiveStreams

internal class FluxJustPublisher<T, S: Sequence<T>>: Publisher {
  typealias Item = T

  private let items: S

  init(_ items: S) {
    self.items = items
  }

  func subscribe(_ subscriber: some Subscriber<Item>) {
    let subscription = FluxJustSubscription<T, S>(
      subscriber: subscriber,
      iterator: items.makeIterator()
    )

    if subscription.isExhausted {
      subscriber.onSubscribe(EmptySubscription())
      subscriber.onComplete()

      subscription.cancel()
      return
    }

    subscriber.onSubscribe(subscription)
  }
}

internal class FluxJustSubscription<T, S: Sequence<T>>: Subscription {
  private var actual: (any Subscriber<T>)
  private var iterator: (PeekableIterator<S.Iterator>)

  private var lock: NSLock = .init()

  private var requested: UInt = 0
  private var recursion: Bool = false
  private var cancelled: Bool = false

  init(subscriber: any Subscriber<T>, iterator: S.Iterator) {
    self.actual = subscriber
    self.iterator = PeekableIterator(iterator)
  }

  fileprivate var isExhausted: Bool {
    return iterator.peek() == nil
  }

  func request(_ demand: UInt) {
    #validateDemand(demand, cancel, actual.onError)

    lock.lock()
    requested ~+= demand

    if recursion {
      lock.unlock()
      return
    }

    while !self.cancelled, requested > 0 {
      if let next = iterator.next() {
        self.requested -= 1
        recursion = true
        lock.unlock()

        actual.onNext(next)
        lock.lock()

        recursion = false
      }

      if iterator.peek() == nil {
        self.cancelled = true

        lock.unlock()
        actual.onComplete()

        return
      }
    }

    lock.unlock()
  }

  func cancel() {
    lock.lock()
    defer { lock.unlock() }

    self.cancelled = true
  }
}

extension Flux {
  public static func just(_ items: some Sequence<T>) -> Flux<T> {
    return Flux(publisher: FluxJustPublisher(items))
  }
}
