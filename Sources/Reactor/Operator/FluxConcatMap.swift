import ReactiveStreams

extension Flux {
  public func concatMap<R>(_ mapper: @escaping (T) throws -> any Publisher<R>) -> Flux<R> {
    // ConcatMap is a special case of flatMap which has maxConcurrency of 1
    // see: https://github.com/spring-attic/reactive-streams-commons/issues/21#issuecomment-210178344
    return Flux<R>(publisher: FlatMapPublisher(mapper, publisher, 1))
  }

  public func concatMap<R, C: AsPublisher<R>>(_ mapper: @escaping (T) throws -> C) -> Flux<R> {
    return concatMap({ try mapper($0).asPublisher() })
  }
}
