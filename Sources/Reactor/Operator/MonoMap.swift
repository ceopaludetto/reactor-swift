import ReactiveStreams

extension Mono {
  func map<R>(_ mapper: @escaping (T) throws -> R) -> Mono<R> {
    return Mono<R>(publisher: FluxMapPublisher(mapper, self.publisher))
  }
}
