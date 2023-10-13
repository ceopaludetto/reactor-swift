// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Reactor",
  platforms: [
    .macOS(.v13)
  ],
  products: [
    // Products define the executables and libraries a package produces, making them visible to other packages.
    .library(name: "ReactiveStreams", targets: ["ReactiveStreams"]),
    .library(name: "Reactor", targets: ["Reactor"]),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-log.git", .upToNextMajor(from: "1.5.3")),
    .package(url: "https://github.com/apple/swift-atomics.git", .upToNextMajor(from: "1.2.0")),
    .package(url: "https://github.com/Quick/Quick.git", .upToNextMajor(from: "7.0.0")),
    .package(url: "https://github.com/Quick/Nimble.git", .upToNextMajor(from: "12.0.0"))
  ],
  targets: [
    // Targets are the basic building blocks of a package, defining a module or a test suite.
    // Targets can depend on other targets in this package and products from dependencies.
    .target(name: "ReactiveStreams"),
    .target(
      name: "Reactor",
      dependencies: ["ReactiveStreams", .product(name: "Atomics", package: "swift-atomics")]
    ),
    .target(
      name: "TCK",
      dependencies: [
        "ReactiveStreams",
        "Quick",
        "Nimble",
      	.product(name: "Logging", package: "swift-log"),
 			]
		),
    .testTarget(name: "ReactorTests", dependencies: ["TCK", "Reactor", "Quick", "Nimble"]),
  ]
)
