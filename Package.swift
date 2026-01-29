// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FlowState",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "FlowState",
            exclude: ["Info.plist"]
        )
    ]
)
