import Nimble
import Quick
import ReactiveStreams
import XCTest

public class PublisherVerificationExecutor: Quick.SyncDSLUser {
  private static func createTestContextWithMultipleSubscribers<V: PublisherVerification>(
    _ verification: V,
    _ demand: UInt,
    _ quantity: UInt,
    _ test: @escaping (any Publisher<V.Item>, [AssertSubscriber<V.Item>]) -> Void
  ) throws where V.Item: Equatable {
    let max = verification.maxElementsFromPublisher()

    if demand > max {
      throw XCTSkip("Demand \(demand) is greater than maxElementsFromPublisher \(max)")
    }

    let publisher = verification.createPublisher(demand)
    var subscribers: [AssertSubscriber<V.Item>] = []

    for _ in 0..<quantity {
      let subscriber = AssertSubscriber<V.Item>()
      subscribers.append(subscriber)

      publisher.subscribe(subscriber)
      subscriber.expectSubscription()
    }

    test(publisher, subscribers)
  }

  private static func createTestContext<V: PublisherVerification>(
    _ verification: V,
    _ demand: UInt,
    _ test: @escaping (any Publisher<V.Item>, AssertSubscriber<V.Item>) -> Void
  ) throws where V.Item: Equatable {
    try createTestContextWithMultipleSubscribers(verification, demand, 1) { publisher, subscibers in
      test(publisher, subscibers[0])
    }
  }

  private static func createFailedTestContext<V: PublisherVerification>(
    _ verification: V,
    _ test: @escaping (any Publisher<V.Item>, AssertSubscriber<V.Item>) -> Void
  ) throws where V.Item: Equatable {
    guard let publisher = verification.createFailedPublisher() else {
      throw XCTSkip("createFailedPublisher returned nil")
    }

    let subscriber = AssertSubscriber<V.Item>()

    publisher.subscribe(subscriber)
    subscriber.expectSubscription()

    test(publisher, subscriber)
  }

