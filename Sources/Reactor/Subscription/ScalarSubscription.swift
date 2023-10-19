import Foundation
import ReactiveStreams

internal class ScalarSubscription<T>: Subscription {
  private var actual: any Subscriber<T>
  private let item: T

  private let lock: NSLock = .init()
  private var cancelled: Bool = false

  init(subscriber: any Subscriber<T>, item: T) {
    self.actual = subscriber
    self.item = item
  }

  func request(_ demand: UInt) {
    #validateDemand(demand, cancel, actual.onError)

    lock.lock()
    defer { lock.unlock() }

    actual.onNext(item)
    actual.onComplete()

    self.cancelled = true
  }

  func cancel() {
    lock.lock()
    defer { lock.unlock() }

    self.cancelled = true
  }
}
