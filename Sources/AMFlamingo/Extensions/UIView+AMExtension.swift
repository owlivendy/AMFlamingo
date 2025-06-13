import UIKit
import SnapKit

/// 流式布局配置类
public class AMFlowlayoutConfig {
    /// 最大宽度
    public var maxWidth: CGFloat
    /// 水平间距
    public var spacing: CGFloat
    /// 垂直间距
    public var verticalSpacing: CGFloat
    /// 内边距
    public var padding: UIEdgeInsets
    /// 每行显示的视图数量，默认为0表示自适应，大于0时表示固定数量
    public var itemsPerRow: Int
    
    /// 初始化流式布局配置
    /// - Parameter maxWidth: 最大宽度
    public init(maxWidth: CGFloat) {
        self.maxWidth = maxWidth
        self.spacing = 5
        self.verticalSpacing = 5
        self.padding = .zero
        self.itemsPerRow = 0
    }
}

public extension UIView {
    /// 计算流式布局所需的高度
    /// - Parameters:
    ///   - viewsToLayout: 需要布局的视图数组。数组中的每个视图必须能够通过 systemLayoutSizeFitting 方法计算出其内容大小。
    ///                    建议使用 UILabel、UIButton 等支持内容自适应的视图，或者自定义视图时实现合适的约束。
    ///                    如果视图没有正确设置约束，可能会导致布局计算错误。
    ///   - config: 布局配置
    /// - Returns: 布局所需的总高度
    static func heightForFlowHorizontalSubViews(_ viewsToLayout: [UIView], config: AMFlowlayoutConfig) -> CGFloat {
        return flowHorizontalSubViews(viewsToLayout, container: nil, config: config)
    }
    
    /// 执行流式布局
    /// - Parameters:
    ///   - viewsToLayout: 需要布局的视图数组。数组中的每个视图必须能够通过 systemLayoutSizeFitting 方法计算出其内容大小。
    ///                    建议使用 UILabel、UIButton 等支持内容自适应的视图，或者自定义视图时实现合适的约束。
    ///                    如果视图没有正确设置约束，可能会导致布局计算错误。
    ///   - container: 容器视图，如果为 nil 则只计算高度
    ///   - config: 布局配置
    /// - Returns: 布局所需的总高度
    static func flowHorizontalSubViews(_ viewsToLayout: [UIView], container: UIView?, config: AMFlowlayoutConfig) -> CGFloat {
        if viewsToLayout.isEmpty { return 0 }
        
        let needLayout = container != nil
        
        // 布局 container 内部的子视图
        var previousView: UIView? = nil // 在 container 内部布局，第一个视图相对于其左侧
        var rowHeight: CGFloat = 0 //固定行高
        let spacing = config.spacing // 视图之间的水平间距
        let verticalSpacing = config.verticalSpacing // 行之间的垂直间距
        var currentX: CGFloat = config.padding.left // 相对于 container 的 x 坐标
        var currentLineY: CGFloat = config.padding.top // 当前行的布局的 Y 坐标
        var currentMaxY: CGFloat = config.padding.top // 当前行的最大 Y 坐标
        
        let maxwidth = config.maxWidth
        
        // 计算固定宽度（如果设置了每行数量）
        let fixedItemWidth: CGFloat?
        if config.itemsPerRow > 0 {
            let availableWidth = maxwidth - config.padding.left - config.padding.right
            let totalSpacing = CGFloat(config.itemsPerRow - 1) * config.spacing
            fixedItemWidth = (availableWidth - totalSpacing) / CGFloat(config.itemsPerRow)
        } else {
            fixedItemWidth = nil
        }
        
        for (index, currentView) in viewsToLayout.enumerated() {
            if currentView.isHidden { continue } // 如果视图隐藏则跳过布局
            if needLayout {
                container?.addSubview(currentView)
            }
            
            let viewSize = currentView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
            let requiredWidth = fixedItemWidth ?? viewSize.width
            
            if (index == 0) {
                rowHeight = viewSize.height
                currentMaxY += rowHeight + verticalSpacing
            }
            
            // 判断是否需要换行
            let shouldWrap = config.itemsPerRow > 0 ? 
                (index > 0 && index % config.itemsPerRow == 0) : // 固定数量时，根据索引判断
                (currentX + requiredWidth + config.padding.right > maxwidth && currentX > config.padding.left) // 自适应时，根据宽度判断
            
            if shouldWrap {
                // 换行
                rowHeight = viewSize.height
                currentX = config.padding.left // 回到行的起始 X 坐标
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
                        make.left.equalTo(container!.snp.left).offset(config.padding.left) // 相对于 container 左侧
                    }
                    
                    // 如果设置了固定宽度，添加宽度约束
                    if let fixedWidth = fixedItemWidth {
                        make.width.equalTo(fixedWidth)
                    }
                }
            }
            // 更新当前 X 坐标和前一个视图
            currentX += requiredWidth
            previousView = currentView
        }
        
        // 计算 container 的总高度
        let totalHeight = currentMaxY - verticalSpacing + config.padding.bottom // 最后一行的高度就是总高度
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
