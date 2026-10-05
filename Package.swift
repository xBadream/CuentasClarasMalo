// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CuentasClaras",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "CuentasClaras",
            targets: ["CuentasClaras"]
        )
    ],
    targets: [
        .executableTarget(
            name: "CuentasClaras",
            path: "Sources/CuentasClaras"
        ),
        .testTarget(
            name: "CuentasClarasTests",
            dependencies: ["CuentasClaras"],
            path: "Tests/CuentasClarasTests"
        )
    ]
)
