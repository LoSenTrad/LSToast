import UIKit

@MainActor
enum DemoStyle {
    static let accent = UIColor(red: 0.16, green: 0.34, blue: 0.94, alpha: 1)
    static let canvas = UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.06, green: 0.075, blue: 0.11, alpha: 1)
            : UIColor(red: 0.955, green: 0.965, blue: 0.985, alpha: 1)
    }
    static let softAccent = UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.13, green: 0.19, blue: 0.33, alpha: 1)
            : UIColor(red: 0.925, green: 0.945, blue: 1, alpha: 1)
    }

    static func label(_ text: String, size: CGFloat = 15, weight: UIFont.Weight = .regular,
                      color: UIColor = .label) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = UIFontMetrics.default.scaledFont(for: .systemFont(ofSize: size, weight: weight))
        label.adjustsFontForContentSizeCategory = true
        label.textColor = color
        label.numberOfLines = 0
        return label
    }

    static func button(_ title: String, symbol: String? = nil, id: String, primary: Bool = false,
                       action: @escaping @MainActor () -> Void) -> UIButton {
        var configuration = primary ? UIButton.Configuration.filled() : .tinted()
        configuration.title = title
        configuration.baseBackgroundColor = accent
        configuration.baseForegroundColor = primary ? .white : accent
        configuration.cornerStyle = .medium
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 13, bottom: 12, trailing: 13)
        configuration.imagePadding = 7
        if let symbol { configuration.image = UIImage(systemName: symbol) }
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { values in
            var values = values
            values.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
            return values
        }
        let button = UIButton(configuration: configuration, primaryAction: UIAction { _ in action() })
        button.accessibilityIdentifier = id
        button.titleLabel?.numberOfLines = 2
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        return button
    }

    static func row(_ views: UIView...) -> UIStackView {
        let stack = UIStackView(arrangedSubviews: views)
        stack.axis = .horizontal
        stack.spacing = 10
        stack.distribution = .fillEqually
        return stack
    }

    static func stack(spacing: CGFloat = 12) -> UIStackView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = spacing
        return stack
    }

    static func card(title: String, subtitle: String, content: UIStackView) -> UIView {
        let card = UIView()
        card.backgroundColor = .secondarySystemGroupedBackground
        card.layer.cornerRadius = 22
        let stack = Self.stack(spacing: 12)
        stack.addArrangedSubview(label(title, size: 19, weight: .bold))
        stack.addArrangedSubview(label(subtitle, size: 13, color: .secondaryLabel))
        stack.addArrangedSubview(content)
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18),
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 18),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -18)
        ])
        return card
    }
}
