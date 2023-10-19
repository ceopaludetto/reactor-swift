import ReactiveStreams

extension Mono {
  public static func fromResult<E: Error>(_ result: Result<T, E>) -> Mono<T> {
    switch result {
    case .success(let value):
      return Mono.just(value)
    case .failure(let error):
      return Mono.error(error)
    }
  }
}
