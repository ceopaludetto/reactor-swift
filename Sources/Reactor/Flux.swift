import ReactiveStreams

public struct Flux<T>: AsPublisher {
  internal let publisher: any Publisher<T>

  internal init(publisher: some Publisher<T>) {
    self.publisher = publisher
  }

  public func asPublisher() -> any Publisher<T> {
    return publisher
  }
}

extension Flux {
  public func subscribe(_ subscriber: some Subscriber<T>) {
    publisher.subscribe(subscriber)
  }

  public func subscribe(_ onNext: @escaping (T) -> Void) {
    let subscriber = CallbackSubscriber(onNext: onNext)
    subscribe(subscriber)
  }
}
