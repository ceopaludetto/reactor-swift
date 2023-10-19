infix operator ~+: AdditionPrecedence
infix operator ~+=: AdditionPrecedence

extension UInt {
	static func ~+ (lhs: UInt, rhs: UInt) -> UInt {
		let (result, overflowed) = lhs.addingReportingOverflow(rhs)
		return overflowed ? .max : result
	}

	static func ~+= (lhs: inout UInt, rhs: UInt) {
		lhs = lhs ~+ rhs
	}
}
