infix operator ~+ : AdditionPrecedence
infix operator ~+= : AdditionPrecedence

extension UInt {
  internal static func ~+ (lhs: UInt, rhs: UInt) -> UInt {
    let (result, overflowed) = lhs.addingReportingOverflow(rhs)
    return overflowed ? .max : result
  }

  internal static func ~+= (lhs: inout UInt, rhs: UInt) {
    lhs = lhs ~+ rhs
  }
}
