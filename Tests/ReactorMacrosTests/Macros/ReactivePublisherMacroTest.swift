import MacroTesting
import Testing

@testable import ReactorMacros

struct ReactivePublisherMacroTest {
	@Test
	func shouldExpandReactivePublisherCorrectly() {
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

			extension Test: PublisherConvertible {
				public func toPublisher() -> any Publisher<T> {
					return self.publisher
				}
			}
			"""
		}
	}
}
