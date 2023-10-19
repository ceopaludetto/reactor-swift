import Foundation
import ReactiveStreams

@ReactivePublisher
public struct Flux<T> {}

extension Flux {
  public func subscribe(_ subscriber: some Subscriber<T>) {
    publisher.subscribe(subscriber)
  }

  public func subscribe(_ onNext: @escaping (T) -> Void) {
    let subscriber = CallbackSubscriber(onNext: onNext)
    subscribe(subscriber)
  }
}
