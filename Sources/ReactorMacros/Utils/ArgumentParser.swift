import SwiftSyntax

extension LabeledExprListSyntax {
	func extractArguments() -> [ExprSyntax] {
		map(\.expression)
	}
}
