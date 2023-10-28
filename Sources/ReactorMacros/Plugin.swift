import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct ReactorMacrosPlugin: CompilerPlugin {
	let providingMacros: [Macro.Type] = [
		ReactivePublisherMacro.self,
	]
}
