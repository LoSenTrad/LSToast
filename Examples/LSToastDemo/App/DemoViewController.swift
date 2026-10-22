import UIKit
import LSToast
#if LSTOAST_COCOAPODS
import LSTPopView
#else
import LSTPopViewSwift
#endif

/// This app depends on the local LSToast package only. Its LSTPopView dependency
/// is also available to the app for normal business popup presentation.
@MainActor
final class DemoViewController: UIViewController {
    private let scrollView = UIScrollView()
    private let status = DemoStyle.label("准备好了 · Ready to try", size: 12, color: .secondaryLabel)
    private weak var businessPopup: LSTPopView?
    private weak var queuedPopup: LSTPopView?
    private weak var businessInput: UITextField?
    private weak var businessState: UILabel?
    private var toastCount = 0
    private var playback: Task<Void, Never>?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = DemoStyle.canvas
        buildPage()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Optional deterministic playback for recording the repository's GIF.
        if ProcessInfo.processInfo.arguments.contains("--demo-autoplay"), playback == nil {
            playDemo()
        }
    }

    private func buildPage() {
        scrollView.accessibilityIdentifier = "demo.scroll"
        scrollView.alwaysBounceVertical = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        let stack = DemoStyle.stack(spacing: 16)
        stack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stack)
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -36),
            stack.centerXAnchor.constraint(equalTo: scrollView.frameLayoutGuide.centerXAnchor),
            stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -36)
        ])
        stack.addArrangedSubview(hero())

        let positions = DemoStyle.stack(spacing: 10)
        positions.addArrangedSubview(DemoStyle.row(
            DemoStyle.button("顶部", symbol: "arrow.up.to.line", id: "demo.position.top") { [weak self] in
                self?.show("顶部提示 · Top", position: .top)
            },
            DemoStyle.button("居中", symbol: "dot.scope", id: "demo.position.center") { [weak self] in
                self?.show("居中提示 · Center")
            },
            DemoStyle.button("底部", symbol: "arrow.down.to.line", id: "demo.position.bottom") { [weak self] in
                self?.show("底部提示 · Bottom", position: .bottom)
            }
        ))
        positions.addArrangedSubview(DemoStyle.button("长文本与自动消失", symbol: "text.alignleft",
                                                     id: "demo.longText") { [weak self] in
            self?.show("这是一条可以自动换行的轻提示。\n文字显示期间，页面仍然可以滚动，按钮仍然可以点击。\nA little message. Everything else keeps going.", duration: 4)
        })
        stack.addArrangedSubview(DemoStyle.card(title: "01  想放哪里，就放哪里", subtitle: "Top, center or bottom. Messages disappear automatically.", content: positions))

        let lifecycle = DemoStyle.stack(spacing: 10)
        lifecycle.addArrangedSubview(DemoStyle.row(
            DemoStyle.button("连续替换", symbol: "arrow.triangle.2.circlepath", id: "demo.replace") { [weak self] in
                self?.replaceToast()
            },
            DemoStyle.button("旧句柄安全", symbol: "checkmark.shield", id: "demo.oldHandle") { [weak self] in
                self?.verifyOldHandle()
            }
        ))
        lifecycle.addArrangedSubview(DemoStyle.button("只隐藏当前 Toast", symbol: "eye.slash", id: "demo.hide") { [weak self] in
            guard let self else { return }
            LSToast.hide(in: self.view)
            self.status.text = "只隐藏当前窗口的 Toast · Current toast hidden"
        })
        stack.addArrangedSubview(DemoStyle.card(title: "02  每次显示，都有边界", subtitle: "Latest message wins. Old handles cannot dismiss a newer toast.", content: lifecycle))

        let coexistence = DemoStyle.stack(spacing: 10)
        coexistence.addArrangedSubview(DemoStyle.label("在真实 LSTPopView 弹窗里输入，再显示或隐藏 Toast。等待中的弹窗只会在业务弹窗关闭后出现。", size: 14, color: .secondaryLabel))
        coexistence.addArrangedSubview(DemoStyle.button("打开业务弹窗与等待队列", symbol: "rectangle.on.rectangle",
                                                       id: "demo.openBusiness", primary: true) { [weak self] in
            self?.openBusinessPopup()
        })
        stack.addArrangedSubview(DemoStyle.card(title: "03  弹窗继续，提示轻轻来", subtitle: "Business popup, text input and queue remain independent.", content: coexistence))
        stack.addArrangedSubview(codeCard())
        status.accessibilityIdentifier = "demo.status"
        status.textAlignment = .center
        stack.addArrangedSubview(status)
    }

    private func hero() -> UIView {
        let card = UIView()
        card.layer.cornerRadius = 26
        card.backgroundColor = DemoStyle.softAccent
        let content = DemoStyle.stack(spacing: 13)
        content.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(content)
        let brand = UIStackView()
        brand.axis = .horizontal
        brand.alignment = .center
        brand.spacing = 10
        let icon = UIImageView(image: UIImage(systemName: "text.bubble.fill"))
        icon.tintColor = DemoStyle.accent
        icon.contentMode = .scaleAspectFit
        icon.widthAnchor.constraint(equalToConstant: 28).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 28).isActive = true
        brand.addArrangedSubview(icon)
        let name = DemoStyle.label("LSToast", size: 29, weight: .bold)
        name.accessibilityIdentifier = "demo.title"
        brand.addArrangedSubview(name)
        brand.addArrangedSubview(UIView())
        content.addArrangedSubview(brand)
        content.addArrangedSubview(DemoStyle.label("轻提示，不打断。", size: 22, weight: .semibold))
        content.addArrangedSubview(DemoStyle.label("A small toast. A smooth experience.\n基于 LSTPopView，让业务弹窗按原计划继续。", size: 13, color: .secondaryLabel))
        content.addArrangedSubview(DemoStyle.row(
            DemoStyle.button("显示 Toast", symbol: "sparkles", id: "demo.basic", primary: true) { [weak self] in
                self?.show("操作成功 · Saved successfully")
            },
            DemoStyle.button("播放演示", symbol: "play.fill", id: "demo.play") { [weak self] in self?.playDemo() }
        ))
        NSLayoutConstraint.activate([
            content.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            content.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
            content.topAnchor.constraint(equalTo: card.topAnchor, constant: 22),
            content.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -22)
        ])
        return card
    }

    private func codeCard() -> UIView {
        let code = DemoStyle.stack(spacing: 10)
        let label = DemoStyle.label("import LSToast\n\nLSToast.show(\"保存成功\", in: view)\n\nlet toast = LSToast.show(\n    \"提示内容\", in: view,\n    duration: 3, position: .bottom\n)\ntoast?.hide()\n\nLSToast.hide(in: view)", size: 12)
        label.font = .monospacedSystemFont(ofSize: 12, weight: .medium)
        label.textColor = DemoStyle.accent
        label.accessibilityIdentifier = "demo.code"
        code.addArrangedSubview(label)
        code.addArrangedSubview(DemoStyle.label("只添加 LSToast，LSTPopView 会作为独立依赖自动下载。\nAdd LSToast once. Its popup dependency resolves automatically.", size: 12, color: .secondaryLabel))
        return DemoStyle.card(title: "从一行代码开始", subtitle: "Small API, explicit ownership.", content: code)
    }

    private func show(_ message: String, duration: TimeInterval = 2, position: LSToast.Position = .center) {
        LSToast.show(message, in: view, duration: duration, position: position)
        status.text = "Toast 已显示，\(Int(duration)) 秒后自动消失 · Auto dismiss"
    }

    private func replaceToast() {
        LSToast.show("第一条提示 · First message", in: view, duration: 5)
        status.text = "第一条提示即将被第二条替换 · Replacing"
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            guard let self else { return }
            self.show("第二条提示 · 只保留最新一条", duration: 3)
        }
    }

    private func verifyOldHandle() {
        let old = LSToast.show("旧提示 · Old message", in: view, duration: 8)
        status.text = "显示新提示后，调用旧 handle.hide() · Old handle test"
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { [weak self] in
            guard let self else { return }
            LSToast.show("新提示仍在 · Old handle cannot hide me", in: self.view, duration: 4)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
                old?.hide()
                self?.status.text = "旧 handle 已调用，新提示仍保留 · New toast is safe"
            }
        }
    }

    private func openBusinessPopup() {
        guard businessPopup == nil, queuedPopup == nil else { return }
        let width = min(CGFloat(352), view.bounds.width - 36)
        let card = UIView(frame: CGRect(x: 0, y: 0, width: width, height: 454))
        card.backgroundColor = .secondarySystemGroupedBackground
        card.layer.cornerRadius = 26
        card.accessibilityIdentifier = "demo.business.card"
        let content = DemoStyle.stack(spacing: 10)
        content.frame = card.bounds.insetBy(dx: 20, dy: 22)
        content.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        let title = DemoStyle.label("业务弹窗还在这里", size: 21, weight: .bold)
        title.textAlignment = .center
        content.addArrangedSubview(title)
        let subtitle = DemoStyle.label("Business popup stays put.\n显示或隐藏 Toast，不改变这里的状态。", size: 12, color: .secondaryLabel)
        subtitle.textAlignment = .center
        content.addArrangedSubview(subtitle)
        let input = UITextField()
        input.borderStyle = .roundedRect
        input.placeholder = "试着输入文字 · Type something"
        input.accessibilityIdentifier = "demo.business.input"
        input.returnKeyType = .done
        input.addAction(UIAction { [weak input] _ in input?.resignFirstResponder() }, for: .editingDidEndOnExit)
        input.heightAnchor.constraint(equalToConstant: 42).isActive = true
        content.addArrangedSubview(input)
        businessInput = input
        let waiting = DemoStyle.label("等待弹窗：尚未显示 · Waiting: queued", size: 12, color: .secondaryLabel)
        waiting.textAlignment = .center
        waiting.accessibilityIdentifier = "demo.business.queueState"
        content.addArrangedSubview(waiting)
        businessState = waiting
        content.addArrangedSubview(DemoStyle.button("显示 / 替换 Toast", symbol: "sparkles", id: "demo.business.show", primary: true) { [weak self] in
            guard let self else { return }
            self.toastCount += 1
            LSToast.show("第 \(self.toastCount) 条提示\n输入内容和业务弹窗继续保留", in: self.view, duration: 3)
        })
        content.addArrangedSubview(DemoStyle.button("显示长提示 · 8 秒", symbol: "text.bubble", id: "demo.business.long") { [weak self] in
            guard let self else { return }
            LSToast.show("试着点击下方的按钮。\nToast 上的文字区域也可以穿透点击。", in: self.view, duration: 8)
        })
        content.addArrangedSubview(DemoStyle.button("只隐藏 Toast", symbol: "eye.slash", id: "demo.business.hide") { [weak self] in
            guard let self else { return }
            LSToast.hide(in: self.view)
        })
        content.addArrangedSubview(DemoStyle.button("关闭业务 → 查看等待弹窗", symbol: "arrow.right", id: "demo.business.close") { [weak self] in
            self?.closeBusinessPopup()
        })
        card.addSubview(content)
        guard let popup = LSTPopView.initWithCustomView(card, parentView: view, popStyle: .scale, dismissStyle: .fade) else { return }
        popup.groupId = "demo.business"
        popup.priority = 100
        popup.bgAlpha = 0.30
        popup.isClickBgDismiss = false
        businessPopup = popup
        popup.pop()

        let queuedCard = UIView(frame: CGRect(x: 0, y: 0, width: width, height: 242))
        queuedCard.backgroundColor = .secondarySystemGroupedBackground
        queuedCard.layer.cornerRadius = 26
        queuedCard.accessibilityIdentifier = "demo.queued.card"
        let queuedContent = DemoStyle.stack(spacing: 15)
        queuedContent.frame = queuedCard.bounds.insetBy(dx: 22, dy: 24)
        queuedContent.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        let nextTitle = DemoStyle.label("轮到等待弹窗了", size: 22, weight: .bold)
        nextTitle.textAlignment = .center
        queuedContent.addArrangedSubview(nextTitle)
        let nextDescription = DemoStyle.label("The queue continues as expected.\n只有业务弹窗关闭后，我才会出现。\n显示和隐藏 Toast，都没有提前推进队列。", size: 14, color: .secondaryLabel)
        nextDescription.textAlignment = .center
        queuedContent.addArrangedSubview(nextDescription)
        queuedContent.addArrangedSubview(DemoStyle.button("完成 · Done", symbol: "checkmark", id: "demo.queued.close", primary: true) { [weak self] in
            self?.queuedPopup?.dismiss()
        })
        queuedCard.addSubview(queuedContent)
        if let queued = LSTPopView.initWithCustomView(queuedCard, parentView: view, popStyle: .scale, dismissStyle: .fade) {
            queued.groupId = "demo.business"
            queued.priority = 1
            queued.bgAlpha = 0.30
            queued.isClickBgDismiss = true
            queuedPopup = queued
            queued.popViewDidPopBlock = { [weak self] in
                self?.status.text = "业务弹窗关闭，等待弹窗正常接上 · Queue resumed"
            }
            queued.pop()
        }
        status.text = "业务弹窗显示中，等待弹窗尚未显示 · Popup active, next queued"
    }

    private func closeBusinessPopup() {
        // Resigning here is the business popup's own close action; toast actions
        // deliberately never end editing or alter its first responder.
        businessInput?.resignFirstResponder()
        businessPopup?.dismiss()
    }

    /// Reproducible, account-free sequence used to record the README preview.
    private func playDemo() {
        playback?.cancel()
        playback = Task { @MainActor [weak self] in
            func pause(_ seconds: Double) async -> Bool {
                do { try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000)); return !Task.isCancelled }
                catch { return false }
            }
            guard await pause(0.5), let self else { return }
            self.scrollView.setContentOffset(CGPoint(x: 0, y: -self.scrollView.adjustedContentInset.top), animated: true)
            self.show("轻提示，不打断。\nHello, LSToast!", duration: 1.8)
            guard await pause(2.5) else { return }
            self.show("顶部提示 · Top", duration: 1.5, position: .top)
            guard await pause(2.2) else { return }
            self.show("底部提示 · Bottom", duration: 1.5, position: .bottom)
            guard await pause(2.2) else { return }
            self.openBusinessPopup()
            self.businessInput?.text = "输入内容保留 · Hello"
            guard await pause(0.8) else { return }
            LSToast.show("Toast 与业务弹窗共存\nBusiness popup stays in place", in: self.view, duration: 8)
            guard await pause(2.8) else { return }
            LSToast.hide(in: self.view)
            self.businessState?.text = "Toast 已隐藏，业务弹窗仍在 · Popup stays"
            guard await pause(2) else { return }
            LSToast.show("只保留最新提示\nThe queue is still waiting", in: self.view, duration: 1.8, position: .top)
            guard await pause(2.4) else { return }
            self.closeBusinessPopup()
            guard await pause(2.5) else { return }
            self.queuedPopup?.dismiss()
            self.status.text = "演示完成 · Thanks for trying LSToast"
            self.playback = nil
        }
    }
}
