// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "LSToast",
    platforms: [.iOS(.v15)],
    products: [.library(name: "LSToast", type: .static, targets: ["LSToast"])],
    dependencies: [
        .package(url: "https://github.com/LoSenTrad/LSTPopView.git", exact: "1.0.0-lstoast.1")
    ],
    targets: [
        .target(name: "LSToast", dependencies: [.product(name: "LSTPopViewSwift", package: "LSTPopView")])
    ],
    swiftLanguageModes: [.v5]
)
