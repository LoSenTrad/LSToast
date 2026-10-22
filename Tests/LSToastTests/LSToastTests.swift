import UIKit
import Testing
import LSToast
import LSTPopViewSwift

@MainActor
private final class ToastFixture {
    private var allPopups: [LSTPopView] {
        return LSTPopView.getAllPopView()
    }
    let window: UIWindow
    let parent: UIView
    private weak var previousKey: UIWindow?

    init() throws {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let scene = try #require(scenes.first(where: { $0.activationState == .foregroundActive }) ?? scenes.first)
        previousKey = scene.windows.first(where: \.isKeyWindow)
        window = UIWindow(windowScene: scene)
        window.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        let root = UIViewController()
        window.rootViewController = root
        window.isHidden = false
        parent = root.view
        parent.frame = window.bounds
        window.layoutIfNeeded()
    }

    func businessPopup(content: UIView? = nil) throws -> LSTPopView {
        try #require(LSTPopView.initWithCustomView(content ?? UIView(frame: CGRect(x: 0, y: 0, width: 220, height: 120)),
                                                  parentView: parent, popStyle: .NO, dismissStyle: .NO))
    }

    var toasts: [LSTPopView] {
        allPopups.filter { $0.window === window && $0.accessibilityIdentifier == "lst.toast.popup" }
    }
    var hosts: [UIView] { window.subviews.filter { $0.accessibilityIdentifier == "lst.toast.host" } }

    func close() {
        // 只清本测试窗口及其等待者，绝不调用全局清场，避免影响并行 Suite 或宿主 App。
        LSToast.hide(in: window, animated: false)
        allPopups.filter { $0.parentView === parent || $0.parentView.window === window }
            .forEach { $0.dismissStyle = .NO; $0.dismiss() }
        window.isHidden = true
        window.rootViewController = nil
        previousKey?.makeKey()
    }
}

@MainActor
private func toastEventually(_ predicate: () -> Bool) async throws {
    let end = ContinuousClock.now.advanced(by: .seconds(3))
    while !predicate(), ContinuousClock.now < end { try await Task.sleep(for: .milliseconds(10)) }
    try #require(predicate(), "Toast UIKit behavior did not complete")
}

@Suite("LSToast · 业务弹窗隔离", .serialized)
@MainActor
struct LSToastTests {
    @Test("显示、替换、隐藏和到期不改变业务弹窗及其等待队列")
    func businessQueueIsUntouched() async throws {
        let f = try ToastFixture(); defer { f.close() }
        let business = try f.businessPopup()
        business.priority = 100
        var pops = 0; var dismisses = 0
        business.popViewDidPopBlock = { pops += 1 }
        business.popViewWillDismissBlock = { dismisses += 1 }
        business.pop()
        try await toastEventually { pops == 1 }
        let waiting = try f.businessPopup()
        waiting.priority = 1
        waiting.pop()
        let original = business.currCustomView.frame
        for message in ["第一次", "替换提示"] {
            let token = try #require(LSToast.show(message, in: f.window, duration: 10))
            #expect(token.isVisible)
            #expect(business.superview === f.parent && waiting.superview == nil)
            #expect(business.currCustomView.frame == original)
            #expect(pops == 1 && dismisses == 0)
        }
        LSToast.hide(in: f.window, animated: false)
        #expect(business.superview === f.parent && waiting.superview == nil)
        let auto = try #require(LSToast.show("自动消失", in: f.window, duration: 0.08))
        try await toastEventually { !auto.isVisible }
        #expect(business.superview === f.parent && waiting.superview == nil)
        #expect(pops == 1 && dismisses == 0)
        business.dismissStyle = .NO
        business.dismiss()
        try await toastEventually { waiting.superview === f.parent }
    }

