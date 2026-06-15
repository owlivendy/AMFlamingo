import UIKit
import AMFlamingo

#if DEBUG

/// 故意持有泄漏对象，仅用于 Demo 验证。
private enum AMLeakDemoLeakBucket {
    static var retainedPoppedVC: UIViewController?
    static var retainedChildVC: UIViewController?
    static var orphanView: UIView?

    static func reset() {
        retainedPoppedVC = nil
        retainedChildVC = nil
        orphanView = nil
    }
}

/// AMLeakFinder 验证页：通过故意制造的泄漏，在 Xcode 控制台查看检测报告。
class AMLeakFinderDemoController: AMBaseController {

    private let infoLabel = UILabel(frame: .zero)
    private let stackView = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "AMLeakFinder 演示"
        view.backgroundColor = .systemBackground
        setupLeakFinder()
        setupUI()
    }

    private func setupLeakFinder() {
        AMLeakDemoLeakBucket.reset()
        AMLeakFinder.checkDelay = 1.5
//        AMLeakFinder.includedClassPrefixes = ["AMLeakDemo"]
        if !AMLeakFinder.isRunning {
            AMLeakFinder.start()
        }
    }

    private func setupUI() {
        infoLabel.numberOfLines = 0
        infoLabel.font = .systemFont(ofSize: 14)
        infoLabel.textColor = .secondaryLabel
        infoLabel.text = """
        仅 DEBUG 生效。进入子页面后返回，约 1.5 秒内在 Xcode 控制台搜索「监测到内存泄露」。

        测试前可先点「清除故意泄漏」避免旧样本干扰。
        """
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(infoLabel)

        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)

        addScenarioButton(
            title: "场景 1 · Pop 后 VC 未释放",
            subtitle: "子页 viewDidAppear 后静态强引用自身",
            action: #selector(showPoppedVCLeak)
        )
        addScenarioButton(
            title: "场景 2 · 子 VC 强引用泄漏",
            subtitle: "addChildViewController 后 pop，静态保留子 VC",
            action: #selector(showChildVCLeak)
        )
        addScenarioButton(
            title: "场景 3 · 孤立 View 泄漏",
            subtitle: "addSubview 追踪后移出并静态持有",
            action: #selector(showOrphanViewLeak)
        )
        addScenarioButton(
            title: "场景 4 · manualRegister 泄漏",
            subtitle: "Swift 私有属性 + registerChildViewController",
            action: #selector(showManualRegisterLeak)
        )
        addScenarioButton(
            title: "场景 5 · 仅 addSubview 子 view",
            subtitle: "superVC.addSubview(childVC.view)，pop 后静态保留子 VC",
            action: #selector(showAddSubviewOnlyLeak)
        )
        addScenarioButton(
            title: "清除故意泄漏",
            subtitle: nil,
            action: #selector(clearLeaks),
            isDestructive: true
        )

        NSLayoutConstraint.activate([
            infoLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            infoLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            infoLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            stackView.topAnchor.constraint(equalTo: infoLabel.bottomAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
        ])
    }

    private func addScenarioButton(
        title: String,
        subtitle: String?,
        action: Selector,
        isDestructive: Bool = false
    ) {
        var config = UIButton.Configuration.gray()
        config.title = title
        config.subtitle = subtitle
        config.titleAlignment = .leading
        config.imagePadding = 8
        config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
        if isDestructive {
            config.baseForegroundColor = .systemRed
        }

        let button = UIButton(configuration: config)
        button.contentHorizontalAlignment = .leading
        button.addTarget(self, action: action, for: .touchUpInside)
        stackView.addArrangedSubview(button)
    }

    @objc private func showPoppedVCLeak() {
        navigationController?.pushViewController(AMLeakDemoPoppedLeakController(), animated: true)
    }

    @objc private func showChildVCLeak() {
        navigationController?.pushViewController(AMLeakDemoParentLeakController(), animated: true)
    }

    @objc private func showOrphanViewLeak() {
        navigationController?.pushViewController(AMLeakDemoOrphanViewLeakController(), animated: true)
    }

    @objc private func showManualRegisterLeak() {
        navigationController?.pushViewController(AMLeakDemoManualRegisterLeakController(), animated: true)
    }

    @objc private func showAddSubviewOnlyLeak() {
        navigationController?.pushViewController(AMLeakDemoAddSubviewOnlyLeakController(), animated: true)
    }

    @objc private func clearLeaks() {
        AMLeakDemoLeakBucket.reset()
        let alert = UIAlertController(
            title: "已清除",
            message: "静态泄漏引用已置空。若对象仍被其他地方持有，需等待 ARC 回收。",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "好的", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - 场景 1

private final class AMLeakDemoPoppedLeakController: AMBaseController {

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Pop VC 泄漏"
        view.backgroundColor = .systemBackground
        installHint("""
        本页已在 viewDidAppear 中将自身存入静态变量。

        点击返回后等待约 1.5 秒，控制台应报告 AMLeakDemoPoppedLeakController 泄漏。
        """)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AMLeakDemoLeakBucket.retainedPoppedVC = self
    }
}

// MARK: - 场景 2

private final class AMLeakDemoChildLeakController: AMBaseController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemYellow.withAlphaComponent(0.2)
    }
}

