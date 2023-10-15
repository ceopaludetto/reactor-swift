extension Mono {
  public static func fromOptional(_ item: T?) -> Mono<T> {
    if case .some(let item) = item {
      return Mono.just(item)
    }

    return Mono.empty()
  }
}
