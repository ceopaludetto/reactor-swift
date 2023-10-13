import Foundation
import ReactiveStreams

internal class CallbackSubscriber<T>: Subscriber {
  typealias Item = T

  private let onSubscribeCallback: ((any Subscription) -> Void)?
  private let onNextCallback: ((T) -> Void)?
  private let onErrorCallback: ((Error) -> Void)?
  private let onCompleteCallback: (() -> Void)?

  init(
  	onSubscribe: ((any Subscription) -> Void)? = nil,
    onNext: ((T) -> Void)? = nil,
    onError: ((Error) -> Void)? = nil,
    onComplete: (() -> Void)? = nil
  ) {
    self.onSubscribeCallback = onSubscribe
    self.onNextCallback = onNext
    self.onErrorCallback = onError
    self.onCompleteCallback = onComplete
  }

  func onSubscribe(_ subscription: some Subscription) {
    subscription.request(.max)
    self.onSubscribeCallback?(subscription)
  }

  func onNext(_ element: T) {
    onNextCallback?(element)
  }

  func onError(_ error: Error) {
    onErrorCallback?(error)
  }

  func onComplete() {
    onCompleteCallback?()
  }
}
