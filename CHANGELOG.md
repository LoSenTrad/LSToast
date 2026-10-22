# Changelog

LSToast follows [Semantic Versioning](https://semver.org/). Git tags identify source releases; CocoaPods Trunk availability is checked separately.

## 2.0.0

- Unify all three dependency managers on the external native Swift `LSTPopViewSwift` module. CocoaPods now resolves `LSTPopViewSwift ~> 0.1.0`; SPM and Carthage retain the same native engine snapshot.
- Remove the legacy Objective-C CocoaPods backend, `LSTOAST_COCOAPODS` conditional branches, and the transitive `LSTPopView` / `LSTTimer` dependency chain.
- Require a Swift 6.2+ compiler / Xcode 26+ for every integration path; the minimum deployment target remains iOS 15. LSToast's own Swift 5 language mode does not lower the native dependency's compiler requirement.
- Keep `LSToast.show`, window-scoped `hide`, and presentation-specific `Handle` APIs unchanged. Applications that directly used the old Objective-C popup module must migrate those calls or declare that module separately.
- Update all integration examples and installation guidance for the unified native module. Archive the 1.0.0 validation history separately; the new version's validation and publication status are recorded in [2.0.0 validation](docs/validation.md).

## 1.0.0

- Initial standalone UIKit toast API: `LSToast.show`, window-scoped `hide`, and presentation-specific weak `Handle`.
- Top, center, and bottom positions; multiline text; Dynamic Type and safe-area layout.
- Private parent-view scope that keeps toast operations out of business popup queues.
- Full touch-through behavior without changing the key window or ending input editing.
- Replacement-safe lifetime handling and automatic timed dismissal.
- CocoaPods integration through Objective-C `LSTPopView` / `LSTTimer`, and SPM / Carthage integration through native Swift `LSTPopViewSwift`, all independently resolved.
- UIKit demo, recorded demonstration GIF, hosted isolation tests, and CI configuration.
