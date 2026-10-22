# Changelog

LSToast follows [Semantic Versioning](https://semver.org/). Git tags identify source releases; CocoaPods Trunk availability is checked separately.

## 1.0.0

- Initial standalone UIKit toast API: `LSToast.show`, window-scoped `hide`, and presentation-specific weak `Handle`.
- Top, center, and bottom positions; multiline text; Dynamic Type and safe-area layout.
- Private parent-view scope that keeps toast operations out of business popup queues.
- Full touch-through behavior without changing the key window or ending input editing.
- Replacement-safe lifetime handling and automatic timed dismissal.
- CocoaPods, Swift Package Manager, and Carthage integration with independently resolved LSTPopView dependencies.
- UIKit demo, recorded demonstration GIF, hosted isolation tests, and CI configuration.
