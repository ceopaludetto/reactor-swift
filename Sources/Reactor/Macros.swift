import Foundation
import ReactiveStreams

enum GuardLockType {
	case next, terminal
}

@freestanding(declaration)
macro validateDemand(_ demand: UInt, _ cancel: () -> Void, _ onError: ((Error) -> Void)?) =
	#externalMacro(module: "ReactorMacros", type: "ValidateDemandMacro")

@freestanding(declaration)
macro guardLock(_ lock: NSLock, _ done: Bool, _ type: GuardLockType) =
	#externalMacro(module: "ReactorMacros", type: "GuardLockMacro")

@attached(extension, conformances: AsPublisher, names: named(asPublisher))
@attached(member, names: named(init), named(publisher))
public macro ReactivePublisher() =
	#externalMacro(module: "ReactorMacros", type: "ReactivePublisherMacro")
