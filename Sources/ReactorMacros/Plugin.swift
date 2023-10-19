import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct ReactorMacrosPlugin: CompilerPlugin {
  let providingMacros: [Macro.Type] = [
    GuardLockMacro.self,
    ReactivePublisherMacro.self,
    ValidateDemandMacro.self
  ]
}
