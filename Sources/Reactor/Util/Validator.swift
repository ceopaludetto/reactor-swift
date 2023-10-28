public enum ValidationError: Error, Equatable {
	case invalidDemand(UInt)
}

extension ValidationError: CustomStringConvertible {
	public var description: String {
		switch self {
		case let .invalidDemand(demand):
			"Invalid demand \(demand), must be greater than 0"
		}
	}
}

enum Validator {
	static func demand(_ demand: UInt) -> Result<UInt, ValidationError> {
		if demand == 0 {
			return .failure(.invalidDemand(demand))
		}

		return .success(demand)
	}
}