    @Test("文字中心和背景均穿透到业务按钮，不改变 keyWindow")
    func hitTestingPassesThroughWholeToast() throws {
        let f = try ToastFixture(); defer { f.close() }
        let key = f.window.windowScene?.windows.first(where: \.isKeyWindow)
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 260, height: 160))
        let business = try f.businessPopup(content: button)
        business.pop()
        LSToast.show("保存成功", in: f.window, duration: 10)
        f.window.layoutIfNeeded()
        let toast = try #require(f.toasts.first)
        let middle = toast.currCustomView.convert(CGPoint(x: toast.currCustomView.bounds.midX,
                                                         y: toast.currCustomView.bounds.midY), to: f.window)
        #expect(f.window.hitTest(middle, with: nil) === button)
        let edge = CGPoint(x: 5, y: 5)
        #expect(f.window.hitTest(edge, with: nil)?.isDescendant(of: business) == true)
        #expect(f.window.windowScene?.windows.first(where: \.isKeyWindow) === key)
        #expect(!toast.accessibilityViewIsModal)
    }

    @Test("吐司显示和隐藏保留业务输入框 firstResponder")
    func inputFocusIsPreserved() async throws {
        let f = try ToastFixture(); defer { f.close() }
        f.window.makeKeyAndVisible()
        let field = UITextField(frame: CGRect(x: 0, y: 0, width: 240, height: 50))
        let business = try f.businessPopup(content: field)
        business.pop()
        try #require(field.becomeFirstResponder())
        LSToast.show("输入内容已保留", in: f.window)
        try await toastEventually { !f.toasts.isEmpty }
        #expect(field.isFirstResponder)
        LSToast.hide(in: f.window, animated: false)
        #expect(field.isFirstResponder)
        #expect(f.window.isKeyWindow)
        #expect(business.superview === f.parent)
    }

    @Test("旧 handle 和未结束的关闭动画不能移除替换后的新吐司")
    func oldHandleAndAnimationCannotCloseReplacement() async throws {
        let f = try ToastFixture(); defer { f.close() }
        let old = try #require(LSToast.show("旧提示", in: f.window, duration: 0.1))
        old.hide()
        let next = try #require(LSToast.show("新提示", in: f.window, duration: 10))
        old.hide(animated: false)
        try await Task.sleep(for: .milliseconds(400))
        #expect(next.isVisible && !old.isVisible)
        #expect(f.toasts.count == 1 && f.hosts.count == 1)
        #expect((f.toasts.first?.currCustomView.subviews.first as? UILabel)?.text == "新提示")
    }

    @Test("不同业务窗口与脱离窗口的显式 view 互不影响")
    func windowsAndDetachedViewsAreIsolated() async throws {
        let a = try ToastFixture(); let b = try ToastFixture()
        defer { b.close(); a.close() }
        let first = try #require(LSToast.show("A", in: a.window, duration: 10))
        let second = try #require(LSToast.show("B", in: b.window, duration: 10))
        let detached = UIView()
        #expect(LSToast.show("不允许串到其它窗口", in: detached) == nil)
        LSToast.hide(in: detached, animated: false)
        #expect(first.isVisible && second.isVisible)
        LSToast.hide(in: a.parent, animated: false)
        try await toastEventually { !first.isVisible && a.hosts.isEmpty }
        #expect(second.isVisible)
        #expect(a.hosts.isEmpty && b.hosts.count == 1)
    }

    @Test("已经启动的旧倒计时到期后不能移除新吐司")
    func runningOldTimerCannotCloseReplacement() async throws {
        let f = try ToastFixture(); defer { f.close() }
        let old = try #require(LSToast.show("旧计时器", in: f.window, duration: 0.4))
        // Preserve the old object and let its real presentation complete before replacing it.
        let oldPopup = try #require(f.toasts.first)
        try await Task.sleep(for: .milliseconds(250))
        let next = try #require(LSToast.show("新的 10 秒提示", in: f.window, duration: 10))
        try await Task.sleep(for: .milliseconds(650))
        #expect(!old.isVisible && oldPopup.superview == nil)
        #expect(next.isVisible && f.toasts.count == 1)
    }

    @Test("空白消息不关闭当前提示，无效时长回退默认值", arguments: [0.0, -1, .nan, .infinity])
    func invalidInputDoesNotBreakCurrentToast(duration: TimeInterval) throws {
        let f = try ToastFixture(); defer { f.close() }
        let token = try #require(LSToast.show("有效", in: f.window, duration: duration))
        #expect(LSToast.show(" \n\t", in: f.window) == nil)
        #expect(token.isVisible)
        #expect(f.toasts.first?.showTime == 0) // 吐司持有自己的倒计时，不借用业务弹窗的计时状态。
    }

    @Test("真实自动到期清理宿主、manager登记及内容弱引用")
    func expiryReleasesAllPresentationObjects() async throws {
        let f = try ToastFixture(); defer { f.close() }
        let token = try #require(LSToast.show("很快消失", in: f.window, duration: 0.08))
        weak var popup = f.toasts.first
        weak var content = popup?.currCustomView
        weak var host = f.hosts.first
        try await toastEventually { !token.isVisible && popup == nil && content == nil && host == nil }
        #expect(f.toasts.isEmpty && f.hosts.isEmpty)
    }

    @Test("业务显式移除吐司后清理宿主，下一次显示仍正常")
    func externalRemovalCleansHost() async throws {
        let f = try ToastFixture(); defer { f.close() }
        let old = try #require(LSToast.show("旧内容", in: f.window, duration: 10))
        let popup = try #require(f.toasts.first)
        popup.dismissStyle = .NO
        popup.dismiss()
        try await toastEventually { !old.isVisible && f.hosts.isEmpty }
        let next = try #require(LSToast.show("新内容", in: f.window, duration: 10))
        #expect(next.isVisible)
        #expect(f.toasts.first !== popup)
    }

    @Test("吐司采用非模态辅助功能语义")
    func accessibilityIsNonModal() throws {
        let f = try ToastFixture(); defer { f.close() }
        LSToast.show("提示", in: f.window, duration: 10)
        let popup = try #require(f.toasts.first)
        #expect(!popup.accessibilityViewIsModal)
        #expect(popup.isHideBg)
    }

    @Test("长文字在窄窗口及三个位置均保持安全区内", arguments: [LSToast.Position.top, .center, .bottom])
    func longTextFitsWindow(position: LSToast.Position) throws {
        let f = try ToastFixture(); defer { f.close() }
        f.window.frame.size = CGSize(width: 280, height: 640)
        LSToast.show(String(repeating: "这是一条多行提示。", count: 10), in: f.window, duration: 10, position: position)
        f.window.layoutIfNeeded()
        let popup = try #require(f.toasts.first)
        let card = popup.currCustomView.convert(popup.currCustomView.bounds, to: f.window)
        let safe = f.window.bounds.inset(by: f.window.safeAreaInsets)
        #expect(card.minX >= safe.minX && card.maxX <= safe.maxX)
        #expect(card.minY >= safe.minY && card.maxY <= safe.maxY)
    }
}
