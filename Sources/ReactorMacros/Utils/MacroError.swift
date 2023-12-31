enum MacroError: Error {
	case invalidArgumentCount(_ current: Int, _ expected: Int)
}

extension MacroError: CustomStringConvertible {
	var description: String {
		switch self {
		case let .invalidArgumentCount(current, expected):
			"Invalid macro argument count, expected: \(expected), received: \(current)"
		}
	}
}
