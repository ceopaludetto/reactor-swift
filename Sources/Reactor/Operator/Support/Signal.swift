import ReactiveStreams

enum Signal<T> {
	case subscribe(Subscription)
	case next(T)
	case error(Error)
	case complete
}
