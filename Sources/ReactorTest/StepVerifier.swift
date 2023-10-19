import Reactor

public protocol StepVerifier<Item> {
	associatedtype Item

	func assertNext(_ item: @escaping (Item) -> Void) -> Self

	func expectSubscription() -> Self
	func expectNext(_ item: Item) -> Self
	func expectNext(_ items: Item...) -> Self
	func expectError(_ error: Error) -> Self
	func expectComplete() -> Self

	func verifyError()
	func verifyError(_ error: Error)
	func verifyComplete()
}

public extension Flux {
	func test() -> some StepVerifier<T> {
		DefaultStepVerifier(self.asPublisher())
	}
}

public extension Mono {
	func test() -> some StepVerifier<T> {
		DefaultStepVerifier(self.asPublisher())
	}
}
