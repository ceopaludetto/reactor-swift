import Nimble
import Quick

@testable import Reactor

class DemandTest: QuickSpec {
  override class func spec() {
    describe("Demand") {
      describe("~+") {
        it("should return correct sum when adding two demands") {
          expect(1 ~+ 1).to(equal(2))
        }

        it("should return .max when overflow") {
          expect(1 ~+ .max).to(equal(.max))
          expect(.max ~+ .max).to(equal(.max))
        }
      }

      describe("~+=") {
        it("should return correct sum when modifying demand") {
          var demand: UInt = 1
          demand ~+= 1

          expect(demand).to(equal(2))
        }

        it("should return .max when overflow") {
          var demand: UInt = 1
          demand ~+= .max
          expect(demand).to(equal(.max))

          demand ~+= .max
          expect(demand).to(equal(.max))
        }
      }
    }
  }
}
