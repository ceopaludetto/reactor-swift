import ReactiveStreams

enum GuardLockType {
	case next, terminal
}

@attached(extension, conformances: PublisherConvertible, names: named(toPublisher))
@attached(member, names: named(init), named(publisher))
public macro ReactivePublisher() =
	#externalMacro(module: "ReactorMacros", type: "ReactivePublisherMacro")
