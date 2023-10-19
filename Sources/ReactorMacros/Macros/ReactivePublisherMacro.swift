import SwiftSyntax
import SwiftSyntaxMacros

public struct ReactivePublisherMacro: ExtensionMacro, MemberMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    return [
      """
      	internal let publisher: any Publisher<T>

        internal init(publisher: some Publisher<T>) {
          self.publisher = publisher
        }
      """
    ]
  }

  public static func expansion(
    of node: AttributeSyntax,
    attachedTo declaration: some DeclGroupSyntax,
    providingExtensionsOf type: some TypeSyntaxProtocol,
    conformingTo protocols: [TypeSyntax],
    in context: some MacroExpansionContext
  ) throws -> [ExtensionDeclSyntax] {
    return [
      try ExtensionDeclSyntax(
        """
        	extension \(type): AsPublisher {
        		public func asPublisher() -> any Publisher<T> {
        			return self.publisher
        		}
        	}
        """)
    ]
  }
}
