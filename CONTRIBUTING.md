# Contributing to LSToast

欢迎提交可复现的问题和小范围改进。问题描述请包含安装方式、LSToast 与弹窗依赖版本、Xcode / Swift / iOS 版本、最小复现代码，以及预期和实际行为。不要上传真实用户数据、凭证或整份 App 私有日志。

## Local development

1. Clone the repository and open `Examples/LSToastDemo/LSToastDemo.xcodeproj`.
2. Use Xcode 26 / Swift 6.2 or newer with an available iOS 16+ iPhone simulator. The demo uses the local Swift package and automatically resolves the upstream popup package.
3. Run `./scripts/test-demo.sh`. To choose a simulator, pass `SIMULATOR_UDID`; to choose an independent output folder, pass `OUTPUT_DIR`.
4. Run `python3 scripts/check-docs.py` and `git diff --check` for documentation or packaging changes.
5. For CocoaPods integration changes, also run `XCODE_XCCONFIG_FILE="$PWD/Tools/iOS15.xcconfig" pod lib lint LSToast.podspec --platforms=ios --verbose`. The checked-in xcconfig raises legacy dependency targets to the supported iOS 15 floor without changing upstream source or versions. Keep lint strict and investigate its actual errors or warnings; do not add `--allow-warnings` to hide an unresolved failure. This is validation, not Trunk publication.

## Scope and compatibility

- Keep the `LSToast` API consistent across the Objective-C CocoaPods backend and native Swift SPM / Carthage backend.
- Never hide or replace business popups by calling a global removal API from toast code.
- Keep all UI state on `MainActor`, all touch regions transparent to interaction, and all saved popup handles weak where the API promises weak ownership.
- Preserve per-window state. Do not use a global singleton toast instance that crosses scene ownership.
- Test replacements while the old toast is appearing or dismissing. Old handles, callbacks, and timers must not affect a newer presentation.
- Do not make toasts key windows, call `endEditing`, or forcibly move accessibility focus.
- Do not change dependency versions as an incidental part of an unrelated fix.

## Tests and reviews

Hosted tests live under `Tests/LSToastTests` and require iOS 16 for Swift Testing / ContinuousClock. The library and demo app still support iOS 15. UIKit tests need an iOS app host and should be run through the demo's shared scheme. The app host links the static LSToast product; the test target resolves those symbols through its host and must not link that static product a second time. A plain macOS `swift test` is not an iOS UIKit test run.

Changes to lifecycle, queue isolation, timing, or window selection need a focused regression test. UI changes should include an actual simulator screenshot or recording and note the runtime version. State which checks ran and which did not; a configured workflow alone is not a passing result.

Keep pull requests focused. Explain the concrete trigger, the resulting behavior, and the verification command. Never commit `Pods`, `Carthage`, `.build`, DerivedData, private signing settings, or local build logs.

## Demo recording

`docs/images/demo.gif` is a recording of the real demo, not a mockup. When replacing it, demonstrate a business popup staying visible while toast messages appear and disappear. Prefer a short, readable loop; keep device content free of accounts, identifiers, or private data. Commit the updated GIF together with any necessary demo instructions.

## Distribution

Only maintainers publish tags and package-index releases. Follow [docs/releasing.md](docs/releasing.md); do not treat a successful `pod lib lint` as a Trunk publication.
