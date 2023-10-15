@freestanding(declaration)
internal macro validateDemand(_ demand: UInt, _ cancel: () -> Void, _ onError: (Error) -> Void) =
  #externalMacro(module: "ReactorMacros", type: "ValidateDemandMacro")
