import Foundation
import Testing

func eventually(_ assertion: @autoclosure () -> Bool, timeout: TimeInterval = 1.0, message: Comment? = nil) {
	let runLoop = RunLoop.current
	let timeoutDate = Date(timeIntervalSinceNow: timeout)

	repeat {
		if assertion() {
			return
		}

		runLoop.run(until: Date(timeIntervalSinceNow: 0.01))
	} while Date().compare(timeoutDate) == .orderedAscending

	// Trying to suppress a warning here with Bool(false)
	#expect(Bool(false), message ?? "Assertion failed after \(timeout) seconds")
}
