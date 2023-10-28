public extension Mono {
	static func justOrEmpty(_ item: T?) -> Mono<T> {
		if case let .some(item) = item {
			return Mono.just(item)
		}

		return Mono.empty()
	}
}
