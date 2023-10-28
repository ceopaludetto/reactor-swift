import ReactiveStreams
import Testing

@testable import Reactor

struct FluxJustAsyncTest {
	@Test
	func shouldAwaitListOfElements() async throws {
		let items = try await Flux.just(1...)
			.take(100)
			.awaitList()

		#expect(items.count == 100)
		#expect(items == Array(1 ... 100))
	}

	@Test
	func battleTest() async throws {
		let items = try await Flux.just(1...)
			.take(1000)
			.takeWhile { _ in true }
			.takeUntil { _ in false }
			.filter { _ in true }
			.index()
			.map { $1 }
			.flatMap { Mono.just($0) }
			.concatMap { Mono.just($0) }
			.awaitList()

		#expect(items.count == 1000)
		#expect(items == Array(1 ... 1000))
	}
}
