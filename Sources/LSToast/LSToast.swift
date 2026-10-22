import UIKit
import ObjectiveC
import LSTPopViewSwift

/// 每个业务窗口独立的轻提示。只管理自己的 LSTPopView，不清空或推进业务弹窗队列。
@MainActor
public enum LSToast {
    public enum Position: Sendable { case top, center, bottom }

    /// A handle to one presentation. An old handle never dismisses its replacement.
    @MainActor
    public final class Handle {
        private weak var presenter: LSToastPresenter?
        private let requestID: UUID
        fileprivate init(presenter: LSToastPresenter, requestID: UUID) {
            self.presenter = presenter; self.requestID = requestID
        }
        public var isVisible: Bool { presenter?.isVisible(requestID) == true }
        public func hide(animated: Bool = true) { presenter?.hide(requestID: requestID, animated: animated) }
    }

    private static var presenterKey: UInt8 = 0

    @discardableResult
    public static func show(_ message: String, in view: UIView? = nil,
                     duration: TimeInterval = 2, position: Position = .center) -> Handle? {
        let message = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty, let window = window(for: view), !window.isHidden else { return nil }
        let presenter: LSToastPresenter
        if let existing = objc_getAssociatedObject(window, &presenterKey) as? LSToastPresenter {
            presenter = existing
        } else {
            presenter = LSToastPresenter(window: window)
            objc_setAssociatedObject(window, &presenterKey, presenter, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        return presenter.show(message, duration: duration.isFinite && duration > 0 ? duration : 2,
                              position: position)
    }

    /// 只隐藏指定窗口的当前吐司，不通过全局 key、removeLast 或 removeAll 寻找弹窗。
    public static func hide(in view: UIView? = nil, animated: Bool = true) {
        guard let window = window(for: view),
              let presenter = objc_getAssociatedObject(window, &presenterKey) as? LSToastPresenter else { return }
        presenter.hide(animated: animated)
    }

    private static func window(for view: UIView?) -> UIWindow? {
        if let view { return (view as? UIWindow) ?? view.window }
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let active = scenes.filter { $0.activationState == .foregroundActive }
        let foreground = active.isEmpty ? scenes.filter { $0.activationState == .foregroundInactive } : active
        let windows = foreground.flatMap(\.windows).filter { !$0.isHidden && $0.windowLevel == .normal }
        let keys = windows.filter(\.isKeyWindow)
        if keys.count == 1 { return keys[0] }
        if keys.isEmpty && foreground.count == 1 && windows.count == 1 { return windows[0] }
        return nil
    }
}

@MainActor
fileprivate final class LSToastPresenter {
    private weak var window: UIWindow?
    private var host: LSToastHostView?
    private var popup: LSTPopView?
    private var requestID = UUID()
    private var expiry: DispatchWorkItem?

    init(window: UIWindow) { self.window = window }

    func isVisible(_ id: UUID) -> Bool { requestID == id && popup?.window != nil }

    func show(_ message: String, duration: TimeInterval, position: LSToast.Position) -> LSToast.Handle? {
        guard let window else { return nil }
        let id = UUID()
        requestID = id
        expiry?.cancel(); expiry = nil
        // 先推进请求标识再移除旧弹窗，避免旧回调清理后来的提示。
        popup?.dismissStyle = .NO
        popup?.dismiss()
        host?.removeFromSuperview()
        popup = nil; host = nil
        let host = LSToastHostView(frame: window.bounds)
        host.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        host.accessibilityIdentifier = "lst.toast.host"
        window.addSubview(host)
        let content = LSToastContentView(message: message)
        guard let popup = LSTPopView.initWithCustomView(content, parentView: host,
                                                       popStyle: .fade, dismissStyle: .fade) else {
            host.removeFromSuperview(); return nil
        }
        guard popup.isPresentationContextValid else { host.removeFromSuperview(); return nil }
        self.host = host; self.popup = popup
        popup.accessibilityIdentifier = "lst.toast.popup"
        popup.groupId = "LSToast.private"
        popup.isStack = true
        popup.isHideBg = true
        popup.isClickBgDismiss = false
        popup.isUserInteractionEnabled = false
        popup.popDuration = 0.15
        popup.dismissDuration = 0.15
        // 倒计时由吐司持有，取消旧任务后再按本次请求标识关闭，避免影响替换后的实例。
        popup.showTime = 0
        host.configure(popup: popup, content: content, position: position)
        host.onPopupRemoved = { [weak self, weak host] in self?.finishIfRemoved(id, host: host) }
        popup.popViewDidPopBlock = { [weak self] in self?.startExpiry(id, duration: duration) }
        popup.pop()
        // A global clearing transaction may reject entry. Clean up, without retrying across its barrier.
        DispatchQueue.main.async { [weak self, weak host] in self?.finishIfRemoved(id, host: host) }
        return LSToast.Handle(presenter: self, requestID: id)
    }

    private func startExpiry(_ id: UUID, duration: TimeInterval) {
        guard requestID == id else { return }
        expiry?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.hide(requestID: id, animated: true) }
        expiry = work
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: work)
    }

