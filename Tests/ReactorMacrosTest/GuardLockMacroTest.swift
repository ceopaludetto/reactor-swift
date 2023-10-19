import MacroTesting
import Quick
import XCTest

@testable import ReactorMacros

class GuardLockMacroTest: QuickSpec {
	override class func spec() {
		it("should expand guardLock in .terminal mode") {
			assertMacro(["guardLock": GuardLockMacro.self]) {
				"""
				#guardLock(lock, done, .terminal)
				"""
			} expansion: {
				"""
				lock.lock()
				guard !done else {
					lock.unlock()
					return
				}

				done.toggle()
				lock.unlock()
				"""
			}
		}

		it("should expand guardLock in .next mode") {
			assertMacro(["guardLock": GuardLockMacro.self]) {
				"""
				#guardLock(lock, done, .next)
				"""
			} expansion: {
				"""
				lock.lock()
				guard !done else {
					lock.unlock()
					return
				}


				lock.unlock()
				"""
			}
		}
	}
}
