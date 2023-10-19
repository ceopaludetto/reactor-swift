import Quick
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

@testable import ReactorMacros

class ReactivePublisherMacroTest: QuickSpec {
	override class func spec() {
		it("should create publisher property correctly") {
			assertMacroExpansion(
				"""
				@ReactivePublisher
				class Test {}
				""",
				expandedSource:
				"""
				class Test {
					internal let publisher: any Publisher<T>

					internal init(publisher: some Publisher<T>) {
				    self.publisher = publisher
				  }
				}

				extension Test: AsPublisher {
				  public func asPublisher() -> any Publisher<T> {
				    self.publisher
				  }
				}
				""",
				macros: ["ReactivePublisher": ReactivePublisherMacro.self],
				indentationWidth: .tabs(2)
			)
		}
	}
}
