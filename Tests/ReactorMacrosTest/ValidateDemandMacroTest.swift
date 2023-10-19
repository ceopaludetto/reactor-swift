import MacroTesting
import Quick
import XCTest

@testable import ReactorMacros

class ValidateDemandMacroTest: QuickSpec {
	override class func spec() {
		it("should expand #validateDemand correctly") {
			assertMacro(["validateDemand": ValidateDemandMacro.self]) {
				"""
				#validateDemand(demand, self.cancel, self.actual.onError)
				"""
			} expansion: {
				"""
				if case .failure(let error) = Validator.demand(demand) {
						self.cancel()
						self.actual.onError(error)

						return
				}
				"""
			}
		}
	}
}
