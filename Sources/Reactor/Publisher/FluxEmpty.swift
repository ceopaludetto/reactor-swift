import ReactiveStreams

internal class FluxEmptyPublisher<T>: Publisher {
  typealias Item = T

  func subscribe(_ subscriber: some Subscriber<Item>) {
    subscriber.onSubscribe(EmptySubscription())
    subscriber.onComplete()
  }
}

extension Flux {
  public static func empty() -> Flux<T> {
    return Flux(publisher: FluxEmptyPublisher())
  }
}
