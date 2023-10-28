import ReactiveStreams

struct FluxPeekCallbacks<T> {
	let onSubscribe: ((Subscription) throws -> Void)?
	let onNext: ((T) throws -> Void)?
	let onComplete: (() throws -> Void)?
	let onError: ((Error) throws -> Void)?
	let onAfterTerminate: (() throws -> Void)?
	let onRequest: ((UInt) throws -> Void)?
	let onCancel: (() throws -> Void)?

	init(
		onSubscribe: ((Subscription) throws -> Void)? = nil,
		onNext: ((T) throws -> Void)? = nil,
		onComplete: (() throws -> Void)? = nil,
		onError: ((Error) throws -> Void)? = nil,
		onAfterTerminate: (() throws -> Void)? = nil,
		onRequest: ((UInt) throws -> Void)? = nil,
		onCancel: (() throws -> Void)? = nil
	) {
		self.onSubscribe = onSubscribe
		self.onNext = onNext
		self.onComplete = onComplete
		self.onError = onError
		self.onAfterTerminate = onAfterTerminate
		self.onRequest = onRequest
		self.onCancel = onCancel
	}
}

final class FluxPeekPublisher<T>: Publisher {
	typealias Item = T

	private let callbacks: FluxPeekCallbacks<T>
	private let source: any Publisher<T>

	init(
		_ callbacks: FluxPeekCallbacks<T>,
		_ source: some Publisher<T>
	) {
		self.callbacks = callbacks
		self.source = source
	}

	func subscribe(_ subscriber: some Subscriber<Item>) {
		self.source.subscribe(FluxPeekOperator(self.callbacks, subscriber))
	}
}

final class FluxPeekOperator<T>: BaseOperator, Subscriber, Subscription {
	typealias Item = T

	private let actual: any Subscriber<T>

	private let callbacks: FluxPeekCallbacks<T>

	init(
		_ callbacks: FluxPeekCallbacks<T>,
		_ actual: some Subscriber<T>
	) {
		self.callbacks = callbacks
		self.actual = actual
	}

	func onSubscribe(_ subscription: some Subscription) {
		self.tryLock(.subscription(subscription)) {
			self.actual.onSubscribe(self)
			runCatching(self.onError) { try self.callbacks.onSubscribe?(subscription) }
		}
	}

	func onNext(_ element: T) {
		self.tryLock(.next) {
			self.actual.onNext(element)
			runCatching(self.onError) { try self.callbacks.onNext?(element) }
		}
	}

	func onError(_ error: Error) {
		self.tryLock(.terminal) {
			self.actual.onError(error)

			runCatching(self.onError) {
				try self.callbacks.onError?(error)
				try self.callbacks.onAfterTerminate?()
			}
		}
	}

	func onComplete() {
		self.tryLock(.terminal) {
			self.actual.onComplete()

			runCatching(self.onError) {
				try self.callbacks.onComplete?()
				try self.callbacks.onAfterTerminate?()
			}
		}
	}

	func request(_ demand: UInt) {
		self.subscription?.request(demand)
		runCatching(self.onError) { try self.callbacks.onRequest?(demand) }
	}

	func cancel() {
		self.subscription?.cancel()
		runCatching(self.onError) { try self.callbacks.onCancel?() }
	}
}

public extension Flux {
	func doOnSubscribe(_ onSubscribe: @escaping (Subscription) throws -> Void) -> Flux<T> {
		Flux(publisher: FluxPeekPublisher(.init(onSubscribe: onSubscribe), publisher))
	}

	func doOnNext(_ onNext: @escaping (T) throws -> Void) -> Flux<T> {
		Flux(publisher: FluxPeekPublisher(.init(onNext: onNext), publisher))
	}

	func doOnComplete(_ onComplete: @escaping () throws -> Void) -> Flux<T> {
		Flux(publisher: FluxPeekPublisher(.init(onComplete: onComplete), publisher))
	}

	func doOnError(_ onError: @escaping (Error) throws -> Void) -> Flux<T> {
		Flux(publisher: FluxPeekPublisher(.init(onError: onError), publisher))
	}

	func doOnTerminate(_ onTerminate: @escaping () throws -> Void) -> Flux<T> {
		Flux(publisher: FluxPeekPublisher(.init(onComplete: onTerminate, onError: { _ in try onTerminate() }), publisher))
	}

	func doAfterTerminate(_ onAfterTerminate: @escaping () throws -> Void) -> Flux<T> {
		Flux(publisher: FluxPeekPublisher(.init(onAfterTerminate: onAfterTerminate), publisher))
	}

	func doOnRequest(_ onRequest: @escaping (UInt) throws -> Void) -> Flux<T> {
		Flux(publisher: FluxPeekPublisher(.init(onRequest: onRequest), publisher))
	}

	func doOnCancel(_ onCancel: @escaping () throws -> Void) -> Flux<T> {
		Flux(publisher: FluxPeekPublisher(.init(onCancel: onCancel), publisher))
	}
}
