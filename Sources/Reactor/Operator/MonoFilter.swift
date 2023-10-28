import ReactiveStreams

public extension Mono {
	func filter(_ predicate: @escaping (T) throws -> Bool) -> Mono<T> {
		Mono<T>(publisher: FluxFilterPublisher(predicate, publisher))
	}
}