    func hide(requestID id: UUID? = nil, animated: Bool) {
        guard id == nil || id == requestID else { return }
        expiry?.cancel(); expiry = nil
        // 只关闭当前持有的 Swift 弹窗实例，保留业务弹窗及其队列。
        popup?.dismissStyle = animated ? .fade : .NO
        popup?.dismiss()
        finishIfRemoved(requestID, host: host)
    }

    private func finishIfRemoved(_ id: UUID, host removedHost: LSToastHostView?) {
        guard requestID == id, let host, host === removedHost, popup?.superview !== host else { return }
        expiry?.cancel(); expiry = nil
        host.removeFromSuperview()
        popup = nil; self.host = nil
    }
}

/// 命中测试完整穿透，包括文字所在区域；不会抢走业务弹窗按钮、手势或输入焦点。
@MainActor
private final class LSToastHostView: UIView {
    private weak var popup: LSTPopView?
    private weak var content: LSToastContentView?
    private var position = LSToast.Position.center
    var onPopupRemoved: (() -> Void)?

    override func willRemoveSubview(_ subview: UIView) {
        super.willRemoveSubview(subview)
        guard subview === popup else { return }
        // 以视图真正移除作为清理时机，也覆盖业务方直接关闭依赖库中吐司实例的情况。
        // UIKit 在宿主析构时也会调用这里；复用已有弱引用回调，避免对析构中的 self 新建弱引用。
        let notifyRemoval = onPopupRemoved
        DispatchQueue.main.async { notifyRemoval?() }
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? { nil }

    func configure(popup: LSTPopView, content: LSToastContentView, position: LSToast.Position) {
        self.popup = popup; self.content = content; self.position = position
        updateLayout()
    }

    override func layoutSubviews() { super.layoutSubviews(); updateLayout() }
    override func safeAreaInsetsDidChange() { super.safeAreaInsetsDidChange(); setNeedsLayout() }
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        setNeedsLayout()
    }

    private func updateLayout() {
        guard let popup, let content, bounds.width > 0, bounds.height > 0 else { return }
        let safe = bounds.inset(by: safeAreaInsets)
        content.fit(maximum: CGSize(width: max(1, min(CGFloat(320), safe.width - CGFloat(32))),
                                   height: max(1, safe.height - CGFloat(72))))
        switch position {
        case .center:
            popup.hemStyle = .center
            popup.adjustY = (safeAreaInsets.top - safeAreaInsets.bottom) / 2
        case .top:
            popup.hemStyle = .top
            popup.adjustY = safeAreaInsets.top + CGFloat(20)
        case .bottom:
            popup.hemStyle = .bottom
            popup.adjustY = -safeAreaInsets.bottom - CGFloat(36)
        }
        popup.setNeedsLayout()
    }
}

@MainActor
private final class LSToastContentView: UIView {
    private let label = UILabel()

    init(message: String) {
        super.init(frame: .zero)
        backgroundColor = UIColor(white: 0.08, alpha: 0.92)
        layer.cornerRadius = CGFloat(10)
        clipsToBounds = true
        isUserInteractionEnabled = false
        label.text = message
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.accessibilityIdentifier = "lst.toast.message"
        addSubview(label)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func fit(maximum: CGSize) {
        label.font = UIFontMetrics(forTextStyle: .subheadline).scaledFont(for: .systemFont(ofSize: CGFloat(15)))
        let horizontal = min(CGFloat(16), maximum.width / 4)
        let vertical = min(CGFloat(12), maximum.height / 4)
        let text = label.sizeThatFits(CGSize(width: max(1, maximum.width - horizontal * 2),
                                            height: .greatestFiniteMagnitude))
        bounds.size = CGSize(width: min(maximum.width, ceil(text.width) + horizontal * 2),
                             height: min(maximum.height, ceil(text.height) + vertical * 2))
        label.frame = bounds.insetBy(dx: horizontal, dy: vertical)
    }
}
