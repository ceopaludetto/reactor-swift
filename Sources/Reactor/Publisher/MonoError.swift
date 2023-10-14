import ReactiveStreams

internal class MonoErrorPublisher<T>: Publisher {
  typealias Item = T

  private let error: Error

  init(_ error: Error) {
    self.error = error
  }

  func subscribe(_ subscriber: some Subscriber<Item>) {
    subscriber.onSubscribe(EmptySubscription())
    subscriber.onError(error)
  }
}

extension Mono {
  public static func error(_ error: some Error) -> Mono<T> {
    return Mono(publisher: MonoErrorPublisher(error))
  }
}
