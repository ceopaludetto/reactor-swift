import SwiftSyntax
import SwiftSyntaxMacros

public struct ReactivePublisherMacro: ExtensionMacro, MemberMacro {
	public static func expansion(
		of _: AttributeSyntax,
		providingMembersOf _: some DeclGroupSyntax,
		in _: some MacroExpansionContext
	) throws -> [DeclSyntax] {
		[
			"""
			internal let publisher: any Publisher<T>

			internal init(publisher: some Publisher<T>) {
				self.publisher = publisher
			}
			""",
		]
	}

	public static func expansion(
		of _: AttributeSyntax,
		attachedTo _: some DeclGroupSyntax,
		providingExtensionsOf type: some TypeSyntaxProtocol,
		conformingTo _: [TypeSyntax],
		in _: some MacroExpansionContext
	) throws -> [ExtensionDeclSyntax] {
		try [
			ExtensionDeclSyntax(
				"""
				extension \(type): PublisherConvertible {
					public func toPublisher() -> any Publisher<T> {
						return self.publisher
					}
				}
				"""
			),
		]
	}
}
