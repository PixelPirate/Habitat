// swift-tools-version:3.1

import PackageDescription

let package = Package(
    name: "Habitat",
    dependencies: [
        .Package(url: "https://github.com/vapor/vapor.git", majorVersion: 2),
        .Package(url: "https://github.com/PixelPirate/Git2Swift.git", majorVersion: 0),
        .Package(url: "https://github.com/vapor/leaf-provider.git", majorVersion: 1)
    ]
)
