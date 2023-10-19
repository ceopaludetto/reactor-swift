import SwiftSyntax
import SwiftSyntaxMacros

public struct ValidateDemandMacro: DeclarationMacro {
	public static func expansion(
		of node: some FreestandingMacroExpansionSyntax,
		in _: some MacroExpansionContext
	) throws -> [DeclSyntax] {
		let args = node.argumentList.extractArguments()

		guard args.count == 3 else {
			throw MacroError.invalidArgumentCount(args.count, 3)
		}

		let demand = args[0]
		let cancel = args[1]
		let onError = args[2]

		return [
			"""
			if case .failure(let error) = Validator.demand(\(raw: demand)) {
			  \(raw: cancel)()
			  \(raw: onError)(error)

			  return
			}
			""",
		]
	}
}
