import Foundation

extension Optional where Wrapped == TimeInterval {
  func toDispatchTime() -> DispatchTime {
    if let interval = self {
      return .now() + interval
    }

    return .distantFuture
  }
}
