import ReactiveStreams

public extension Mono {
	static func fromResult(_ result: Result<T, some Error>) -> Mono<T> {
		switch result {
		case let .success(value):
			Mono.just(value)
		case let .failure(error):
			Mono.error(error)
		}
	}
}
