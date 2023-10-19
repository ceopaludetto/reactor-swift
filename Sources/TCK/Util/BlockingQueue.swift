import Foundation

class BlockingQueue<T> {
	private var array: [T] = []
	private var group: DispatchGroup = .init()

	func add(_ element: T) {
		self.group.enter()

		DispatchQueue.global().sync {
			self.array.append(element)
			self.group.leave()
		}
	}

	func take(_ timeout: TimeInterval? = nil) -> T? {
		if case .timedOut = self.group.wait(timeout: timeout.toDispatchTime()) {
			return nil
		}

		if self.array.isEmpty {
			return nil
		}

		return self.array.removeFirst()
	}

	func takeAll(_ timeout: TimeInterval? = nil) -> [T] {
		if case .timedOut = self.group.wait(timeout: timeout.toDispatchTime()) {
			return []
		}

		var elements: [T] = []
		while !self.array.isEmpty {
			elements.append(self.array.removeFirst())
		}

		return elements
	}
}
