// swift-tools-version: 5.9

import CompilerPluginSupport
import PackageDescription

let package = Package(
  name: "Reactor",
  platforms: [
    .macOS(.v13)
  ],
  products: [
    .library(name: "ReactiveStreams", targets: ["ReactiveStreams"]),
    .library(name: "Reactor", targets: ["Reactor"]),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-log.git", .upToNextMajor(from: "1.5.3")),
    .package(url: "https://github.com/Quick/Quick.git", .upToNextMajor(from: "7.0.0")),
    .package(url: "https://github.com/Quick/Nimble.git", .upToNextMajor(from: "12.0.0")),
    .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0"),
  ],
  targets: [
    .target(name: "ReactiveStreams"),
    .target(
      name: "TCK",
      dependencies: [
        "ReactiveStreams",
        "Quick",
        "Nimble",
        .product(name: "Logging", package: "swift-log"),
      ]
    ),

    .macro(
      name: "ReactorMacros",
      dependencies: [
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
        .product(name: "SwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
        .product(name: "SwiftDiagnostics", package: "swift-syntax"),
      ]
    ),
    .target(name: "Reactor", dependencies: ["ReactiveStreams", "ReactorMacros"]),

    .testTarget(
      name: "ReactorTests",
      dependencies: [
        "ReactorMacros",
        "TCK",
        "Reactor",
        "Quick",
        "Nimble",
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
        .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
      ]
    ),
  ]
)
