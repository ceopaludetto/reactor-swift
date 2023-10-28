import ReactiveStreams

public extension Mono {
	func map<R>(_ mapper: @escaping (T) throws -> R) -> Mono<R> {
		Mono<R>(publisher: FluxMapPublisher(mapper, publisher))
	}
}
