import ReactiveStreams

public extension Flux {
	func concatMap<R>(_ mapper: @escaping (T) throws -> any Publisher<R>) -> Flux<R> {
		// ConcatMap is a special case of flatMap which has maxConcurrency of 1
		// see: https://github.com/spring-attic/reactive-streams-commons/issues/21#issuecomment-210178344
		Flux<R>(publisher: FlatMapPublisher(mapper, publisher, 1))
	}

	func concatMap<R>(_ mapper: @escaping (T) throws -> some AsPublisher<R>) -> Flux<R> {
		self.concatMap { try mapper($0).asPublisher() }
	}
}
