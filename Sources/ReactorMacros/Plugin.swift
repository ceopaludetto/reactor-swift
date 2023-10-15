#if canImport(SwiftCompilerPlugin)
  import SwiftCompilerPlugin
  import SwiftSyntaxMacros

  @main
  struct ReactorMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
      ValidateDemandMacro.self
    ]
  }
#endif
