import SwiftSyntax

extension LabeledExprListSyntax {
  func extractArguments() -> [ExprSyntax] {
    return self.map { $0.expression }
  }
}
