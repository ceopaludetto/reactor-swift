import Foundation

extension TimeInterval? {
	func toDispatchTime() -> DispatchTime {
		if let interval = self {
			return .now() + interval
		}

		return .distantFuture
	}
}
