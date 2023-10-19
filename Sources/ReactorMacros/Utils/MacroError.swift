enum MacroError: Error {
  case invalidArgumentCount(_ current: Int, _ expected: Int)
}

extension MacroError: CustomStringConvertible {
  var description: String {
    switch self {
    case .invalidArgumentCount(let current, let expected):
      return "Invalid macro argument count, expected: \(expected), received: \(current)"
    }
  }
}
