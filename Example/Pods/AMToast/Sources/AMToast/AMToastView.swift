import UIKit

public class AMToastView: UIView {
    public var contentInsets: UIEdgeInsets = UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 15) {
        didSet {
            content_top?.constant = contentInsets.top
            content_bottom?.constant = contentInsets.bottom
            content_leading?.constant = contentInsets.left
            content_trailing?.constant = contentInsets.right
        }
    }
    private var content_top: NSLayoutConstraint?
    private var content_bottom: NSLayoutConstraint?
    private var content_leading: NSLayoutConstraint?
    private var content_trailing: NSLayoutConstraint?
    private var content_width: NSLayoutConstraint?
    private var content_height: NSLayoutConstraint?
    
    /// 自定义视图
    /// - 如果自定义视图满足以下条件，则不需要设置 frame：
    ///   1. 视图内部使用 AutoLayout 布局
    ///   2. 视图能够根据内容自适应大小
    /// - 如果自定义视图不满足上述条件，则需要设置 frame.size：
    ///   1. 设置 frame.width 来指定视图宽度
    ///   2. 设置 frame.height 来指定视图高度
    /// - 注意：即使设置了 frame.size，视图仍然会使用 AutoLayout 进行布局，frame.size 会被转换为对应的约束
    public var customView: UIView? {
        didSet {
            oldValue?.removeFromSuperview()
            if let customView = customView {
                addSubview(customView)
                customView.translatesAutoresizingMaskIntoConstraints = false
                
                // 设置位置约束
                content_top = customView.topAnchor.constraint(equalTo: self.topAnchor, constant: contentInsets.top)
                content_bottom = self.bottomAnchor.constraint(equalTo: customView.bottomAnchor, constant: contentInsets.bottom)
                content_leading = customView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: contentInsets.left)
                content_trailing = self.trailingAnchor.constraint(equalTo: customView.trailingAnchor, constant: contentInsets.right)
                
                var constraints = [
                    content_top!,
                    content_bottom!,
                    content_leading!,
                    content_trailing!
                ]
                
                // 如果设置了 frame.size，添加尺寸约束
                if customView.frame.width > 0 {
                    content_width = customView.widthAnchor.constraint(equalToConstant: customView.frame.width)
                    constraints.append(content_width!)
                }
                
                if customView.frame.height > 0 {
                    content_height = customView.heightAnchor.constraint(equalToConstant: customView.frame.height)
                    constraints.append(content_height!)
                }
                
                NSLayoutConstraint.activate(constraints)
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    func setupUI() {
        backgroundColor = AMToastConfig.ToastViewStyle.backgroundColor
        layer.cornerRadius = AMToastConfig.ToastViewStyle.cornerRadius
        clipsToBounds = true
    }
    
//    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
//        super.traitCollectionDidChange(previousTraitCollection)
//        
//        if #available(iOS 13.0, *) {
//            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
//                backgroundColor = AMToastConfig.ToastViewStyle.backgroundColor
//            }
//        }
//    }
} 
