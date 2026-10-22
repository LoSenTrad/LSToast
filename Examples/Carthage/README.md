# Carthage consumer demo

From the repository root run `carthage bootstrap --use-xcframeworks --platform iOS --no-use-binaries`, then `carthage build --no-skip-current --use-xcframeworks --platform iOS --no-use-binaries`. Open `LSToastDemo.xcodeproj` in this directory. It links and embeds both XCFrameworks from the root `Carthage/Build` directory. Demo app sources and hosted tests are shared with the main SPM demo; no Swift package is added to this consumer target.
