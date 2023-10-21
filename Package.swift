// swift-tools-version: 5.9

import CompilerPluginSupport
import PackageDescription

let package = Package(
	name: "Reactor",
	platforms: [
		.macOS(.v13),
	],
	products: [
		.library(name: "ReactiveStreams", targets: ["ReactiveStreams"]),
		.library(name: "Reactor", targets: ["Reactor"]),
		.library(name: "ReactorTest", targets: ["ReactorTest"]),
	],
	dependencies: [
		.package(url: "https://github.com/apple/swift-log.git", .upToNextMajor(from: "1.5.3")),
		.package(url: "https://github.com/pointfreeco/swift-macro-testing", .upToNextMajor(from: "0.2.1")),
		.package(url: "https://github.com/apple/swift-testing.git", branch: "main"),
		.package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0"),
	],
	targets: [
		.target(name: "COpenCombineHelpers"),
		.target(name: "ReactiveStreams"),

		.macro(
			name: "ReactorMacros",
			dependencies: [
				.product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
				.product(name: "SwiftSyntax", package: "swift-syntax"),
				.product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
				.product(name: "SwiftDiagnostics", package: "swift-syntax"),
			]
		),
		.target(
			name: "Reactor",
			dependencies: [
				"ReactiveStreams",
				"ReactorMacros",
				"COpenCombineHelpers",
				.product(name: "Logging", package: "swift-log"),
			]
		),
		.target(
			name: "ReactorTest",
			dependencies: [
				"ReactiveStreams",
				"Reactor",
				.product(name: "Testing", package: "swift-testing"),
			]
		),

		.testTarget(
			name: "ReactorTests",
			dependencies: [
				"Reactor",
				.product(name: "Testing", package: "swift-testing"),
			]
		),
		.testTarget(
			name: "ReactorMacrosTests",
			dependencies: [
				"ReactorMacros",
				.product(name: "Testing", package: "swift-testing"),
				.product(name: "MacroTesting", package: "swift-macro-testing"),
			]
		),
	],
	cxxLanguageStandard: .cxx17
)
