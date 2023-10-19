public enum ValidationError: Error {
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
	static func demand(_ demand: UInt) -> Result<UInt, Error> {
		if demand == 0 {
			return .failure(ValidationError.invalidDemand(demand))
		}

		return .success(demand)
	}
}
