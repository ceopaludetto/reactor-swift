import Atomics
import ReactiveStreams

internal class ScalarSubscription<T>: Subscription {
  private var actual: any Subscriber<T>
  private let item: T

  private let done: ManagedAtomic<Bool> = .init(false)

  init(subscriber: any Subscriber<T>, item: T) {
    self.actual = subscriber
    self.item = item
  }

  func request(_ demand: UInt) {
    if case .failure(let error) = Validator.demand(demand) {
      cancel()
      actual.onError(error)

      return
    }

    if done.load(ordering: .relaxed) {
      return
    }

    actual.onNext(item)
    actual.onComplete()

    done.store(true, ordering: .relaxed)
  }

  func cancel() {
    done.store(true, ordering: .relaxed)
  }
}
