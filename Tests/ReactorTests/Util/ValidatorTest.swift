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
    }
  }
}
