import Foundation
import Nimble
import ReactiveStreams

class AssertSubscriber<T>: Subscriber {
  typealias Item = T

  var subscription: (any Subscription)?

  let produced: BlockingQueue<T> = .init()
  let errors: BlockingQueue<Error> = .init()

  var completed = false

  let subscriptionSemaphore: DispatchSemaphore = .init(value: 0)
  let completionSemaphore: DispatchSemaphore = .init(value: 0)

  func onSubscribe(_ subscription: some Subscription) {
    logger.debug("onSubscribe()")

    self.subscription = subscription
    subscriptionSemaphore.signal()
  }

  func onNext(_ element: T) {
    logger.debug("onNext(\(element))")
    produced.add(element)
  }

  func onError(_ error: Error) {
    logger.debug("onError(\(error))")
    errors.add(error)
  }

  func onComplete() {
    logger.debug("onComplete()")

    self.completed = true
    completionSemaphore.signal()
  }

  func requestNext(_ demand: UInt = 1) {
    if self.subscription == nil {
      fatalError("Subscription not set")
    }

    self.subscription!.request(demand)
  }

  func cancel() {
    if self.subscription == nil {
      fatalError("Subscription not set")
    }

    self.subscription!.cancel()
  }

  @discardableResult
  func expectSubscription() -> Subscription {
    subscriptionSemaphore.wait()
    expect(self.subscription).notTo(beNil())

    return subscription!
  }

  @discardableResult
  func expectNext(_ elements: Int) -> [T] {
    let produced = self.produced.takeAll(.now() + 0.1)

    expect(produced)
      .to(haveCount(elements), description: "expectNext called but no elements produced")

    return produced
  }

  @discardableResult
  func expectNextOrNone(_ elements: Int) -> [T] {
    let produced = self.produced.takeAll(.now() + 0.1)

    if !produced.isEmpty {
      expect(produced)
        .to(haveCount(elements), description: "expectNext called but no elements produced")

      return produced
    }

    return []
  }

  @discardableResult
  func expectNext() -> T {
    let item = expectNext(1).first
    expect(item).notTo(beNil())

    return item!
  }

  func expectNoErrors() {
    expect(self.errors.takeAll(.now() + 0.1)).to(beEmpty())
  }

  func expectNone() {
    expect(self.produced.takeAll(.now() + 0.1)).to(beEmpty())
  }

  func expectCompletion() {
    expect(self.completionSemaphore.wait(timeout: .now() + 10) == DispatchTimeoutResult.success)
      .to(beTrue(), description: "expectCompletion timed out")

    expect(self.completed).to(beTrue())
  }
}
