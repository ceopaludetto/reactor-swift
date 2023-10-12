import Atomics

enum ValidationError: Error {
  case invalidDemand(UInt)
}

extension ValidationError: CustomStringConvertible {
  var description: String {
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

  static func addCap(_ demand: UInt, _ requested: ManagedAtomic<UInt>) -> UInt? {
    var new = demand
    var initialRequested: UInt

    repeat {
      initialRequested = requested.load(ordering: .relaxed)

      if initialRequested == .max {
        return nil
      }

      new &+= initialRequested

      if new <= 0 {
        new = .max
      }
    } while !requested.weakCompareExchange(
      expected: initialRequested, desired: new, ordering: .relaxed
    ).exchanged

    if initialRequested > 0 {
      return nil
    }

    return new
  }
}
