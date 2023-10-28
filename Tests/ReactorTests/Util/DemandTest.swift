import Testing

@testable import Reactor

struct DemandTest {
	@Test
	func shouldReturnCorrectSumWhenAddingTwoDemands() {
		#expect(1 ~+ 1 == 2)
	}

	@Test
	func shouldReturnMaxWhenOverflowAddingTwoDemands() {
		#expect(1 ~+ .max == .max)
		#expect(.max ~+ .max == .max)
	}

	@Test
	func shouldReturnCorrectSumWhenModifyingDemand() {
		var demand: UInt = 1
		demand ~+= 1

		#expect(demand == 2)
	}

	@Test
	func shouldReturnMaxWhenOverflowModifyingDemand() {
		var demand: UInt = 1
		demand ~+= .max

		#expect(demand == .max)

		demand ~+= .max
		#expect(demand == .max)
	}
}
