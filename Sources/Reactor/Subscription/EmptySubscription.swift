import ReactiveStreams

class EmptySubscription: Subscription {
	func request(_: UInt) {}
	func cancel() {}
}
