import UIKit

class AMDotLoadingView: UIView {
    enum ContentStyle {
        case light
        case dark
    }
    
    // 三个圆点视图
    private let dot1 = UIView()
    private let dot2 = UIView()
    private let dot3 = UIView()
    
    // 配置参数
    private let dotSize: CGSize = .init(width: 8, height: 8)
    private let dotSpacing: CGFloat = 5
    private let viewSize: CGSize = .init(width: 34, height: 8)
    private var baseColor: UIColor {
        get {
            if contentStyle == .light {
                return UIColor(red: 31/255.0, green: 35/255.0, blue: 41/255.0, alpha: 1.0)
            } else {
                return UIColor.white
            }
        }
    }
    private let animationCycle: TimeInterval = 0.9 // 0.3s * 3
    
    var contentStyle = ContentStyle.dark {
        didSet {
            //update background color
            dot1.backgroundColor = baseColor.withAlphaComponent(0.2)
            dot2.backgroundColor = baseColor.withAlphaComponent(0.5)
            dot3.backgroundColor = baseColor.withAlphaComponent(1.0)
            
            resetAnimation()
        }
    }
    
    override init(frame: CGRect) {
        // 强制使用固定尺寸，忽略传入的frame大小
        super.init(frame: CGRect(origin: frame.origin, size: viewSize))
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        // 强制设置固定尺寸
        self.bounds.size = viewSize
        setupViews()
    }
    
    func resetAnimation() {
        dot1.layer.removeAllAnimations()
        dot2.layer.removeAllAnimations()
        dot3.layer.removeAllAnimations()
        
        startAnimation()
    }
    
    private func setupViews() {
        backgroundColor = .clear
        clipsToBounds = true
        
        // 配置圆点通用属性
        [dot1, dot2, dot3].forEach { dot in
            dot.frame = CGRect(origin: .zero, size: dotSize)
            dot.layer.cornerRadius = dotSize.width / 2
            dot.clipsToBounds = true
            addSubview(dot)
        }
        
        // 计算每个圆点的X坐标（垂直居中）
        let dotY: CGFloat = (viewSize.height - dotSize.height) / 2
        dot1.frame.origin = .init(x: 0, y: dotY)
        dot2.frame.origin = .init(x: dot1.frame.maxX + dotSpacing, y: dotY)
        dot3.frame.origin = .init(x: dot2.frame.maxX + dotSpacing, y: dotY)
        
        // 初始透明度设置
        dot1.backgroundColor = baseColor.withAlphaComponent(0.2)
        dot2.backgroundColor = baseColor.withAlphaComponent(0.5)
        dot3.backgroundColor = baseColor.withAlphaComponent(1.0)
    }
    
    func startAnimation() {
        // 为每个圆点设置关键帧动画
        animateDot(dot: dot1, startIndex: 0)
        animateDot(dot: dot2, startIndex: 1)
        animateDot(dot: dot3, startIndex: 2)
    }
    
    // 为单个圆点设置动画（根据起始索引确定动画序列）
    private func animateDot(dot: UIView, startIndex: Int) {
        let animation = CAKeyframeAnimation(keyPath: "backgroundColor")
        animation.duration = animationCycle
        animation.repeatCount = .infinity
        animation.timingFunctions = [
            CAMediaTimingFunction(name: .easeInEaseOut),
            CAMediaTimingFunction(name: .easeInEaseOut),
            CAMediaTimingFunction(name: .easeInEaseOut)
        ]
        
        // 透明度序列：[0.2, 0.5, 1.0] 循环偏移
        let alphaValues: [CGFloat] = [0.2, 0.5, 1.0]
        animation.values = (0...3).map { i in
            let index = (startIndex + i) % 3
            return baseColor.withAlphaComponent(alphaValues[index]).cgColor
        }
        
        animation.keyTimes = [NSNumber(value: 0), NSNumber(value: 1/3.0), NSNumber(value: 2/3.0), NSNumber(value:1)]
        dot.layer.add(animation, forKey: "dotAnimation_\(startIndex)")
    }
}
