// swift-tools-version:3.1

import PackageDescription

let package = Package(
    name: "StarsOnKitura",
    dependencies: [
        .Package(url: "https://github.com/Bersaelor/KDTree", majorVersion: 0, minor: 5),
        .Package(url: "https://github.com/IBM-Swift/Kitura.git", majorVersion: 1, minor: 7),
        .Package(url: "https://github.com/IBM-Swift/HeliumLogger.git", majorVersion: 1, minor: 7),
        .Package(url: "https://github.com/IBM-Swift/Kitura-StencilTemplateEngine.git", majorVersion: 1, minor: 8)
    ]
)
