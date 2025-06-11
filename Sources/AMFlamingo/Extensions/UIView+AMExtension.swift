import UIKit

/// 流式布局配置类
public class AMFlowlayoutConfig {
    /// 最大宽度
    public var maxWidth: CGFloat
    /// 行高
    public var rowHeight: CGFloat
    /// 水平间距
    public var spacing: CGFloat
    /// 垂直间距
    public var verticalSpacing: CGFloat
    /// 行起始X坐标
    public var lineStartX: CGFloat
    
    /// 初始化流式布局配置
    /// - Parameter maxWidth: 最大宽度
    public init(maxWidth: CGFloat) {
        self.maxWidth = maxWidth
        self.rowHeight = 16
        self.spacing = 5
        self.verticalSpacing = 5
        self.lineStartX = 0
    }
}

public extension UIView {
    /// 计算流式布局所需的高度
    /// - Parameters:
    ///   - viewsToLayout: 需要布局的视图数组
    ///   - config: 布局配置
    /// - Returns: 布局所需的总高度
    static func heightForFlowHorizontalSubViews(_ viewsToLayout: [UIView], config: AMFlowlayoutConfig) -> CGFloat {
        return flowHorizontalSubViews(viewsToLayout, container: nil, config: config)
    }
    
    /// 执行流式布局
    /// - Parameters:
    ///   - viewsToLayout: 需要布局的视图数组
    ///   - container: 容器视图，如果为 nil 则只计算高度
    ///   - config: 布局配置
    /// - Returns: 布局所需的总高度
    static func flowHorizontalSubViews(_ viewsToLayout: [UIView], container: UIView?, config: AMFlowlayoutConfig) -> CGFloat {
        if viewsToLayout.isEmpty { return 0 }
        
        let needLayout = container != nil
        
        // 布局 container 内部的子视图
        var previousView: UIView? = nil // 在 container 内部布局，第一个视图相对于其左侧
        let rowHeight = config.rowHeight //固定行高
        let spacing = config.spacing // 视图之间的水平间距
        let verticalSpacing = config.verticalSpacing // 行之间的垂直间距
        let lineStartX = config.lineStartX // 当前行的起始 X 坐标
        var currentX: CGFloat = 0 // 相对于 container 的 x 坐标
        var currentLineY: CGFloat = 0 // 当前行的布局的 Y 坐标
        var currentMaxY = rowHeight + verticalSpacing // 当前行的最大 Y 坐标
        
        let maxwidth = config.maxWidth
        
        for currentView in viewsToLayout {
            if currentView.isHidden { continue } // 如果视图隐藏则跳过布局
            if needLayout {
                container?.addSubview(currentView)
            }
            
            let viewSize = currentView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
            let requiredWidth = viewSize.width
            
            // 判断是否需要换行
            if currentX + requiredWidth > maxwidth && currentX > 0 {
                // 换行
                currentX = lineStartX // 回到行的起始 X 坐标
                currentLineY += verticalSpacing + rowHeight // 增加垂直间距
                previousView = nil // 换行后相对于 container 的左边布局
                currentMaxY += rowHeight + verticalSpacing
            } else if previousView != nil {
                currentX += spacing // 不是第一个视图，增加水平间距
            }
            
            // 设置当前视图的约束
            if needLayout {
                currentView.snp.makeConstraints { make in
                    if let previousView = previousView {
                        make.left.equalTo(previousView.snp.right).offset(spacing)
                        make.centerY.equalTo(previousView)
                    } else {
                        make.top.equalTo(container!.snp.top).offset(currentLineY) // 相对于 container 顶部
                        make.left.equalTo(container!.snp.left).offset(lineStartX) // 相对于 container 左侧
                    }
                    //高度，宽度由内容决定
                }
            }
            // 更新当前 X 坐标和前一个视图
            currentX += requiredWidth
            previousView = currentView
        }
        
        // 计算 container 的总高度
        let totalHeight = currentMaxY - verticalSpacing // 最后一行的高度就是总高度
        return totalHeight
    }
    
    /// 在当前视图中执行流式布局
    /// - Parameters:
    ///   - viewsToLayout: 需要布局的视图数组
    ///   - config: 布局配置
    /// - Returns: 布局所需的总高度
    func flowHorizontalSubViews(_ viewsToLayout: [UIView], config: AMFlowlayoutConfig) -> CGFloat {
        return UIView.flowHorizontalSubViews(viewsToLayout, container: self, config: config)
    }
}

public extension UIView {
    /// 从 Nib 加载单个视图
    /// - Returns: 加载的视图，如果加载失败则返回 nil
    static func viewFromNib() -> UIView? {
        return viewsFromNib().first
    }
    
    /// 从 Nib 加载多个视图
    /// - Returns: 加载的视图数组
    static func viewsFromNib() -> [UIView] {
        let className = String(describing: self)
        return Bundle.main.loadNibNamed(className, owner: nil, options: nil) as? [UIView] ?? []
    }
    
    /// 从指定的 Bundle 和 Nib 名称加载视图
    /// - Parameters:
    ///   - bundle: Bundle 对象
    ///   - nibName: Nib 名称
    ///   - owner: 所有者对象
    /// - Returns: 加载的视图数组
    static func viewsFromNib(bundle: Bundle, nibName: String, owner: Any?) -> [UIView] {
        return bundle.loadNibNamed(nibName, owner: owner, options: nil) as? [UIView] ?? []
    }
} 