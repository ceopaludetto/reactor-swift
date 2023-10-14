import ReactiveStreams

internal class MonoJustPublisher<T>: Publisher {
  typealias Item = T

  private let item: T

  init(_ item: T) {
    self.item = item
  }

  func subscribe(_ subscriber: some Subscriber<Item>) {
    subscriber.onSubscribe(ScalarSubscription(subscriber: subscriber, item: item))
  }
}

extension Mono {
  public static func just(_ item: T) -> Mono<T> {
    return Mono(publisher: MonoJustPublisher(item))
  }
}
