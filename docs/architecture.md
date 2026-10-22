# 吐司与业务弹窗的隔离边界

LSToast 的目标是让短暂的文字提示可以与业务弹窗共存。显示、替换、隐藏吐司时，只操作吐司自己的对象和父视图。

## 窗口归属

每个业务 `UIWindow` 通过独立 presenter 保存当前吐司。传入 `UIView` 时，以该 view 所属窗口为显示位置；直接传入 `UIWindow` 时使用该窗口。省略参数时才回退到活动 key window 查找。它不创建额外 UIWindow，也不切换 key window。

一个窗口中的新提示替换该窗口的旧提示。不同窗口的 presenter、宿主和计时生命周期互不共用。多 scene 业务应明确传入目标页面的 view。

## 私有父视图

吐司插入专属透明父视图，使用这个父视图作为原生 Swift 弹窗的 presentation context。业务弹窗仍使用业务自己的父容器。它们不进入同一个按父容器管理的弹窗作用域。

LSToast 为吐司保留确切的实例引用，自动消失、主动隐藏、替换和句柄关闭最终都针对该实例。它不调用 `removeAllPopView`、`removeLastPopView`，也不通过全局 key 查找后删除某个业务对象。

App 仍可以直接使用独立的 LSTPopViewSwift 依赖。吐司仍登记在同一依赖的全局管理范围，App 主动调用 `removeAllPopView` / `removeLastPopView` 时可能移除吐司。移除整个父容器或关闭窗口，也会影响所在吐司；具体影响范围按上游管理器与 UIKit 的语义执行。组件不拦截或绕过 App 的清场意图。

## 触摸与输入

宿主的命中测试返回 `nil`，吐司也没有交互按钮，因此文字、边距和透明区域都不截获触摸。底层业务视图仍接收点击与手势。吐司不是模态阻塞层，不应用于阻止重复提交。

组件不调用 `endEditing`，不切换 key window，不为了提示主动切换 first responder，也不发送强制切换辅助功能焦点的事件。这些约束保留输入状态，但不等于消息必然被 VoiceOver 听读。必须被用户确认或阅读的业务结果，应使用更合适的状态呈现。

## 替换与句柄

每次显示生成新的请求标识。旧显示的结束回调只能清理旧宿主，不能把新请求的状态置空。句柄弱引用 presenter 并保存本次显示标识，已经过期的句柄不会“寻找当前吐司”再关闭它。

吐司期限由 presenter 按本次请求标识管理，上游 popup 的自动关闭计时不参与吐司期限。新提示替换旧提示时，旧实例退出，旧截止任务不能关闭后来的实例。物理移除宿主时也会清理对应实例，不依赖析构时的回调。不要为了提示再在业务层维护一个会调用全局 `LSToast.hide()` 的旧延迟任务；需要稍后取消某次提示时，保存该次 `Handle`。

## 布局与消息长度

内容根据安全区域、最大宽度和 Dynamic Type 计算大小，支持顶部、居中、底部。吐司适合简短文本；长文本可能被可用空间限制，重要说明应放入业务页面。输入焦点保留不代表所有自定义键盘、浮动键盘及多窗口场景下的底部位置都已经得到人工验证。

## 统一的原生 Swift 依赖

LSToast 2.0 的 CocoaPods、SPM 和 Carthage 入口统一使用原生 Swift `LSTPopViewSwift`。源码中直接导入该模块，不再根据包管理器选择 Objective-C 后端，也不再通过 `LSTOAST_COCOAPODS` 编译条件切换实现。

原生引擎来自独立上游仓库 [LoSenTrad/LSTPopView](https://github.com/LoSenTrad/LSTPopView)，三个分发入口使用同一源码快照。CocoaPods 对应 `LSTPopViewSwift ~> 0.1.0`；SPM 对应精确语义版本 `1.0.0-lstoast.1`；Carthage 对应提交 `a6099ecf24177f264dccc617043dc5d505482a21`。LSToast 不内置或改名复制上游类，也不再传递引入旧 Objective-C `LSTPopView` / `LSTTimer`。

依赖管理器负责获取和解析；Carthage 下 App 仍需要嵌入两个动态框架。SPM 的 LSToast 产品采用静态链接，Xcode App 只关联 LSToast 即可直接导入上游模块，无需重复链接上游产品；另一个 Swift Package 的 target 若直接使用上游 API，则应声明自己的直接 package/product 依赖。

旧 Objective-C 引擎和原生 Swift 引擎是不同实现与管理器。如果 App 为自己的业务继续显式安装旧引擎，它的全局管理器不会因此成为 LSToast 的管理器；LSToast 只使用原生 Swift 引擎。1.0 的 CocoaPods 迁移细节见[安装说明](installation.md#从-10-升级到-20)。

## 验证范围

库和 Demo App 的最低系统是 iOS 15；托管测试因 Swift Testing / ContinuousClock 要求使用 iOS 16+。测试通过 App host 解析静态库符号，测试 target 不再次链接同一静态产品。

托管测试验证窗口作用域、触摸命中、输入焦点、队列隔离、替换时序、旧句柄和对象释放。Demo 用于人工观察动画及业务弹窗共存。实际支持结论应结合对应提交的构建和测试证据；一个包管理器的通过不能代替另一个集成方式的构建、设备或运行时检查。
