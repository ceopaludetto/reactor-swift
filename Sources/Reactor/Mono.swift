import ReactiveStreams

@ReactivePublisher
public struct Mono<T> {}

extension Mono {
  public func subscribe(_ subscriber: some Subscriber<T>) {
    publisher.subscribe(subscriber)
  }

  public func subscribe(_ onNext: @escaping (T) -> Void) {
    let subscriber = CallbackSubscriber(onNext: onNext)
    subscribe(subscriber)
  }
}
