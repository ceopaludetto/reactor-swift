public enum ValidationError: Error {
  case invalidDemand(UInt)
}

extension ValidationError: CustomStringConvertible {
  public var description: String {
    switch self {
    case .invalidDemand(let demand):
      return "Invalid demand \(demand), must be greater than 0"
    }
  }
}

internal struct Validator {
  static func demand(_ demand: UInt) -> Result<UInt, Error> {
    if demand == 0 {
      return .failure(ValidationError.invalidDemand(demand))
    }

    return .success(demand)
  }
}
