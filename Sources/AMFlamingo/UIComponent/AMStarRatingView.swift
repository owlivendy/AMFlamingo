//
//  AMStarRatingView.swift
//  ChinaHomelife247
//
//  Created by Codex on 2026/4/20.
//

import UIKit
import SnapKit

/// 星级评分视图
/// - 支持只读和编辑两种模式
/// - 支持自定义星星数量、间距、选中/未选中图片
/// - 分数默认按 1 颗星 = 1 分计算
class AMStarRatingView: UIView {
    /// 评分变更回调，返回当前分数
    typealias ScoreChangedBlock = (_ score: Int) -> Void

    /// 星星总数，最少为 1，默认 5 颗
    var starCount: Int = 5 {
        didSet {
            let validCount = max(1, starCount)
            if validCount != starCount {
                starCount = validCount
                return
            }
            rebuildStarButtons()
            setScore(score)
        }
    }

    /// 星星之间的间距，默认 6
    var starSpacing: CGFloat = 6 {
        didSet {
            stackView.spacing = starSpacing
            invalidateIntrinsicContentSize()
        }
    }

    /// 选中状态的图片名称，要求初始化时传入
    let selectedImageName: String

    /// 未选中状态的图片名称，要求初始化时传入
    let unselectedImageName: String

    /// 是否允许点击编辑，默认可编辑
    var isEditable: Bool = true {
        didSet {
            updateInteractionState()
        }
    }

    /// 每颗星对应的分值，默认 1 颗星 = 1 分
    var scorePerStar: Int = 1 {
        didSet {
            if scorePerStar < 1 {
                scorePerStar = 1
                return
            }
            setScore(score)
            refreshStarDisplay()
        }
    }

    /// 评分结果回调
    /// 返回值按“选中星星数量 * scorePerStar”计算
    /// 例如选中 3 颗星且 scorePerStar = 2 时，回调分数为 6
    var scoreChangedBlock: ScoreChangedBlock?

    /// 当前分数，外部只读，通过方法或点击修改
    private(set) var score: Int = 0 {
        didSet {
            refreshStarDisplay()
        }
    }

    /// 横向承载所有星星按钮
    private let stackView = UIStackView()
    /// 内部所有星星按钮集合
    private var starButtons: [UIButton] = []
    /// 单颗星的默认参考尺寸，用于 intrinsicContentSize，外部可修改
    var defaultStarSize: CGFloat = 24 {
        didSet {
            if defaultStarSize <= 0 {
                defaultStarSize = 24
                return
            }
            invalidateIntrinsicContentSize()
            setNeedsLayout()
        }
    }

    /// 指定图片和编辑状态初始化
    /// - Parameters:
    ///   - selectedImageName: 选中状态图片名称，必传
    ///   - unselectedImageName: 未选中状态图片名称，必传
    ///   - isEditable: 是否可编辑，默认 true
    init(selectedImageName: String, unselectedImageName: String, isEditable: Bool = true) {
        self.selectedImageName = selectedImageName
        self.unselectedImageName = unselectedImageName
        self.isEditable = isEditable
        super.init(frame: .zero)
        commonInit()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented. Use init(selectedImageName:unselectedImageName:isEditable:)")
    }

    override var intrinsicContentSize: CGSize {
        let width = CGFloat(starCount) * defaultStarSize + CGFloat(max(0, starCount - 1)) * starSpacing
        return CGSize(width: width, height: defaultStarSize)
    }

    /// 直接设置总分
    /// - Parameters:
    ///   - score: 目标分数，会自动限制在 0 ~ starCount * scorePerStar 之间
    ///   - triggerCallback: 是否触发评分回调
    func setScore(_ score: Int, triggerCallback: Bool = false) {
        let maxScore = starCount * scorePerStar
        let minScore = 0
        let validScore = min(max(score, minScore), maxScore)

        guard self.score != validScore else {
            if triggerCallback {
                scoreChangedBlock?(validScore)
            }
            return
        }

        self.score = validScore

        if triggerCallback {
            scoreChangedBlock?(validScore)
        }
    }

    /// 通过选中星星数量设置分数
    /// - Parameters:
    ///   - selectedStars: 选中的星星数量
    ///   - triggerCallback: 是否触发评分回调
    func setSelectedStars(_ selectedStars: Int, triggerCallback: Bool = false) {
        setScore(selectedStars * scorePerStar, triggerCallback: triggerCallback)
    }

    private func commonInit() {
        setupViews()
        rebuildStarButtons()
    }

    private func setupViews() {
        addSubview(stackView)
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = starSpacing

        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    /// 根据当前星数重新创建按钮
    /// 按钮宽高保持一致，最终会随着外部高度约束自动缩放
    private func rebuildStarButtons() {
        starButtons.forEach { button in
            stackView.removeArrangedSubview(button)
            button.removeFromSuperview()
        }
        starButtons.removeAll()

        for index in 0..<starCount {
            let button = UIButton(type: .custom)
            button.tag = index + 1
            button.imageView?.contentMode = .scaleAspectFit
            button.addTarget(self, action: #selector(handleStarTap(_:)), for: .touchUpInside)

            stackView.addArrangedSubview(button)
            button.snp.makeConstraints { make in
                make.width.equalTo(button.snp.height)
            }

            starButtons.append(button)
        }

        updateInteractionState()
        refreshStarDisplay()
        invalidateIntrinsicContentSize()
        setNeedsLayout()
    }

    /// 根据编辑状态统一更新按钮交互能力
    private func updateInteractionState() {
        starButtons.forEach { button in
            button.isUserInteractionEnabled = isEditable
        }
    }

    /// 按当前分数刷新每颗星的显示状态
    private func refreshStarDisplay() {
        let selectedCount = scorePerStar > 0 ? min(starCount, score / scorePerStar) : 0

        for (index, button) in starButtons.enumerated() {
            let isSelected = index < selectedCount
            let imageName = isSelected ? selectedImageName : unselectedImageName
            let image = UIImage(named: imageName)
            button.setImage(image, for: .normal)
        }
    }

    /// 编辑模式下点击某颗星后，直接完成评分并回调
    @objc private func handleStarTap(_ sender: UIButton) {
        guard isEditable else { return }
        setSelectedStars(sender.tag, triggerCallback: true)
    }
}
