import Nimble
import Quick
import ReactiveStreams
import TCK

@testable import Reactor

struct FluxJustPublisherTCK: PublisherVerification {
  typealias Item = UInt

  func createPublisher(_ elements: UInt) -> any Publisher<Item> {
    return FluxJustPublisher(0..<elements)
  }

  func createFailedPublisher() -> (any Publisher<Item>)? {
    return nil
  }

  func maxElementsFromPublisher() -> UInt {
    return .max
  }

  func boundedDepthOfOnNextAndRequestRecursion() -> UInt {
    return 1
  }
}

class FluxJustTest: QuickSpec {
  override class func spec() {
    PublisherVerificationExecutor.TCK(FluxJustPublisherTCK())
  }
}

class FluxJustAsyncTest: AsyncSpec {
  override class func spec() {
    it("should await list of elements") {
      let items = try await Flux.just(1...)
        .take(100)
        .awaitList()

      expect(items).to(haveCount(100))
      expect(items).to(equal(Array(1...100)))
    }

    it("battle test") {
      let items = try await Flux.just(1...)
        .take(1000)
        .takeWhile { _ in true }
        .takeUntil { _ in false }
        .filter { _ in true }
        .index()
        .map { $1 }
        .flatMap { Mono.just($0) }
        .concatMap { Mono.just($0) }
        .awaitList()

      expect(items).to(haveCount(1000))
      expect(items).to(equal(Array(1...1000)))
    }
  }
}
