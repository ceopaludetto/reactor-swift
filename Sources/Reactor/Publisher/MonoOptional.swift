public extension Mono {
	static func fromOptional(_ item: T?) -> Mono<T> {
		if case let .some(item) = item {
			return Mono.just(item)
		}

		return Mono.empty()
	}
}
