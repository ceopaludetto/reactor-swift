import ReactiveStreams

internal class EmptySubscription: Subscription {
  func request(_ demand: UInt) {}
  func cancel() {}
}
