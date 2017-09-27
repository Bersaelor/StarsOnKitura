// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "StarsOnKitura",
    products: [
        .executable(
            name: "StarsOnKitura",
            targets: ["StarsOnKitura"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/Bersaelor/KDTree", .upToNextMinor(from: "1.0.2")),
//        .package(url: "https://github.com/Bersaelor/SwiftyHYGDB", .upToNextMinor(from: "0.5.2")),
        .package(url: "../SwiftyHYGDB", .upToNextMinor(from: "0.6.0")),
        .package(url: "https://github.com/IBM-Swift/Kitura.git", .upToNextMinor(from: "1.7.8")),
        .package(url: "https://github.com/IBM-Swift/HeliumLogger.git", .upToNextMinor(from: "1.7.1")),
        .package(url: "https://github.com/IBM-Swift/Kitura-StencilTemplateEngine.git", .upToNextMinor(from: "1.8.3"))
    ],
    targets: [
        .target(
            name: "StarsOnKitura",
            dependencies: ["KDTree", "Kitura", "KituraStencil", "HeliumLogger", "SwiftyHYGDB"]
        )
    ]
)
