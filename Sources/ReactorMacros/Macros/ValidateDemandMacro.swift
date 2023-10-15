import SwiftSyntax
import SwiftSyntaxMacros

enum ValidateDemandMacroError: Error {
  case invalidArgumentCount
}

public struct ValidateDemandMacro: DeclarationMacro {
  public static func expansion(
    of node: some FreestandingMacroExpansionSyntax,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    guard let varName = node.argumentList.first else {
      throw ValidateDemandMacroError.invalidArgumentCount
    }

    guard let cancelFn = node.argumentList.dropFirst().first else {
      throw ValidateDemandMacroError.invalidArgumentCount
    }

    guard let onErrorFn = node.argumentList.dropFirst(2).first else {
      throw ValidateDemandMacroError.invalidArgumentCount
    }

    return [
      """
      if case .failure(let error) = Validator.demand(\(varName.expression)) {
        \(cancelFn.expression)()
        \(onErrorFn.expression)(error)

        return
      }
      """
    ]
  }
}
