import Foundation
import ReactiveStreams

class ScalarSubscription<T>: Subscription {
	private var actual: any Subscriber<T>
	private let item: T

	private let lock: NSLock = .init()
	private var cancelled: Bool = false

	init(subscriber: any Subscriber<T>, item: T) {
		self.actual = subscriber
		self.item = item
	}

	func request(_ demand: UInt) {
		#validateDemand(demand, self.cancel, self.actual.onError)

		self.lock.lock()
		defer { lock.unlock() }

		self.actual.onNext(self.item)
		self.actual.onComplete()

		self.cancelled = true
	}

	func cancel() {
		self.lock.lock()
		defer { lock.unlock() }

		self.cancelled = true
	}
}
