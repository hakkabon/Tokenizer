// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Tokenizer",
    products: [
        .library(name: "Tokenizer", targets: ["Tokenizer"]),
        .executable(name: "tok", targets: ["tok"]),
    ],
    dependencies: [
        .package(name: "Files", url: "https://github.com/johnsundell/files.git", from: "2.2.1"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "0.3.0"),
    ],
    targets: [
        .target(name: "Tokenizer", dependencies: ["Files"]),
        .target(
            name: "tok",
            dependencies: [
                "Tokenizer",
                "Files",
                .product(name: "ArgumentParser", package: "swift-argument-parser")]),
        .testTarget(name: "TokenizerTests", dependencies: ["Tokenizer"]),
    ]
)
