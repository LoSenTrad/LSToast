# 安装、依赖与集成

LSToast 不内置一份改名的弹窗引擎。包管理器会获取独立的 LSTPopView 依赖，App 也可以使用安装后的弹窗模块。LSToast 的公开接口始终是 `import LSToast`。

## 依赖对应关系

| 使用方式 | LSToast 下游依赖 | App 的弹窗模块 | 工具链 |
| --- | --- | --- | --- |
| CocoaPods | `LSTPopView ~> 0.3.10` → `LSTTimer` | `LSTPopView`（Objective-C） | Swift 5.9+，iOS 15+ |
| SPM | LoSenTrad/LSTPopView 的 Swift 产品 | `LSTPopViewSwift` | Swift 6.2+ / Xcode 26+，iOS 15+ |
| Carthage | LoSenTrad/LSTPopView 的动态框架 | `LSTPopViewSwift` | Swift 6.2+ / Xcode 26+，Carthage 0.38+，iOS 15+ |

SPM 的上游依赖固定为语义版本 [`1.0.0-lstoast.1`](https://github.com/LoSenTrad/LSTPopView/releases/tag/1.0.0-lstoast.1)，Carthage 固定为同一份代码的 revision [`a6099ecf24177f264dccc617043dc5d505482a21`](https://github.com/LoSenTrad/LSTPopView/commit/a6099ecf24177f264dccc617043dc5d505482a21)，使用其中的原生 Swift 模块与动态框架入口。SwiftPM 的正式版本需要依赖语义版本，因此不能只使用 `revision:`。这个上游快照不改变 CocoaPods 的 `0.3.10` 版本约束。

上游原生 Swift 模块与旧 Objective-C Pod 并非同一个二进制。不要把两者的导入名或自定义弹窗示例直接混用。LSToast 在内部适配后端，App 的吐司调用方式保持一致。

## CocoaPods

```ruby
platform :ios, '15.0'

target 'YourApp' do
  use_frameworks!
  pod 'LSToast', '~> 1.0'
end

post_install do |installer|
  minimum = Gem::Version.new('15.0')

  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      current = config.build_settings['IPHONEOS_DEPLOYMENT_TARGET']
      next unless current.to_s.match?(/\A\d+(?:\.\d+)*\z/)
      next unless Gem::Version.new(current) < minimum

      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
    end
  end
end
```

历史 Pod target 的最低系统设置可能低于当前 Xcode 支持范围。上面的 `post_install` 仅将显式低于 15 的部署目标提升到 15，不修改上游源码和版本，也不会降低已有更高的最低版本。已有 `post_install` 回调时，应将循环合并进去，不能另写第二份覆盖原有处理。

执行 `pod install`，打开 App 的 `.xcworkspace`。`LSTPopView` 和 `LSTTimer` 会由依赖声明自动获取；无需手动复制文件或维护另一份源码。

已经直接使用 `LSTPopView` 的 App，可以保留与 `~> 0.3.10` 兼容的显式版本约束，CocoaPods 会统一解析。已有约束不兼容时，应解决版本冲突，不能通过复制第二份弹窗实现绕过解析器。

**1.0.0 已发布到 CocoaPods 公共 Specs，可以直接使用上面的版本声明。** `pod trunk info LSToast` 可查询发布记录，对应的 [公共 podspec](https://github.com/CocoaPods/Specs/blob/master/Specs/1/f/d/LSToast/1.0.0/LSToast.podspec.json) 已可读取。

直接读取 Git tag 中的 podspec 仍可使用以下声明；保留上面的 `post_install`：

```ruby
pod 'LSToast', :git => 'https://github.com/LoSenTrad/LSToast.git', :tag => '1.0.0'
```

发布证据见 [1.0.0 验证记录](validation.md)；相关语法见 [CocoaPods Podfile 指南](https://guides.cocoapods.org/using/the-podfile.html#from-a-podspec-in-the-root-of-a-library-repo)。

## Swift Package Manager

在 Xcode 的 **File → Add Package Dependencies…** 输入 `https://github.com/LoSenTrad/LSToast.git`，选择 `1.0.0` 及以上兼容版本，只将 `LSToast` 产品关联到 App target。SPM 会沿 `Package.swift` 的依赖声明下载 LSTPopView，并构建 `LSTPopViewSwift`。LSToast 的 SPM 产品是静态库，包含传递依赖符号；App 无需再次链接或嵌入同一上游产品即可直接导入它。

在另一个 Swift Package 中：

```swift
// Package.swift 中的顶层 dependencies
.package(url: "https://github.com/LoSenTrad/LSToast.git", from: "1.0.0")

// 业务 target 的 dependencies
.product(name: "LSToast", package: "LSToast")
```

提交 App 的 `Package.resolved`，使团队使用同一解析结果。不要通过编辑 `.build/checkouts` 或 DerivedData 内的临时副本修改依赖。

## Carthage

`Cartfile`：

```text
github "LoSenTrad/LSToast" ~> 1.0
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

## 直接使用 LSTPopView

CocoaPods 集成后的业务 Swift 文件可导入独立的 OC 模块：

```swift
import LSToast
import LSTPopView
```

SPM / Carthage 集成使用原生 Swift 模块：

```swift
import LSToast
import LSTPopViewSwift
```

Xcode App 使用 SPM 时，只关联 `LSToast` 静态产品即可直接导入 `LSTPopViewSwift`；上游独立 package 会自动下载，其符号随静态产品链接。不要再向同一个 App target 重复添加或嵌入上游产品。Carthage 的两个产品则都是动态框架，仍必须按前文链接并嵌入两份 XCFramework。

另一个 Swift Package 的 target 若直接依赖上游 API，应在自己的 manifest 中显式声明上游 package/product，遵守 SwiftPM 的直接依赖边界。弹窗构造和队列 API 以 [LSTPopView 上游文档](https://github.com/LoSenTrad/LSTPopView)为准。

业务弹窗可以使用同一依赖的正常管理器。LSToast 只在自己的透明父视图内管理吐司，不会主动调用该管理器的全局清空方法；吐司仍属于上游全局管理范围，App 主动调用 `removeAllPopView` / `removeLastPopView` 时可能连同吐司一起移除。

## 常见问题

### 吐司没有出现

优先显式传入已显示页面的 `view` 或 `window`。尚未加入窗口的临时 `UIView` 无法确定显示目标。纯空白文本、没有可用可见窗口时会返回 `nil`；检查返回值比继续排队重试更清楚。

### 多 scene App 显示在错误窗口

在当前页面中调用 `LSToast.show("完成", in: view)`。不要依赖省略 `in:` 时的 key-window 回退选择来判断用户当前操作的业务 scene。

### `No such module LSTPopViewSwift`

确认当前使用 SPM / Carthage 路径且上游依赖已成功解析与构建。Xcode App 的 SPM 配置只需关联 `LSToast`；Carthage 则需要链接并嵌入两个动态框架。CocoaPods 路径的模块叫 `LSTPopView`。不要通过复制第二份上游源码或重复链接静态产品绕过解析错误。

### Swift tools version 不支持

SPM / Carthage 使用的上游 Swift 包要求 Swift 6.2 / Xcode 26 及以上。选择满足要求的 Xcode，并检查 `xcode-select -p`、`xcrun swift --version`；改变 App 的 Swift language mode 不能升级实际编译器。

### 能否在 macOS 执行 `swift test`

LSToast 使用 UIKit，测试依赖 iOS App host。请在 iOS 16+ 模拟器运行 Demo 的共享 scheme，或执行 `scripts/test-demo.sh`。托管测试的 Swift Testing / ContinuousClock 需要 iOS 16；库和 Demo App 仍支持 iOS 15。macOS 的普通 `swift test` 不是同等验证。
