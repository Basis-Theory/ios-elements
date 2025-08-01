// swift-tools-version: 5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BasisTheoryElements",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "BasisTheoryElements",
            targets: ["BasisTheoryElements"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
         .package(url: "https://github.com/Basis-Theory/basistheory-swift", .exact("0.7.0")),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "BasisTheoryElements",
            dependencies: [
                .product(name: "BasisTheory", package: "basistheory-swift"),
            ],
            resources: [.process("Resources")]
        )
    ]
)
