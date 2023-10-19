public protocol Subscription: AnyObject {
	func request(_ demand: UInt)
	func cancel()
}
