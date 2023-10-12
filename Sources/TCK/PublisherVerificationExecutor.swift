import Nimble
import Quick
import ReactiveStreams

public class PublisherVerificationExecutor: Quick.SyncDSLUser {
  private static func createTestContext<V: PublisherVerification>(
    _ verification: V,
    _ demand: UInt,
    _ test: @escaping (any Publisher<V.Item>, AssertSubscriber<V.Item>) -> Void
  ) {
    let publisher = verification.createPublisher(demand)
    let subscriber = AssertSubscriber<V.Item>()

    publisher.subscribe(subscriber)
    subscriber.expectSubscription()

    test(publisher, subscriber)
  }

  public static func TCK<V: PublisherVerification>(_ verification: V) {
    describe("ReactiveStreams TCK") {
      describe("validate") {
        it("maxElementsFromPublisher") {
          expect(verification.maxElementsFromPublisher())
            .to(beGreaterThan(0), description: "maxElementsFromPublisher MUST return a number >= 0")
        }
      }

      describe("required") {
        it("createPublisher1MustProduceAStreamOfExactly1Element") {
          createTestContext(verification, 1) { publisher, subscriber in
            subscriber.requestNext(1)
            subscriber.expectNext()

            subscriber.expectCompletion()
          }
        }

        it("createPublisher3MustProduceAStreamOfExactly3Elements") {
          createTestContext(verification, 3) { publisher, subscriber in
            subscriber.requestNext(3)
            subscriber.expectNext(3)

            subscriber.expectCompletion()
          }
        }

        context("spec101") {
          it("subscriptionRequestMustResultInTheCorrectNumberOfProducedElements") {
            createTestContext(verification, 5) { publisher, subscriber in
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
            createTestContext(verification, 3) { publisher, subscriber in
              subscriber.requestNext(10)
              subscriber.expectNext(3)
              subscriber.expectCompletion()
            }
          }
        }

        context("spec105") {
          it("mustSignalOnCompleteWhenFiniteStreamTerminates") {
            createTestContext(verification, 3) { publisher, subscriber in
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
            createTestContext(verification, 1) { publisher, subscriber in
              subscriber.requestNext(10)
              subscriber.expectNext()
              subscriber.expectCompletion()

              subscriber.requestNext(10)
              subscriber.expectNone()
            }
          }
        }

        context("spec306") {
          it("afterSubscriptionIsCancelledRequestMustBeNops") {
            createTestContext(verification, 3) { publisher, subscriber in
              subscriber.cancel()

              subscriber.requestNext()
              subscriber.requestNext()
              subscriber.requestNext()

              subscriber.expectNone()
              subscriber.expectNoErrors()
            }
          }
        }
      }

      describe("optional") {
        context("spec105") {
          it("emptyStreamMustTerminateBySignallingOnComplete") {
            createTestContext(verification, 0) { publisher, subscriber in
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

          xit(
            "mustProduceTheSameElementsInTheSameSequenceToAllOfItsSubscribersWhenRequestingOneByOne"
          ) {}
          xit(
            "mustProduceTheSameElementsInTheSameSequenceToAllOfItsSubscribersWhenRequestingManyUpfront"
          ) {}
        }

      }
    }
  }
}
