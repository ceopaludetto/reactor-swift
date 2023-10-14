import Atomics
import ReactiveStreams

internal class FluxJustPublisher<T, S: Sequence<T>>: Publisher {
  typealias Item = T

  private let items: S

  init(_ items: S) {
    self.items = items
  }

  func subscribe(_ subscriber: some Subscriber<Item>) {
    subscriber.onSubscribe(
      FluxJustSubscription<T, S>(
        subscriber: subscriber,
        items: items.makeIterator()
      )
    )
  }
}

internal class FluxJustSubscription<T, S: Sequence<T>>: Subscription {
  private var actual: any Subscriber<T>
  private var items: PeekableIterator<S.Iterator>

  private let cancelled: ManagedAtomic<Bool> = .init(false)
  private let requested: ManagedAtomic<UInt> = .init(0)

  init(subscriber: any Subscriber<T>, items: S.Iterator) {
    self.actual = subscriber
    self.items = PeekableIterator(items)
  }

  func request(_ demand: UInt) {
    if case .failure(let error) = Validator.demand(demand) {
      cancel()
      actual.onError(error)

      return
    }

    if let new = Validator.addCap(demand, requested) {
      if new == .max {
        self.fast()
        return
      }

      self.slow(new)
    }
  }

  func cancel() {
    self.cancelled.store(true, ordering: .relaxed)
  }

  private func fast() {
    while true {
      if cancelled.load(ordering: .relaxed) {
        return
      }

      if let item = items.next() {
        actual.onNext(item)
      }

      if items.peek() == nil {
        actual.onComplete()
        return
      }
    }
  }

  private func slow(_ demand: UInt) {
    var sent: UInt = 0
    var new: UInt = demand

    while true {
      while sent != new {
        if cancelled.load(ordering: .relaxed) {
          return
        }

        if let item = items.next() {
          sent += 1
          actual.onNext(item)
        }

        if items.peek() == nil {
          actual.onComplete()
          return
        }
      }

      new = requested.load(ordering: .relaxed)

      if sent == new {
        if requested.loadThenWrappingDecrement(by: sent, ordering: .relaxed) - sent == 0 {
          return
        }

        sent = 0
      }
    }
  }
}

extension Flux {
  public static func just(_ items: some Sequence<T>) -> Flux<T> {
    return Flux(publisher: FluxJustPublisher(items))
  }
}
