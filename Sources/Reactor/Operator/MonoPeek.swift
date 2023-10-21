import ReactiveStreams

public extension Mono {
	func doOnSubscribe(_ onSubscribe: @escaping (Subscription) throws -> Void) -> Mono<T> {
		Mono(publisher: FluxPeekPublisher(.init(onSubscribe: onSubscribe), publisher))
	}

	func doOnNext(_ onNext: @escaping (T) throws -> Void) -> Mono<T> {
		Mono(publisher: FluxPeekPublisher(.init(onNext: onNext), publisher))
	}

	func doOnSuccess(_ onSuccess: @escaping () throws -> Void) -> Mono<T> {
		Mono(publisher: FluxPeekPublisher(.init(onComplete: onSuccess), publisher))
	}

	func doOnError(_ onError: @escaping (Error) throws -> Void) -> Mono<T> {
		Mono(publisher: FluxPeekPublisher(.init(onError: onError), publisher))
	}

	func doOnTerminate(_ onTerminate: @escaping () throws -> Void) -> Mono<T> {
		Mono(publisher: FluxPeekPublisher(.init(onComplete: onTerminate, onError: { _ in try onTerminate() }), publisher))
	}

	func doAfterTerminate(_ onAfterTerminate: @escaping () throws -> Void) -> Mono<T> {
		Mono(publisher: FluxPeekPublisher(.init(onAfterTerminate: onAfterTerminate), publisher))
	}

	func doOnRequest(_ onRequest: @escaping (UInt) throws -> Void) -> Mono<T> {
		Mono(publisher: FluxPeekPublisher(.init(onRequest: onRequest), publisher))
	}

	func doOnCancel(_ onCancel: @escaping () throws -> Void) -> Mono<T> {
		Mono(publisher: FluxPeekPublisher(.init(onCancel: onCancel), publisher))
	}
}
