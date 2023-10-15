// MARK: Mono

extension Optional {
  public func toMono() -> Mono<Wrapped> {
    return Mono.fromOptional(self)
  }
}

extension Result {
  public func toMono() -> Mono<Success> {
    return Mono.fromResult(self)
  }
}

extension Error {
  public func toMono<T>() -> Mono<T> {
    return Mono.error(self)
  }
}

extension Int {
  public func toMono() -> Mono<Int> {
    return Mono.just(self)
  }
}

extension UInt {
  public func toMono() -> Mono<UInt> {
    return Mono.just(self)
  }
}

// TODO: add Int8, Int16, Int32, Int64, UInt8, UInt16, UInt32, UInt64

// MARK: Flux

extension Sequence {
  public func toFlux() -> Flux<Element> {
    return Flux.just(self)
  }
}