  public static func TCK<V: PublisherVerification>(_ verification: V) where V.Item: Equatable {
    describe("ReactiveStreams TCK") {
      describe("required") {
        describe("validate") {
          it("maxElementsFromPublisher") {
            expect(verification.maxElementsFromPublisher())
              .to(
                beGreaterThanOrEqualTo(1),
                description: "maxElementsFromPublisher MUST return a number >= 1")
          }

          it("boundedDepthOfOnNextAndRequestRecursion") {
            expect(verification.boundedDepthOfOnNextAndRequestRecursion())
              .to(
                beGreaterThanOrEqualTo(1),
                description: "boundedDepthOfOnNextAndRequestRecursion MUST return a number >= 1")
          }
        }

        it("createPublisher1MustProduceAStreamOfExactly1Element") {
          try createTestContext(verification, 1) { publisher, subscriber in
            subscriber.requestNext(1)
            subscriber.expectNext()

            subscriber.expectCompletion()
          }
        }

        it("createPublisher3MustProduceAStreamOfExactly3Elements") {
          try createTestContext(verification, 3) { publisher, subscriber in
            subscriber.requestNext(3)
            subscriber.expectNext(3)

            subscriber.expectCompletion()
          }
        }

        context("spec101") {
          it("subscriptionRequestMustResultInTheCorrectNumberOfProducedElements") {
            try createTestContext(verification, 5) { publisher, subscriber in
              subscriber.expectNone()

              subscriber.requestNext(1)
              subscriber.expectNext()

              subscriber.expectNone()

              subscriber.requestNext(1)
              subscriber.requestNext(2)
              subscriber.expectNext(3)

              subscriber.expectNone()

              subscriber.cancel()
            }
          }
        }

        context("spec102") {
          it("maySignalLessThanRequestedAndTerminateSubscription") {
            try createTestContext(verification, 3) { publisher, subscriber in
              subscriber.requestNext(10)
              subscriber.expectNext(3)
              subscriber.expectCompletion()
            }
          }
        }

        context("spec105") {
          it("mustSignalOnCompleteWhenFiniteStreamTerminates") {
            try createTestContext(verification, 3) { publisher, subscriber in
              subscriber.requestNext()
              subscriber.requestNext()
              subscriber.requestNext()
              subscriber.expectNext(3)

              subscriber.requestNext()
              subscriber.expectCompletion()

              subscriber.expectNone()
            }
          }
        }

        context("spec107") {
          it("mustNotEmitFurtherSignalsOnceOnCompleteHasBeenSignalled") {
            try createTestContext(verification, 1) { publisher, subscriber in
              subscriber.requestNext(10)
              subscriber.expectNext()
              subscriber.expectCompletion()

              subscriber.requestNext(10)
              subscriber.expectNone()
            }
          }
        }

        context("spec109") {
          it("subscribeThrowNPEOnNullSubscriber") {
            throw XCTSkip("Not needed on swift")
          }

          it("mustIssueOnSubscribeForNonNullSubscriber") {
            try createTestContext(verification, 0) { publisher, subscriber in
              expect(subscriber.subscription.value).notTo(beNil())
              expect(subscriber.registeredCalls.first).to(equal(.onSubscribe))
            }
          }

          xit(
            "mayRejectCallsToSubscribeIfPublisherIsUnableOrUnwillingToServeThemRejectionMustTriggerOnErrorAfterOnSubscribe"
          ) {

          }
        }

        context("spec302") {
          it("mustAllowSynchronousRequestCallsFromOnNextAndOnSubscribe") {
            try createTestContext(verification, 6) { publisher, subscriber in
              subscriber.requestNext(1)
              subscriber.requestNext(1)
              subscriber.requestNext(1)

              subscriber.registerCustomOnNextCallback { _ in
                subscriber.requestNext(1)
              }

              subscriber.expectNoErrors()
            }
          }
        }

        context("spec303") {
          xit("mustNotAllowUnboundedRecursion") {

          }
        }

        context("spec306") {
          it("afterSubscriptionIsCancelledRequestMustBeNops") {
            try createTestContext(verification, 3) { publisher, subscriber in
              subscriber.cancel()

              subscriber.requestNext()
              subscriber.requestNext()
              subscriber.requestNext()

              subscriber.expectNone()
              subscriber.expectNoErrors()
            }
          }
        }

        context("spec307") {
          it("afterSubscriptionIsCancelledAdditionalCancelationsMustBeNops") {
            try createTestContext(verification, 1) { publisher, subscriber in
              let subscription = subscriber.subscription.value
              expect(subscription).notTo(beNil())

              subscription!.cancel()
              subscription!.cancel()
              subscription!.cancel()

              subscriber.expectNone()
              subscriber.expectNoErrors()
            }
          }
        }

        context("spec309") {
          it("requestZeroMustSignalIllegalArgumentException") {
            try createTestContext(verification, 10) { publisher, subscriber in
              subscriber.requestNext(0)
              subscriber.expectAnyError()
            }
          }

          it("requestNegativeNumberMustSignalIllegalArgumentException") {
            throw XCTSkip("Not needed on swift")
          }
        }

        context("spec312") {
          xit("cancelMustMakeThePublisherToEventuallyStopSignaling") {
            try createTestContext(verification, 20) { publisher, subscriber in
              subscriber.requestNext(10)
              subscriber.requestNext(5)

              subscriber.expectNext()
              subscriber.cancel()

              var onNextCount = 0
              var stillBeingSignalled: Bool

              repeat {
                subscriber.expectNone()

                let error = subscriber.expectAnyError()
                if error == nil {
                  stillBeingSignalled = false
                } else {
                  stillBeingSignalled = true
                  onNextCount += 1
                }

                expect(onNextCount).to(beLessThanOrEqualTo(15))
              } while stillBeingSignalled
            }
          }
        }

        context("spec313") {
          it("cancelMustMakeThePublisherEventuallyDropAllReferencesToTheSubscriber") {
            throw XCTSkip("Probably not testable on swift since it's use ARC")
          }
        }

        context("spec317") {
          it("mustSupportAPendingElementCountUpToLongMaxValue") {
            try createTestContext(verification, 3) { publisher, subscriber in
              subscriber.requestNext(.max)

              subscriber.expectNext(3)
              subscriber.expectCompletion()

              subscriber.expectNoErrors()
            }
          }

          it("mustSupportACumulativePendingElementCountUpToLongMaxValue") {
            try createTestContext(verification, 3) { publisher, subscriber in
              subscriber.requestNext(.max / 2)
              subscriber.requestNext(.max / 2)
              subscriber.requestNext(1)

              subscriber.expectNext(3)
              subscriber.expectCompletion()

              subscriber.expectNoErrors()
            }
          }

          it("mustNotSignalOnErrorWhenPendingAboveLongMaxValue") {
            try createTestContext(verification, .max) { publisher, subscriber in
              // arbitrarily set limit on nuber of request calls signalled, we expect overflow after already 2 calls,
              // so 10 is relatively high and safe even if arbitrarily chosen
              var calls = 10

              subscriber.registerCustomOnNextCallback { _ in
                if calls > 0 {
                  subscriber.requestNext(.max - 1)
                  calls -= 1

                  return
                }

                subscriber.cancel()
              }

              // eventually triggers `onNext`, which will then trigger up to `callsCounter` times `request(Long.MAX_VALUE - 1)`
              // we're pretty sure to overflow from those
              subscriber.requestNext()
              subscriber.expectNoErrors()
            }
          }
        }
      }

      describe("stochastic") {
        context("spec103") {
          xit("mustSignalOnMethodsSequentially") {}
        }
      }

      describe("optional") {
        context("spec104") {
          it("mustSignalOnErrorWhenFails") {
            // TODO: actually is broken
            try createFailedTestContext(verification) { publisher, subscriber in
              expect(subscriber.expectAnyError()).notTo(beNil())
              expect(subscriber.registeredCalls).to(equal([.onSubscribe, .onError]))
            }
          }
        }

        context("spec105") {
          it("emptyStreamMustTerminateBySignallingOnComplete") {
            try createTestContext(verification, 0) { publisher, subscriber in
              subscriber.requestNext()

              subscriber.expectCompletion()
              subscriber.expectNone()
            }
          }
        }

        context("spec111") {
          it("maySupportMultiSubscribe") {
            let subscriber1 = AssertSubscriber<V.Item>()
            let subscriber2 = AssertSubscriber<V.Item>()

            let publisher = verification.createPublisher(1)

            publisher.subscribe(subscriber1)
            publisher.subscribe(subscriber2)

            subscriber1.expectNoErrors()
            subscriber2.expectNoErrors()

            subscriber1.cancel()
            subscriber2.cancel()
          }

          it("registeredSubscribersMustReceiveOnNextOrOnCompleteSignals") {
            let subscriber1 = AssertSubscriber<V.Item>()
            let subscriber2 = AssertSubscriber<V.Item>()

            let publisher = verification.createPublisher(1)

            publisher.subscribe(subscriber1)
            publisher.subscribe(subscriber2)

            subscriber1.requestNext()
            subscriber2.requestNext()

            subscriber1.expectNextOrNone(1)
            subscriber2.expectNextOrNone(1)

            subscriber1.expectCompletion()
            subscriber2.expectCompletion()

            subscriber1.cancel()
            subscriber2.cancel()
          }

          it(
            "mustProduceTheSameElementsInTheSameSequenceToAllOfItsSubscribersWhenRequestingOneByOne"
          ) {
            try createTestContextWithMultipleSubscribers(verification, 5, 3) {
              let subscriber1 = $1[0]
              let subscriber2 = $1[1]
              let subscriber3 = $1[2]

              subscriber1.requestNext()
              let x1 = subscriber1.expectNext()

              subscriber2.requestNext(2)
              let y1 = subscriber2.expectNext(2)

              subscriber1.requestNext()
              let x2 = subscriber1.expectNext()

              subscriber3.requestNext(3)
              let z1 = subscriber3.expectNext(3)

              subscriber3.requestNext()
              let z2 = subscriber3.expectNext()

              subscriber3.requestNext()
              let z3 = subscriber3.expectNext()
              // TODO: request end

              subscriber2.requestNext(3)
              let y2 = subscriber2.expectNext(3)
              // TODO: request end

              subscriber1.requestNext(2)
              let x3 = subscriber1.expectNext(2)

              subscriber1.requestNext()
              let x4 = subscriber1.expectNext()
              // TODO: request end

              let r = [x1, x2] + x3 + [x4]

              let check1 = y1 + y2
              let check2 = z1 + [z2, z3]

              expect(r).to(equal(check1))
              expect(r).to(equal(check2))
            }
          }

          it(
            "mustProduceTheSameElementsInTheSameSequenceToAllOfItsSubscribersWhenRequestingManyUpfront"
          ) {
            try createTestContextWithMultipleSubscribers(verification, 3, 3) {
              let subscriber1 = $1[0]
              let subscriber2 = $1[1]
              let subscriber3 = $1[2]

              subscriber1.requestNext(4)
              subscriber2.requestNext(4)
              subscriber3.requestNext(4)

              let r1 = subscriber1.expectNext(3)
              let r2 = subscriber2.expectNext(3)
              let r3 = subscriber3.expectNext(3)

              expect(r1).to(equal(r2))
              expect(r2).to(equal(r3))
            }
          }

          it(
            "mustProduceTheSameElementsInTheSameSequenceToAllOfItsSubscribersWhenRequestingManyUpfrontAndCompleteAsExpected"
          ) {
            try createTestContextWithMultipleSubscribers(verification, 3, 3) {
              let subscriber1 = $1[0]
              let subscriber2 = $1[1]
              let subscriber3 = $1[2]

              subscriber1.requestNext(4)
              subscriber2.requestNext(4)
              subscriber3.requestNext(4)

              let r1 = subscriber1.expectNext(3)
              let r2 = subscriber2.expectNext(3)
              let r3 = subscriber3.expectNext(3)

              subscriber1.expectCompletion()
              subscriber2.expectCompletion()
              subscriber3.expectCompletion()

              expect(r1).to(equal(r2))
              expect(r2).to(equal(r3))
            }
          }
        }

        context("spec309") {
          it("requestNegativeNumberMaySignalIllegalArgumentExceptionWithSpecificMessage") {
            throw XCTSkip("Not needed on swift")
          }
        }
      }

      describe("untested") {
        context("spec106") {
          it("mustConsiderSubscriptionCancelledAfterOnErrorOrOnCompleteHasBeenCalled") {
            throw XCTSkip("Not really testable without more control over the publisher")
          }
        }

        context("spec107") {
          it("mustNotEmitFurtherSignalsOnceOnErrorHasBeenSignalled") {
            throw XCTSkip("Can we meaningfully test this, without more control over the publisher?")
          }
        }

        context("spec108") {
          it("possiblyCanceledSubscriptionShouldNotReceiveOnErrorOrOnCompleteSignals") {
            throw XCTSkip("Can we meaningfully test this?")
          }
        }

        context("spec109") {
          it("subscribeShouldNotThrowNonFatalThrowable") {
            throw XCTSkip("Can we meaningfully test this?")
          }
        }

        context("spec110") {
          it("rejectASubscriptionRequestIfTheSameSubscriberSubscribesTwice") {
            throw XCTSkip("Can we meaningfully test this?")
          }
        }

        context("spec304") {
          it("requestShouldNotPerformHeavyComputations") {
            throw XCTSkip("Cannot be meaningfully tested")
          }
        }

        context("spec305") {
          it("cancelMustNotSynchronouslyPerformHeavyComputation") {
            throw XCTSkip("Cannot be meaningfully tested")
          }
        }
      }
    }
  }
}
