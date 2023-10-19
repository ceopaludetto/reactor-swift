import Quick
import ReactorMacros
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

class GuardLockMacroTest: QuickSpec {
  override class func spec() {
    it("should expand guardLock in .terminal mode") {
      assertMacroExpansion(
        """
        #guardLock(lock, done, .terminal)
        """,
        expandedSource:
          """
          lock.lock()
          guard !done else {
            lock.unlock()
            return
          }

          done.toggle()
          lock.unlock()
          """,
        macros: ["guardLock": GuardLockMacro.self],
        indentationWidth: .spaces(2)
      )
    }

    it("should expand guardLock in .next mode") {
      assertMacroExpansion(
        """
        #guardLock(lock, done, .next)
        """,
        expandedSource:
          """
          lock.lock()
          guard !done else {
            lock.unlock()
            return
          }

          lock.unlock()
          """,
        macros: ["guardLock": GuardLockMacro.self],
        indentationWidth: .spaces(2)
      )
    }
  }
}
