import Atomics
import ReactiveStreams

internal class MonoResultPublisher<T, E: Error>: Publisher {
  typealias Item = T

  private let result: Result<T, E>

  init(_ result: Result<T, E>) {
    self.result = result
  }

  func subscribe(_ subscriber: some Subscriber<Item>) {
    subscriber.onSubscribe(MonoResultSubscription(subscriber: subscriber, result: result))
  }
}

internal class MonoResultSubscription<T, E: Error>: Subscription {
  private let actual: any Subscriber<T>
  private let result: Result<T, E>

  private let cancelled: ManagedAtomic<Bool> = .init(false)

  init(subscriber: any Subscriber<T>, result: Result<T, E>) {
    self.actual = subscriber
    self.result = result
  }

  func request(_ demand: UInt) {
    #validateDemand(demand, cancel, actual.onError)

    switch result {
    case .success(let value):
      actual.onNext(value)
      actual.onComplete()
    case .failure(let error):
      actual.onError(error)
    }
  }

  func cancel() {
    self.cancelled.store(true, ordering: .relaxed)
  }
}

extension Mono {
  public static func fromResult<E: Error>(_ result: Result<T, E>) -> Mono<T> {
    return Mono(publisher: MonoResultPublisher(result))
  }
}