private final class AMLeakDemoParentLeakController: AMBaseController {

    private let leakedChild = AMLeakDemoChildLeakController()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "子 VC 泄漏"
        view.backgroundColor = .systemBackground

        addChild(leakedChild)
        leakedChild.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(leakedChild.view)
        NSLayoutConstraint.activate([
            leakedChild.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            leakedChild.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            leakedChild.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            leakedChild.view.heightAnchor.constraint(equalToConstant: 120),
        ])
        leakedChild.didMove(toParent: self)

        installHint("""
        父页已通过 addChildViewController 挂载子 VC。

        返回（pop）时会将子 VC 存入静态变量；约 1.5 秒后控制台应报告 AMLeakDemoChildLeakController 泄漏，关联方式为 addChildViewController。
        """)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent {
            AMLeakDemoLeakBucket.retainedChildVC = leakedChild
        }
    }
}

// MARK: - 场景 3

private final class AMLeakDemoOrphanViewLeakController: AMBaseController {

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "孤立 View 泄漏"
        view.backgroundColor = .systemBackground
        installHint("""
        本页会 addSubview 一个 Label，随后移出层级并静态持有。

        返回后应报告孤立 UIView 未被释放。
        """)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard AMLeakDemoLeakBucket.orphanView == nil else { return }

        let orphan = UILabel(frame: CGRect(x: 20, y: 220, width: view.bounds.width - 40, height: 44))
        orphan.text = "AMLeakDemoOrphanLabel"
        orphan.textAlignment = .center
        orphan.backgroundColor = .systemOrange.withAlphaComponent(0.2)
        view.addSubview(orphan)

        DispatchQueue.main.async {
            orphan.removeFromSuperview()
            AMLeakDemoLeakBucket.orphanView = orphan
        }
    }
}

// MARK: - 场景 4

private final class AMLeakDemoManualRegisterLeakController: AMBaseController {

    /// private 属性不会被 ObjC Runtime 扫描到
    private let hiddenChild = AMLeakDemoChildLeakController()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "manualRegister"
        view.backgroundColor = .systemBackground
        _ = hiddenChild.view
        AMLeakFinder.registerChildViewController(hiddenChild, forParent: self)
        AMLeakDemoLeakBucket.retainedChildVC = hiddenChild
        installHint("""
        子 VC 为 private 属性，通过 registerChildViewController 登记。

        返回后应报告子 VC 泄漏，关联方式为 manualRegister。
        """)
    }
}

// MARK: - 场景 5

private final class AMLeakDemoAddSubviewOnlyLeakController: AMBaseController {

    private let leakedChild = AMLeakDemoChildLeakController()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "仅 addSubview"
        view.backgroundColor = .systemBackground

        leakedChild.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(leakedChild.view)
        NSLayoutConstraint.activate([
            leakedChild.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            leakedChild.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            leakedChild.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            leakedChild.view.heightAnchor.constraint(equalToConstant: 120),
        ])

        installHint("""
        父页仅执行 view.addSubview(childVC.view)，未调用 addChildViewController。

        返回（pop）时会静态保留子 VC；约 1.5 秒后控制台应报告子 VC 泄漏，常见关联方式为 inferredFromView 或 property。
        """)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent {
            AMLeakDemoLeakBucket.retainedChildVC = leakedChild
        }
    }
}

// MARK: - Helpers

private extension AMBaseController {
    func installHint(_ text: String) {
        let label = UILabel(frame: .zero)
        label.text = text
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 15)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
        ])
    }
}

#else

import UIKit
import AMFlamingo

class AMLeakFinderDemoController: AMBaseController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "AMLeakFinder 演示"
        view.backgroundColor = .systemBackground

        let label = UILabel(frame: .zero)
        label.text = "AMLeakFinder 仅在 DEBUG 构建中可用。"
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            label.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24),
        ])
    }
}

#endif
