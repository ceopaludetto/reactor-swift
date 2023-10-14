import ReactiveStreams

internal class MonoEmptyPublisher<T>: Publisher {
  typealias Item = T

  func subscribe(_ subscriber: some Subscriber<Item>) {
    subscriber.onSubscribe(EmptySubscription())
    subscriber.onComplete()
  }
}

extension Mono {
  public static func empty() -> Mono<T> {
    return Mono(publisher: MonoEmptyPublisher())
  }
}
