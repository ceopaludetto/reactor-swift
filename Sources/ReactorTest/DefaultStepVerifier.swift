import ReactiveStreams

public struct DefaultStepVerifier<T>: StepVerifier {
	public typealias Item = T

	private let publisher: any Publisher<T>

	public init(_ publisher: any Publisher<T>) {
		self.publisher = publisher
	}

	public func assertNext(_: @escaping (T) -> Void) -> Self {
		self
	}

	public func expectSubscription() -> Self {
		self
	}

	public func expectNext(_: T) -> Self {
		self
	}

	public func expectNext(_: T...) -> Self {
		self
	}

	public func expectError(_: Error) -> Self {
		self
	}

	public func expectComplete() -> Self {
		self
	}

	public func verifyError() {}

	public func verifyError(_: Error) {}

	public func verifyComplete() {}
}
