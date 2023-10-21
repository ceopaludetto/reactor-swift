func runCatching(_ onError: (Error) -> Void, _ closure: () throws -> Void) {
	do {
		try closure()
	} catch {
		onError(error)
	}
}
