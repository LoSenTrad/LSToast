import UIKit
import LSToast

/// Copy these calls into your own main-actor view controller.
@MainActor
final class ToastExamples: UIViewController {
    private var pendingMessage: LSToast.Handle?

    func basic() {
        LSToast.show("保存成功", in: view)
    }

    func customDurationAndPosition() {
        LSToast.show("操作已完成", in: view, duration: 3, position: .bottom)
    }

    func keepHandle() {
        pendingMessage = LSToast.show("这一次提示", in: view, duration: 5)
    }

    func dismissOnlyThatMessage() {
        pendingMessage?.hide() // A replacement remains visible.
        pendingMessage = nil
    }

    func dismissCurrentWindowToast() {
        LSToast.hide(in: view)
    }
}
