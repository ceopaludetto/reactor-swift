import Quick
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

@testable import ReactorMacros

class ValidateDemandMacroTest: QuickSpec {
	override class func spec() {
		it("should expand #validateDemand correctly") {
			assertMacroExpansion(
				"""
				#validateDemand(demand, self.cancel, self.actual.onError)
				""",
				expandedSource:
				"""
				if case .failure(let error) = Validator.demand(demand) {
					self.cancel()
					self.actual.onError(error)

					return
				}
				""",
				macros: ["validateDemand": ValidateDemandMacro.self],
				indentationWidth: .tabs(2)
			)
		}
	}
}
