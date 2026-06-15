import UIKit
import AMFlamingo

class AMPopoverDemoController: AMBaseController {

    private let stackView = UIStackView()
    private var menuAnchorButton: UIButton!
    private var tipAnchorButton: UIButton!
    private var passthroughAnchorButton: UIButton!

    private weak var activePopover: AMPopoverView?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "AMPopoverView 演示"
        view.backgroundColor = .systemBackground
        setupButtons()
    }

    private func setupButtons() {
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.alignment = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)

        menuAnchorButton = makeAnchorButton(title: "菜单气泡 · 点此弹出", color: .systemBlue)
        menuAnchorButton.addTarget(self, action: #selector(showMenuPopover), for: .touchUpInside)

        tipAnchorButton = makeAnchorButton(title: "提示气泡 · 点此弹出", color: .systemGreen)
        tipAnchorButton.addTarget(self, action: #selector(showTipPopover), for: .touchUpInside)

        passthroughAnchorButton = makeAnchorButton(title: "穿透模式 · 点此弹出", color: .systemOrange)
        passthroughAnchorButton.addTarget(self, action: #selector(showPassthroughPopover), for: .touchUpInside)

        stackView.addArrangedSubview(menuAnchorButton)
        stackView.addArrangedSubview(tipAnchorButton)
        stackView.addArrangedSubview(passthroughAnchorButton)

        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24),
        ])
    }

    private func makeAnchorButton(title: String, color: UIColor) -> UIButton {
        var config = UIButton.Configuration.plain()
        config.title = title
        config.baseForegroundColor = color
        config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
        config.background.backgroundColor = color.withAlphaComponent(0.12)
        config.background.cornerRadius = 8
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attrs in
            var updated = attrs
            updated.font = .systemFont(ofSize: 16, weight: .medium)
            return updated
        }

        let button = UIButton(configuration: config)
        button.heightAnchor.constraint(equalToConstant: 48).isActive = true
        return button
    }

    // MARK: - Demos

    @objc private func showMenuPopover() {
        activePopover?.hide()

        let items = [
            AMPopoverMenuItem.item(withTitle: "复制") { print("复制") },
            AMPopoverMenuItem.item(withTitle: "转发") { print("转发") },
            AMPopoverMenuItem.item(withTitle: "删除") { print("删除") },
        ]

        let menu = AMPopoverMenuView(menuItems: items)
        menu.menuWidth = 120
        menu.show(anchorView: menuAnchorButton)
    }

    @objc private func showTipPopover() {
        activePopover?.hide()

        let label = UILabel(frame: .zero)
        label.text = "这是一段提示文字\n支持多行展示"
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 14)
        label.textColor = .label
        label.textAlignment = .center
        let maxWidth: CGFloat = 196
        let textSize = label.sizeThatFits(CGSize(width: maxWidth, height: .greatestFiniteMagnitude))
        label.frame = CGRect(x: 12, y: 10, width: maxWidth, height: textSize.height)

        let container = UIView(frame: CGRect(x: 0, y: 0, width: maxWidth + 24, height: textSize.height + 20))
        container.addSubview(label)

        let popover = AMPopoverView(contentView: container)
        popover.placementPriority = .above
        popover.bubbleFillColor = .systemBackground
        popover.show(anchorView: tipAnchorButton)
        activePopover = popover
    }

    @objc private func showPassthroughPopover() {
        activePopover?.hide()

        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 60))
        label.text = "外部点击可穿透\n下方按钮仍可点"
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 13)
        label.textAlignment = .center

        let popover = AMPopoverView(contentView: label)
        popover.allowsBackgroundTapPassthrough = true
        popover.dismissOnBackgroundTap = true
        popover.backgroundTapHandler = { pop in
            print("点击了气泡外部")
            pop.hide()
        }
        popover.show(anchorView: passthroughAnchorButton)
        activePopover = popover
    }
}
