import Atomics
import Nimble
import Quick

@testable import Reactor

class ValidatorTest: QuickSpec {
  override class func spec() {
    describe("Validator") {
      describe("demand") {
        it("should return failure when demand is 0") {
          expect(Validator.demand(0)).to(beFailure())
        }

        it("should return success when demand is greater than 0") {
          expect(Validator.demand(.max)).to(beSuccess())
        }
      }

      describe("addCap") {
        it("should return nil when requested is max") {
          let requested: ManagedAtomic<UInt> = .init(.max)

          expect(Validator.addCap(1, requested)).to(beNil())
        }

        it("should return nil when requested is equal to demand and greater than 0") {
          let requested: ManagedAtomic<UInt> = .init(1)

          expect(Validator.addCap(1, requested)).to(beNil())
        }

        it("should return demand when requested is 0") {
          let requested: ManagedAtomic<UInt> = .init(0)

          expect(Validator.addCap(1, requested)).to(equal(1))
        }
      }
    }
  }
}
