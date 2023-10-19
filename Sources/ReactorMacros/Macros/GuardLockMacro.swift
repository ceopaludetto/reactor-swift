import SwiftSyntax
import SwiftSyntaxMacros

public struct GuardLockMacro: DeclarationMacro {
  public static func expansion(
    of node: some FreestandingMacroExpansionSyntax,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    let args = node.argumentList.extractArguments()

    guard args.count == 3 else {
      throw MacroError.invalidArgumentCount(args.count, 3)
    }

    let lock = args[0]
    let done = args[1]
    let type = args[2]

    let isTerminal = type.as(MemberAccessExprSyntax.self)?.declName.baseName.text == "terminal"

    return [
      """
      \(raw: lock).lock()
      guard !\(raw: done) else {
      	\(raw: lock).unlock()
      	return
      }

      \(raw: isTerminal ? "\(done).toggle()" : "")
      \(raw: lock).unlock()
      """
    ]
  }
}
