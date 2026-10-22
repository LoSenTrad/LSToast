# 安装、依赖与集成

LSToast 2.0 的 CocoaPods、Swift Package Manager 和 Carthage 集成统一基于原生 Swift `LSTPopViewSwift`。包管理器会获取独立依赖，App 也可以直接使用安装后的弹窗模块。LSToast 的公开接口始终是 `import LSToast`。

## 依赖对应关系

| 使用方式 | 自动安装的弹窗依赖 | App 的弹窗模块 | 工具链 |
| --- | --- | --- | --- |
| CocoaPods | `LSTPopViewSwift ~> 0.1.0` | `LSTPopViewSwift` | Swift 6.2+ / Xcode 26+，iOS 15+ |
| SPM | LoSenTrad/LSTPopView 的 `LSTPopViewSwift` 产品 | `LSTPopViewSwift` | Swift 6.2+ / Xcode 26+，iOS 15+ |
| Carthage | LoSenTrad/LSTPopView 的 `LSTPopViewSwift` 动态框架 | `LSTPopViewSwift` | Swift 6.2+ / Xcode 26+，Carthage 0.38+，iOS 15+ |

三个分发入口使用同一上游原生 Swift 源码快照 [`a6099ecf24177f264dccc617043dc5d505482a21`](https://github.com/LoSenTrad/LSTPopView/commit/a6099ecf24177f264dccc617043dc5d505482a21)。CocoaPods 的原生 Pod 版本 `0.1.0` 对应上游 `swift-0.1.0` 标签；SPM 固定为语义版本 [`1.0.0-lstoast.1`](https://github.com/LoSenTrad/LSTPopView/releases/tag/1.0.0-lstoast.1)；Carthage 固定为同一 revision。不同的版本号属于不同分发入口，不代表三份弹窗实现。上游仍位于 [LoSenTrad/LSTPopView](https://github.com/LoSenTrad/LSTPopView) 仓库，无需另建或复制依赖源码。

SwiftPM 的正式版本需要依赖语义版本，因此其声明使用 exact version；Carthage 继续使用固定 revision。LSToast 自身采用 Swift 5 language mode，但完整依赖图要求 Swift 6.2 及以上编译器；原生弹窗模块以 Swift 6 language mode 编译。

## CocoaPods

```ruby
platform :ios, '15.0'

target 'YourApp' do
  use_frameworks!
  pod 'LSToast', '~> 2.0'
end
```

执行 `pod install`，打开 App 的 `.xcworkspace`。`LSTPopViewSwift` 会由依赖声明自动获取，无需另外声明。LSToast 2.0 的依赖图不再引入旧 Objective-C `LSTPopView` 和 `LSTTimer`，两个原生 Pod 的最低系统均为 iOS 15。

**[2.0.0 已发布到公共 Specs](https://github.com/CocoaPods/Specs/blob/master/Specs/1/f/d/LSToast/2.0.0/LSToast.podspec.json)。** 安装与测试证据见 [2.0.0 验证记录](validation.md)。也可指定已发布的 Git tag：

```ruby
pod 'LSToast', :git => 'https://github.com/LoSenTrad/LSToast.git', :tag => '2.0.0'
```

Git tag 安装仍会从 CocoaPods 索引解析独立的 `LSTPopViewSwift` 依赖，不是内置源码。相关语法见 [CocoaPods Podfile 指南](https://guides.cocoapods.org/using/the-podfile.html#from-a-podspec-in-the-root-of-a-library-repo)。

## Swift Package Manager

在 Xcode 的 **File → Add Package Dependencies…** 输入 `https://github.com/LoSenTrad/LSToast.git`，选择 `2.0.0` 及以上兼容版本，只将 `LSToast` 产品关联到 App target。SPM 会沿 `Package.swift` 的依赖声明获取上游包，并构建 `LSTPopViewSwift`。LSToast 的 SPM 产品是静态库，包含传递依赖符号；App 无需再次链接或嵌入同一上游产品即可直接导入它。

在另一个 Swift Package 中：

```swift
// Package.swift 中的顶层 dependencies
.package(url: "https://github.com/LoSenTrad/LSToast.git", from: "2.0.0")

// 业务 target 的 dependencies
.product(name: "LSToast", package: "LSToast")
```

提交 App 的 `Package.resolved`，使团队使用同一解析结果。不要通过编辑 `.build/checkouts` 或 DerivedData 内的临时副本修改依赖。

## Carthage

`Cartfile`：

```text
github "LoSenTrad/LSToast" ~> 2.0
```

构建：

```sh
carthage update --use-xcframeworks --platform iOS
```

依赖的获取与构建会自动进行，App 工程中的链接和嵌入需要自行设置：

1. 把 `Carthage/Build/LSToast.xcframework` 加入 App target。
2. 把 `Carthage/Build/LSTPopViewSwift.xcframework` 加入同一个 App target。
3. 两个动态框架均选择 **Embed & Sign**。
4. 提交 App 的 `Cartfile` 和 `Cartfile.resolved`。团队后续可使用 `carthage bootstrap --use-xcframeworks --platform iOS` 复现版本。

使用 XCFramework 时按照 [Carthage 官方集成说明](https://github.com/Carthage/Carthage#building-platform-independent-xcframeworks-xcode-12-and-above)操作，不要再为这些 XCFramework 追加旧版 `copy-frameworks` 脚本。运行时提示 `Library not loaded` 时，先检查两个框架是否都进入正确 target 的嵌入设置。

## 直接使用 LSTPopViewSwift

三种安装方式的业务 Swift 文件统一导入：

```swift
import LSToast
import LSTPopViewSwift
```

Xcode App 使用 SPM 时，只关联 `LSToast` 静态产品即可直接导入 `LSTPopViewSwift`；上游独立 package 会自动下载，其符号随静态产品链接。不要再向同一个 App target 重复添加或嵌入上游产品。Carthage 的两个产品则都是动态框架，仍必须按前文链接并嵌入两份 XCFramework。

另一个 Swift Package 的 target 若直接依赖上游 API，应在自己的 manifest 中显式声明上游 package/product，遵守 SwiftPM 的直接依赖边界。弹窗构造和队列 API 以 [LSTPopViewSwift 上游文档](https://github.com/LoSenTrad/LSTPopView/tree/master/Swift)为准。

业务弹窗可以使用同一依赖的正常管理器。LSToast 只在自己的透明父视图内管理吐司，不会主动调用该管理器的全局清空方法；吐司仍属于上游全局管理范围，App 主动调用 `removeAllPopView` / `removeLastPopView` 时可能连同吐司一起移除。

## 从 1.0 升级到 2.0

2.0 是主版本升级：1.0.0 的 CocoaPods 路径使用旧 Objective-C `LSTPopView` 与 `LSTTimer`；2.0 改为原生 Swift `LSTPopViewSwift`，统一模块名，并将 CocoaPods 完整依赖图的编译器要求提升到 Swift 6.2 / Xcode 26。`LSToast.show`、`hide`、`Handle` 的调用方式保持一致。SPM 和 Carthage 在 1.0 已使用原生 Swift 引擎，2.0 保持这一选择。

1. 将 LSToast 版本约束改为 2.0，并使用满足新要求的 Xcode。
2. CocoaPods App 若直接调用原有弹窗库，把相关 `import LSTPopView` 和业务调用迁移到 `LSTPopViewSwift` 的原生 API。导入名替换不能自动转换两套弹窗 API。
3. 若 App 的其他功能仍使用旧 Objective-C 引擎，在 App 的 Podfile 中单独显式声明它；LSToast 不再自动带入旧引擎，也不会把旧业务弹窗转换到新管理器。
4. 更新解析锁文件，检查 LSToast 的传递依赖为 `LSTPopViewSwift`。如果仍有 `LSTPopView` / `LSTTimer`，确认是否由 App 或其他依赖显式需要。
5. 仅为 1.0 的历史 Pod 目标增加的 iOS 15 部署目标调整，在 2.0 的纯原生依赖图中不再需要。删除前先确认 App 的其他依赖是否仍使用该设置。

已发布的 `1.0.0` tag 与 Specs 保留原有行为，不会原地修改；它的独立验证记录保存在 [1.0.0 历史验证](validation-1.0.0.md)。升级后应重新验证业务弹窗、等待队列与输入行为。

## 常见问题

### 吐司没有出现

优先显式传入已显示页面的 `view` 或 `window`。尚未加入窗口的临时 `UIView` 无法确定显示目标。纯空白文本、没有可用可见窗口时会返回 `nil`；检查返回值比继续排队重试更清楚。

### 多 scene App 显示在错误窗口

在当前页面中调用 `LSToast.show("完成", in: view)`。不要依赖省略 `in:` 时的 key-window 回退选择来判断用户当前操作的业务 scene。

### `No such module LSTPopViewSwift`

确认上游依赖已成功解析与构建。CocoaPods 请从生成的 `.xcworkspace` 打开并确认锁文件中有 `LSTPopViewSwift`；Xcode App 的 SPM 配置只需关联 `LSToast`；Carthage 则需要链接并嵌入两个动态框架。不要通过复制第二份上游源码或重复链接静态产品绕过解析错误。

### Swift tools version 不支持

三种安装方式都要求 Swift 6.2 / Xcode 26 及以上。选择满足要求的 Xcode，并检查 `xcode-select -p`、`xcrun swift --version`；改变 App 的 Swift language mode 不能升级实际编译器。

### 能否在 macOS 执行 `swift test`

LSToast 使用 UIKit，测试依赖 iOS App host。请在 iOS 16+ 模拟器运行 Demo 的共享 scheme，或执行 `scripts/test-demo.sh`。托管测试的 Swift Testing / ContinuousClock 需要 iOS 16；库和 Demo App 仍支持 iOS 15。macOS 的普通 `swift test` 不是同等验证。
