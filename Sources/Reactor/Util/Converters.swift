// MARK: Mono

public extension Optional {
	func toMono() -> Mono<Wrapped> {
		Mono.fromOptional(self)
	}
}

public extension Result {
	func toMono() -> Mono<Success> {
		Mono.fromResult(self)
	}
}

public extension Error {
	func toMono<T>() -> Mono<T> {
		Mono.error(self)
	}
}

public extension Int {
	func toMono() -> Mono<Int> {
		Mono.just(self)
	}
}

public extension UInt {
	func toMono() -> Mono<UInt> {
		Mono.just(self)
	}
}

// TODO: add Int8, Int16, Int32, Int64, UInt8, UInt16, UInt32, UInt64

// MARK: Flux

public extension Sequence {
	func toFlux() -> Flux<Element> {
		Flux.just(self)
	}
}
