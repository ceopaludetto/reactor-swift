import Foundation

class ConditionalVariable<T> {
	public var value: T?
	private let group: DispatchGroup = .init()

	func dispatch(_ value: T) {
		self.group.enter()

		DispatchQueue.global().sync {
			self.value = value
			self.group.leave()
		}
	}

	func waitForValue(_ timeout: TimeInterval? = nil) -> T? {
		if case .timedOut = self.group.wait(timeout: timeout.toDispatchTime()) {
			return nil
		}

		return self.value
	}
}
