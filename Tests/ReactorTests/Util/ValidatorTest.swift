import Testing

@testable import Reactor

struct ValidatorTest {
	@Test
	func shouldReturnFailureWhenDemandIs0() {
		#expect(Validator.demand(0) == .failure(.invalidDemand(0)))
	}

	@Test
	func shouldReturnSuccessWhenDemandIsGreaterThan0() {
		#expect(Validator.demand(1) == .success(1))
	}
}
