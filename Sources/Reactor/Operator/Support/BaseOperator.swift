import ReactiveStreams

enum TryLockType {
	case next, terminal
	case subscription(Subscription)
}

open class BaseOperator {
	var lock: UnfairLock = .allocate()
	var done: Bool = false

	var subscription: (any Subscription)?

	deinit {
		lock.deallocate()
	}
}

extension BaseOperator {
	func tryLock(_ type: TryLockType, _ closure: @escaping () -> Void) {
		if case let .subscription(subscription) = type {
			self.tryLockSubscription(subscription, closure)
			return
		}

		self.tryLockBase(type, closure)
	}

	private func tryLockBase(_ type: TryLockType, _ closure: @escaping () -> Void) {
		self.lock.lock()

		guard !self.done else {
			self.lock.unlock()

			return
		}

		if case .terminal = type {
			self.done = true
		}

		self.lock.unlock()

		closure()
	}

	private func tryLockSubscription(_ subscription: any Subscription, _ closure: @escaping () -> Void) {
		self.lock.lock()

		guard self.subscription == nil, !self.done else {
			self.lock.unlock()
			self.subscription?.cancel()

			return
		}

		self.subscription = subscription
		self.lock.unlock()

		closure()
	}
}
