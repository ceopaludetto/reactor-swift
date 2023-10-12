import ReactiveStreams

internal class EmptyPublisher<T>: Publisher {
  typealias Item = T

  func subscribe(_ subscriber: some Subscriber<Item>) {
    subscriber.onSubscribe(EmptySubscription())
    subscriber.onComplete()
  }
}

internal class EmptySubscription: Subscription {
  func request(_ demand: UInt) {
    // noop
  }

  func cancel() {
    // noop
  }
}

extension Flux {
  public static func empty() -> Flux<T> {
    return Flux(publisher: EmptyPublisher())
  }
}
