import MacroTesting
import Quick
import XCTest

@testable import ReactorMacros

class ReactivePublisherMacroTest: QuickSpec {
	override class func spec() {
		it("should create publisher property correctly") {
			assertMacro(["ReactivePublisher": ReactivePublisherMacro.self]) {
				"""
				@ReactivePublisher
				class Test {}
				"""
			} expansion: {
				"""
				class Test {

				    internal let publisher: any Publisher<T>

				    internal init(publisher: some Publisher<T>) {
				    	self.publisher = publisher
				    }}

				extension Test: AsPublisher {
					public func asPublisher() -> any Publisher<T> {
						return self.publisher
					}
				}
				"""
			}
		}
	}
}
