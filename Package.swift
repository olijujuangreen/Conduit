// swift-tools-version: 6.3
//
//  Package.swift
//  Conduit
//
//  Created by Olijujuan Green on 4/23/26.
//

import PackageDescription

let package = Package(
    name: "Networking",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v15),
        .watchOS(.v8),
        .visionOS(.v1),
    ],
    products: [
        .library(
            name: "Networking",
            targets: ["Networking"]
        ),
        .library(
            name: "NetworkingTesting",
            targets: ["NetworkingTesting"]
        ),
    ],
    targets: [
        .target(
            name: "Networking"
        ),
        .target(
            name: "NetworkingTesting",
            dependencies: ["Networking"]
        ),
        .testTarget(
            name: "NetworkingTests",
            dependencies: [
                "Networking",
                "NetworkingTesting",
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
