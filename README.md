# Reactor Swift

Recreating [Project Reactor](https://projectreactor.io/) on Swift just for fun.

This project is a monorepo built with SPM with the following shared dependencies:

- ReactiveStreams
- Reactor
- ReactorMacros
- ReactorTests

**Not production ready**

## Get Started

Add the following dependencies to `Package.swift`:

```swift
dependencies: [
	.package(url: "https://github.com/ceopaludetto/reactor-swift", .upToNextMajor("0.0.1")),
],
targets: [
	.target(
		name: "MyPackage",
		dependencies: [
			"Reactor",
      .product(name: "ReactiveStreams", package: "Reactor"), // optional
		]
	),
	.testTarget(
		name: "MyPackageTests",
		dependencies: [
      .product(name: "ReactorTests", package: "Reactor"),
		]
	)
]
```

## Reactive Streams

This project heavily relies on [reactive-streams-jvm](https://github.com/reactive-streams/reactive-streams-jvm) specification. The main types are:

- `Publisher`
- `Subscriber`
- `Subscription`

## Current operators supported

See [OPERATORS.md](./OPERATORS.md)

## Differences to X

Some comparions between Reactor Swift and other reactive libraries.

### Reactor Java

Reactor Swift share a lot of similarities with Reactor Java, but there are some differences:

- Thread safe in Reactor Swift is guaranteed by usage of locks instead of Work In Progress or Work Stealing algorithms
- Reactor Java is way more mature and has a lot of operators
- Reactor Java has a lot of optimizations and performance improvements
- Due to language differences and a more strict type system in Swift, some validations are not needed:
  - It's impossible to provide a negative demand
  - It's impossible to provide a null subscriber
- Reactor Java has support to operator fuseable

### Combine

- Combine does not rely on reactive-streams-jvm specification
- Combine has a small subset of operators
- Combine is not open source or cross-platform (alternative: [OpenCombine](https://github.com/OpenCombine/OpenCombine))

### ReactiveX (RxSwift...)

- ReactiveX does not rely on reactive-streams-jvm specification
- ... (TODO)

## Contribute

- You'll need Swift 5.9+
- Clone this repo
- Run `swift build` to build the project
- Run `swift test` to run the tests

## Acknowledgements

- Thanks to this [awesome presentation](https://www.youtube.com/watch?v=OdSZ6mOQDcY) about reactive-streams specification by Oleh Dokuka(ReactorJava core mantainer).
- Thanks to OpenCombine for clearing the path to achieve thread safety models in Swift
- Thanks to Reactor Java for the awesome library and inspiration
