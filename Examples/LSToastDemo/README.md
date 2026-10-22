# LSToast Demo

LSToast 2.0 的独立 UIKit 示例，无需账号或后端。工程只添加仓库根目录的本地 **LSToast** Swift package；原生 `LSTPopViewSwift` 由该 package 的独立依赖自动解析。示例直接 `import LSTPopViewSwift` 来展示真实业务弹窗与等待队列。

## 在 Xcode 中运行

需要 Xcode 26+、Swift 6.2+ 编译器。App 与库最低支持 iOS 15；宿主测试使用 Swift Testing，需要 iOS 16+ 模拟器。CocoaPods、SPM、Carthage 三个示例均使用 `import LSTPopViewSwift`。

1. 打开 `Examples/LSToastDemo/LSToastDemo.xcodeproj`。
2. 等待 Swift Package Manager 解析依赖。
3. 选择共享 scheme **LSToastDemo**、任意 iOS 15+ 模拟器，点击 Run。
4. 真机运行时，为 App target 选择自己的开发团队。

主页展示默认 Toast、顶部/居中/底部、长文本、自动消失、连续替换、旧句柄安全、手动隐藏，以及可直接复制的调用代码。

点击「打开业务弹窗与等待队列」后，输入文字，再显示或隐藏 Toast。业务弹窗保留输入内容和操作按钮；低优先级弹窗继续等待，直到你主动关闭业务弹窗。示例按实例关闭自己的弹窗，不调用全局清场 API。

```swift
import LSToast

LSToast.show("保存成功", in: view)
LSToast.show("底部提示", in: view, duration: 3, position: .bottom)

let toast = LSToast.show("稍后可手动关闭", in: view, duration: 5)
toast?.hide()

LSToast.hide(in: view)
```

## 测试

共享 scheme 包含以示例 App 为宿主的 **LSToastTests** target，源文件位于仓库根 `Tests/LSToastTests/LSToastTests.swift`。选择模拟器后按 Command-U，或在仓库根执行：

```sh
xcodebuild -project Examples/LSToastDemo/LSToastDemo.xcodeproj \
  -scheme LSToastDemo \
  -destination 'platform=iOS Simulator,id=YOUR_SIMULATOR_UDID' \
  -derivedDataPath build/DemoTests \
  -resultBundlePath build/DemoTests.xcresult \
  -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO test
```

每次运行应使用新的结果目录。先用 `xcrun simctl list devices available` 查询实际 UDID。

## 录制 GIF

点击主页「播放演示」，会按固定次序展示：默认位置 → 顶部 → 底部 → 业务弹窗中保留输入 → 显示 Toast → 隐藏 Toast → 业务弹窗主动关闭 → 等待弹窗出现。整个流程约 18 秒，不调用网络接口。

也可以给 App 添加 launch argument **`--demo-autoplay`**，在启动后自动播放同一段流程。这样录制可以从干净启动开始，并复现 README 的演示。

常用稳定的辅助功能标识：

| 标识 | 控件 |
| --- | --- |
| `demo.basic` / `demo.play` | 默认显示 / 播放演示 |
| `demo.position.top` / `demo.position.center` / `demo.position.bottom` | 三个位置 |
| `demo.longText` / `demo.replace` / `demo.oldHandle` / `demo.hide` | 长文本、替换、旧句柄、隐藏 |
| `demo.openBusiness` | 打开业务与等待弹窗 |
| `demo.business.input` | 业务输入框 |
| `demo.business.show` / `demo.business.long` / `demo.business.hide` | 弹窗内显示、长提示、隐藏 |
| `demo.business.close` | 关闭业务弹窗并恢复队列 |
| `demo.queued.card` / `demo.queued.close` | 等待弹窗与完成按钮 |
| `demo.status` / `demo.business.queueState` | 状态文本 |

演示页面支持系统浅色与深色外观，并使用系统字体与 Dynamic Type。吐司本身由库处理，示例没有复制库的实现。
