//
//  AMMarkdownView.swift
//  Flamingo
//
//  Created by xiaofei shen on 2025/8/30.
//

import UIKit
import Markdown

public struct AMMarkdownViewStyle {
    // MARK: - Table style
    /// 表格斑马纹：偶数行背景色（不含表头）
    public var tableRowEvenBackgroundColor: UIColor = .white
    /// 表格斑马纹：奇数行背景色（不含表头）
    public var tableRowOddBackgroundColor: UIColor = UIColor.hex(string: "#FFF7F4")
    /// 表头背景色
    public var tableHeaderBackgroundColor: UIColor = .systemGray6
    /// 表头字体（会覆盖表头单元格内部 attributedText 的 font）
    public var tableHeaderFont: UIFont = .systemFont(ofSize: 16, weight: .semibold)

    // MARK: - paragrah style
    /// 通用段落样式：正文、标题、表格文本等未单独覆盖时都会继承该样式。
    public var paragrahStyle: NSParagraphStyle
    /// 列表段落样式
    public var listParagrahStyle: NSParagraphStyle
    /// 块级元素（段落、标题、列表、表格）之间的垂直间距；建议为行间距的 1.5~2 倍。
    public var blockSpacing: CGFloat = 16

    // MARK: font
    /// 正文基础字体：普通文本、列表文本、表格内容等默认使用该字体。
    public var baseFont: UIFont = .systemFont(ofSize: 16)
    /// 代码字体：代码块与内联代码优先使用等宽字体，便于对齐与阅读。
    public var codeFont: UIFont = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)

    // MARK: - BlockQuote style
    /// BlockQuote 背景色
    public var blockQuoteBackgroundColor: UIColor = UIColor.systemGray6
    /// BlockQuote 左侧竖线颜色
    public var blockQuoteBarColor: UIColor = UIColor.systemGray3
    /// BlockQuote 左侧竖线宽度
    public var blockQuoteBarWidth: CGFloat = 3
    /// BlockQuote 内边距（背景容器内 padding）
    public var blockQuoteContentInset: UIEdgeInsets = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)
    /// BlockQuote 圆角
    public var blockQuoteCornerRadius: CGFloat = 8
    /// BlockQuote 竖线与正文间距
    public var blockQuoteBarSpacing: CGFloat = 10

    public var isDebug: Bool = false

    public static var `default`: AMMarkdownViewStyle = AMMarkdownViewStyle()

    public init() {
        let _paragrahstyle = NSMutableParagraphStyle()
        _paragrahstyle.lineSpacing = 4
        _paragrahstyle.paragraphSpacing = 8
        paragrahStyle = _paragrahstyle
        
        let _listParagrahstyle = NSMutableParagraphStyle()
        _listParagrahstyle.lineSpacing = 4
        _listParagrahstyle.paragraphSpacing = 4
        _listParagrahstyle.firstLineHeadIndent = 14
        _listParagrahstyle.headIndent = 24
        listParagrahStyle = _listParagrahstyle
    }
}

/// 主视图：用于渲染 Markdown Document（不使用 UIStackView 版本）
public class AMMarkdownView: UIView {
    private let container = UIView() // 用于承载所有子元素的容器
    private var lastSubview: UIView? // 记录上一个添加的子视图，用于约束布局
    private var reuseTextView = [UITextView]()
    private var renderedDocument: Markdown.Document?
    private var lastRenderedWidth: CGFloat = 0

    /// 渲染样式配置（初始化后不可变）
    public let markdownStyle: AMMarkdownViewStyle

    /// 链接点击回调
    public var onLinkTapped: ((URL) -> Void)?

    public convenience init(markdownStyle: AMMarkdownViewStyle = .default) {
        self.init(frame: .zero, markdownStyle: markdownStyle)
    }

    public init(frame: CGRect, markdownStyle: AMMarkdownViewStyle = .default) {
        self.markdownStyle = markdownStyle
        super.init(frame: frame)
        setupContainer()
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        reloadContentIfNeeded()
    }

    /// 使用已解析的 `Document` 更新内容（需 `import Markdown`）
    public func update(document: Markdown.Document?) {
        renderedDocument = document
        lastRenderedWidth = 0
        clearRenderedContent()
        reloadContentIfNeeded()
    }

    /// 使用 Markdown 字符串更新内容
    public func update(markdown: String) {
        update(document: Document(parsing: markdown))
    }

    /// 预处理 Markdown 后更新（ASCII 表格转 GFM、可选 optimize）
    public func update(
        markdown: String,
        convertAsciiTables: Bool = false,
        optimize: Bool = false
    ) {
        var source = markdown
        if convertAsciiTables {
            source = MarkDownOptimizer.convertAsciiTablesToMarkdown(source)
        }
        if optimize {
            source = MarkDownOptimizer.optimizeMarkdown(source)
        }
        update(markdown: source)
    }

    private func clearRenderedContent() {
        lastSubview = nil
        container.subviews.forEach { v in
            if let tv = v as? UITextView {
                reuseTextView.append(tv)
            }
            v.removeFromSuperview()
        }
    }

    private func reloadContentIfNeeded() {
        guard let document = renderedDocument, bounds.width > 0 else { return }
        guard abs(bounds.width - lastRenderedWidth) > 0.5 else { return }
        lastRenderedWidth = bounds.width
        clearRenderedContent()
        render(document)
    }

    private func setupContainer() {
        addSubview(container)
        container.translatesAutoresizingMaskIntoConstraints = false
        // 容器边缘与自身对齐
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topAnchor),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    @objc func onLinkLabelPress(sender: UITapGestureRecognizer) {
        guard let accessibilityIdentifier = sender.view?.accessibilityIdentifier else {return}
        guard let linkUrl = URL.init(string: accessibilityIdentifier) else {return}
        print("\(linkUrl)")
        onLinkTapped?(linkUrl)
    }
    
    // MARK: - 渲染入口
    private func render(_ document: Markdown.Document) {
        let width = bounds.width
        if markdownStyle.isDebug {
            print("[AMMarkdownView] document: \(document.debugDescription())")
        }
        
        let pendingText = NSMutableAttributedString()
        
        func appendBlockSpacingIfNeeded() {
            guard pendingText.length > 0 else { return }
            // 注意：这里不要用 "\n\n"。我们已经通过 paragraphStyle 的 lineSpacing/paragraphSpacing 控制段落间距；
            // 额外插入空行会让“行与行之间看起来多一行”。
            pendingText.append(NSAttributedString(string: "\n"))
        }
        
        func appendCommonParagraphStyle(_ attr: NSMutableAttributedString) {
            guard attr.length > 0 else { return }
            attr.addAttribute(.paragraphStyle, value: markdownStyle.paragrahStyle, range: NSRange(location: 0, length: attr.length))
        }
        
        func flushPendingTextIfNeeded() {
            guard pendingText.length > 0 else { return }
            let tv = makeTextView(attribute: pendingText, width: width)
            addSubviewToContainer(tv)
            pendingText.setAttributedString(NSAttributedString())
        }
        
        func appendBlockQuote(_ quote: BlockQuote) {
            flushPendingTextIfNeeded()
            let view = makeBlockQuoteView(quote: quote, width: width)
            addSubviewToContainer(view)
        }
        
        func appendParagraph(_ para: Paragraph) {
            appendBlockSpacingIfNeeded()
            let attr = NSMutableAttributedString(attributedString: AMMarkdownView.attributedText(for: para, baseFont: markdownStyle.baseFont))
            appendCommonParagraphStyle(attr)
            pendingText.append(attr)
        }
        
        func appendHeading(_ heading: Heading) {
            appendBlockSpacingIfNeeded()
            let font = UIFont.boldSystemFont(ofSize: CGFloat(22 - heading.level * 2))
            let attr = NSMutableAttributedString(attributedString: AMMarkdownView.attributedText(for: heading, baseFont: font))
            appendCommonParagraphStyle(attr)
            pendingText.append(attr)
        }
        
        func appendCodeBlock(_ code: CodeBlock) {
            appendBlockSpacingIfNeeded()
            let attr = NSMutableAttributedString(string: code.code, attributes: [
                .font: markdownStyle.codeFont,
                .foregroundColor: UIColor.darkText
            ])
            appendCommonParagraphStyle(attr)
            pendingText.append(attr)
        }
        
        func appendList(_ list: ListItemContainer, ordered: Bool) {
            appendBlockSpacingIfNeeded()
            let items = Array(list.listItems)
            for (idx, item) in items.enumerated() {
                let bullet = ordered ? "\(idx+1). " : "• "
                let lines = AMMarkdownView.attributedTextForListItem(for: item, baseFont: markdownStyle.baseFont)
                for (jdx, line) in lines.enumerated() {
                    let dealt: NSMutableAttributedString
                    if jdx == 0 {
                        dealt = AMMarkdownView.manipulateListItemAttribute(attribute: line, bullet: bullet, markdownStyle: markdownStyle)
                    } else {
                        dealt = AMMarkdownView.manipulateListItemAttribute(attribute: line, markdownStyle: markdownStyle)
                    }
                    pendingText.append(dealt)
                    if jdx != lines.count - 1 {
                        pendingText.append(NSAttributedString(string: "\n"))
                    }
                }
                // 列表 item 之间只加一个换行，避免尾部多余空行
                if idx != items.count - 1 {
                    pendingText.append(NSAttributedString(string: "\n"))
                }
            }
        }
        
        var previousElementIsList = false
        for block in document.children {
            if previousElementIsList {
                previousElementIsList = false
                appendBlockSpacingIfNeeded()
            }
            
            switch block {
            case let para as Paragraph:
                appendParagraph(para)
                
            case let heading as Heading:
                appendHeading(heading)
                
            case let code as CodeBlock:
                appendCodeBlock(code)
                
            case let list as UnorderedList:
                previousElementIsList = true
                appendList(list, ordered: false)
                
            case let list as OrderedList:
                previousElementIsList = true
                appendList(list, ordered: true)
                
            case let quote as BlockQuote:
                appendBlockQuote(quote)
                
            case let table as Table:
                flushPendingTextIfNeeded()
                let tableView = makeTableView(table: table)
                addSubviewToContainer(tableView)
                
            default:
                break
            }
        }
        
        flushPendingTextIfNeeded()
    }

    // 向容器添加子视图并设置布局约束
    private func addSubviewToContainer(_ subview: UIView) {
        container.addSubview(subview)
        subview.translatesAutoresizingMaskIntoConstraints = false
        
        // 水平方向与容器对齐
        let leading = subview.leadingAnchor.constraint(equalTo: container.leadingAnchor)
        let trailing = subview.trailingAnchor.constraint(equalTo: container.trailingAnchor)
        
        // 垂直方向与上一个视图对齐（或容器顶部）
        let top: NSLayoutConstraint
        if let last = lastSubview {
            top = subview.topAnchor.constraint(equalTo: last.bottomAnchor, constant: markdownStyle.blockSpacing)
        } else {
            top = subview.topAnchor.constraint(equalTo: container.topAnchor)
        }
        
        NSLayoutConstraint.activate([leading, trailing, top])
        lastSubview = subview
    }
    
    private func makeTextView(attribute: NSAttributedString, width: CGFloat) -> UITextView {
        let textView: UITextView
        
        if let tv = self.reuseTextView.popLast() {
            textView = tv
        } else {
            textView = UITextView()
            textView.backgroundColor = .clear
            textView.isEditable = false
            textView.isSelectable = true
            textView.isScrollEnabled = false
            textView.textContainerInset = .zero
            textView.textContainer.lineFragmentPadding = 0
            textView.delegate = self
            textView.dataDetectorTypes = []
        }
        
        textView.attributedText = attribute
        
        return textView
    }
    
    private func makeBlockQuoteView(quote: BlockQuote, width: CGFloat) -> UIView {
        let attr = NSMutableAttributedString(attributedString: AMMarkdownView.attributedText(for: quote, baseFont: markdownStyle.baseFont))
        if attr.length > 0 {
            attr.addAttribute(.paragraphStyle, value: markdownStyle.paragrahStyle, range: NSRange(location: 0, length: attr.length))
        }
        
        let view = AMMarkdownBlockQuoteView(frame: .zero, style: markdownStyle)
        view.configure(text: attr, width: width, delegate: self)
        return view
    }

    // MARK: - 表格渲染（保持原有逻辑，改为直接添加子视图）
    private func makeTableView(table: Table) -> UIView {
        let availableWidth = bounds.width
        let headCells = Array(table.head.cells)
        let colCount = max(headCells.count, 1)
        
        let layout = Self.computeTableLayout(
            table: table,
            availableWidth: availableWidth,
            markdownStyle: markdownStyle
        )
        
        // 横向滚动容器
        let scroll = UIScrollView()
        scroll.showsHorizontalScrollIndicator = true
        scroll.showsVerticalScrollIndicator = false
        scroll.alwaysBounceHorizontal = layout.totalWidth > availableWidth
        scroll.bounces = true
        scroll.isDirectionalLockEnabled = true
        
        let container = UIView()
        scroll.addSubview(container)
        
        scroll.translatesAutoresizingMaskIntoConstraints = false
        container.translatesAutoresizingMaskIntoConstraints = false
        
        // 让 scroll 的内容宽度等于表格总宽（> availableWidth 时可横滑）
        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor),
            container.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
            container.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
            container.heightAnchor.constraint(equalTo: scroll.frameLayoutGuide.heightAnchor),
            container.widthAnchor.constraint(equalToConstant: layout.totalWidth)
        ])
        
        var lastRowView: UIView?
        
        // 表头
        let headerRow = makeTableRow(
            headCells,
            colCount: colCount,
            colWidths: layout.colWidths,
            isHeader: true,
            rowIndex: 0
        )
        container.addSubview(headerRow)
        headerRow.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            headerRow.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            headerRow.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            headerRow.topAnchor.constraint(equalTo: container.topAnchor)
        ])
        lastRowView = headerRow
        
        // 表体（斑马纹按行）
        var bodyIndex = 0
        for row in table.body.rows {
            bodyIndex += 1
            let cells = Array(row.cells)
            let rowView = makeTableRow(
                cells,
                colCount: colCount,
                colWidths: layout.colWidths,
                isHeader: false,
                rowIndex: bodyIndex
            )
            container.addSubview(rowView)
            rowView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                rowView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                rowView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                rowView.topAnchor.constraint(equalTo: lastRowView!.bottomAnchor)
            ])
            lastRowView = rowView
        }
        
        if let last = lastRowView {
            last.bottomAnchor.constraint(equalTo: container.bottomAnchor).isActive = true
        } else {
            container.heightAnchor.constraint(equalToConstant: 0).isActive = true
        }
        
        // 外层返回 scroll（由 AMMarkdownView 负责放进 container）
        return scroll
    }
    
    // 辅助方法：渲染单行 TableRow
    private func makeTableRow(
        _ cells: [Table.Cell],
        colCount: Int,
        colWidths: [CGFloat],
        isHeader: Bool,
        rowIndex: Int
    ) -> UIView {
        let rowView = UIView()
        rowView.clipsToBounds = true
        
        // 斑马纹：按行交替（表头单独样式）
        if isHeader {
            rowView.backgroundColor = markdownStyle.tableHeaderBackgroundColor
        } else {
            let even = (rowIndex % 2 == 0)
            rowView.backgroundColor = even ? markdownStyle.tableRowEvenBackgroundColor : markdownStyle.tableRowOddBackgroundColor
        }
        
        var lastCellView: UIView?
        var maxHeight: CGFloat = 0
        let lineColor = UIColor.hex(string: "#E9E9E9")
        let lineWidth = 1.0 / UIScreen.main.scale
        
        // 确保 colWidths 数量足够
        let widths: [CGFloat] = (colWidths.count >= colCount)
        ? Array(colWidths.prefix(colCount))
        : (colWidths + Array(repeating: Self.tableMinColWidth, count: max(0, colCount - colWidths.count)))
        
        func buildCellView(content: NSAttributedString?, col: Int, isHeader: Bool) -> UIView {
            let cell = AMMarkdownTableCellView()
            cell.backgroundColor = .clear
            
            let label = UILabel(frame: .zero)
            label.numberOfLines = 0
            if isHeader, let content {
                let attr = NSMutableAttributedString(attributedString: content)
                attr.addAttribute(.font, value: markdownStyle.tableHeaderFont, range: NSRange(location: 0, length: attr.length))
                label.attributedText = attr
            } else {
                label.attributedText = content
            }
            label.textAlignment = .center
            label.backgroundColor = .clear
            cell.addSubview(label)
            label.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                label.topAnchor.constraint(equalTo: cell.topAnchor, constant: 8),
                label.bottomAnchor.constraint(equalTo: cell.bottomAnchor, constant: -8),
                label.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 10),
                label.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -10)
            ])
            
            cell.lineColor = lineColor
            cell.lineWidth = lineWidth
            cell.drawTop = (rowIndex == 0)
            cell.drawLeft = (col == 0)
            cell.drawRight = true
            cell.drawBottom = true
            return cell
        }
        
        for col in 0..<colCount {
            let cellContent: NSAttributedString?
            if col < cells.count {
                let attr = AMMarkdownView.attributedText(for: cells[col], baseFont: markdownStyle.baseFont)
                cellContent = attr
                // 高度测量：用列宽减去 padding（与 label inset 对齐）
                let textWidth = max(1, widths[col] - 20)
                let h = AMMarkdownView.heightWithAttiribute(attr, width: textWidth, markdownStyle: markdownStyle, addCommonPragraph: false).height
                maxHeight = max(maxHeight, h + 16) // top/bottom 8
            } else {
                cellContent = nil
            }
            
            let cellView = buildCellView(content: cellContent, col: col, isHeader: isHeader)
            rowView.addSubview(cellView)
            cellView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                cellView.topAnchor.constraint(equalTo: rowView.topAnchor),
                cellView.bottomAnchor.constraint(equalTo: rowView.bottomAnchor),
                cellView.widthAnchor.constraint(equalToConstant: widths[col])
            ])
            
            if let last = lastCellView {
                cellView.leadingAnchor.constraint(equalTo: last.trailingAnchor).isActive = true
            } else {
                cellView.leadingAnchor.constraint(equalTo: rowView.leadingAnchor).isActive = true
            }
            lastCellView = cellView
        }
        
        lastCellView?.trailingAnchor.constraint(equalTo: rowView.trailingAnchor).isActive = true
        rowView.heightAnchor.constraint(equalToConstant: maxHeight).isActive = true
        return rowView
    }
    
}

// MARK: - Table layout helpers
private extension AMMarkdownView {
    struct TableLayout {
        let colWidths: [CGFloat]
        let totalWidth: CGFloat
    }
    
    static let tableMinColWidth: CGFloat = 88
    static let tableMaxColWidth: CGFloat = 260
    
    static func computeTableLayout(
        table: Table,
        availableWidth: CGFloat,
        markdownStyle: AMMarkdownViewStyle
    ) -> TableLayout {
        let headCells = Array(table.head.cells)
        let colCount = max(headCells.count, 1)
        
        // 采样：表头 + 前若干行，避免大表全量测量
        let maxSampleRows = 8
        let bodyRows = Array(table.body.rows.prefix(maxSampleRows))
        
        var cols: [[NSAttributedString]] = Array(repeating: [], count: colCount)
        
        func addRowCells(_ cells: [Table.Cell]) {
            for i in 0..<colCount {
                guard i < cells.count else { continue }
                let attr = AMMarkdownView.attributedText(for: cells[i], baseFont: markdownStyle.baseFont)
                cols[i].append(attr)
            }
        }
        
        addRowCells(headCells)
        for r in bodyRows {
            addRowCells(Array(r.cells))
        }
        
        let lineInset: CGFloat = 20 // 与 label 左右 inset 对齐
        var widths: [CGFloat] = []
        widths.reserveCapacity(colCount)
        
        for i in 0..<colCount {
            var w: CGFloat = tableMinColWidth
            for attr in cols[i] {
                let size = AMMarkdownView.heightWithAttiribute(attr, width: tableMaxColWidth - lineInset, markdownStyle: markdownStyle, addCommonPragraph: false)
                // boundingRect 的 width 在短文本时可能偏小；加上 padding
                w = max(w, min(tableMaxColWidth, size.width + lineInset))
            }
            widths.append(w)
        }
        
        // 如果列总宽小于可用宽度：不强行拉伸（保持内容宽），横滑自然不会出现
        let total = widths.reduce(0, +)
        return TableLayout(colWidths: widths, totalWidth: total)
    }
}

//MARK: UITextViewDelegate
extension AMMarkdownView: UITextViewDelegate {
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        onLinkTapped?(URL)
        return false
    }
    
}

// MARK: - 内联文本处理（保持不变）
extension AMMarkdownView {
    static func extraSpacingAttributedString(_ height: CGFloat) -> NSAttributedString {
        let attachment = NSTextAttachment()
        attachment.bounds = CGRect(x: 0, y: 0, width: 1, height: max(0, height))
        return NSAttributedString(attachment: attachment)
    }
    
    static func attributedTextForListItem(for block: Markup, baseFont: UIFont) -> [NSMutableAttributedString] {
        var lines = [NSMutableAttributedString]()
        let children = Array(block.children)
        var tmpAttr = NSMutableAttributedString()
        for (index, child) in children.enumerated() {
            switch child {
            case let text as Markdown.Text:
                tmpAttr.append(NSAttributedString(string: text.string,
                                                 attributes: [.font: baseFont]))

            case let strong as Strong:
                let sub = attributedText(for: strong, baseFont: baseFont)
                let bold = NSMutableAttributedString(attributedString: sub)
                bold.addAttributes([.font: UIFont.boldSystemFont(ofSize: baseFont.pointSize)],
                                   range: NSRange(location: 0, length: bold.length))
                tmpAttr.append(bold)

            case let em as Emphasis:
                let sub = attributedText(for: em, baseFont: baseFont)
                let italic = NSMutableAttributedString(attributedString: sub)
                italic.addAttributes([.font: UIFont.italicSystemFont(ofSize: baseFont.pointSize)],
                                     range: NSRange(location: 0, length: italic.length))
                tmpAttr.append(italic)

            case let code as InlineCode:
                let attr = NSAttributedString(string: code.code,
                                              attributes: [
                                                .font: UIFont.monospacedSystemFont(ofSize: baseFont.pointSize, weight: .regular),
                                                .backgroundColor: UIColor.systemGray5,
                                                .foregroundColor: UIColor.systemRed
                                              ])
                tmpAttr.append(attr)

            case let link as Link:
                let sub = attributedText(for: link, baseFont: baseFont)
                let linked = NSMutableAttributedString(attributedString: sub)
                linked.addAttributes([
                    .foregroundColor: UIColor.systemBlue,
                    .underlineStyle: NSUnderlineStyle.single.rawValue,
                    .link: link.destination ?? "",
                ], range: NSRange(location: 0, length: linked.length))
                tmpAttr.append(linked)
                
            case is LineBreak:
                lines.append(tmpAttr)
                tmpAttr = NSMutableAttributedString()
            case is Paragraph:
                lines.append(contentsOf: attributedTextForListItem(for: child, baseFont: baseFont))
            default:
                tmpAttr.append(attributedText(for: child, baseFont: baseFont))
            }
            
            if index == children.count - 1, tmpAttr.length > 0 {
                lines.append(tmpAttr)
            }
        }

        return lines
    }
    
    
    static func attributedText(for block: Markup, baseFont: UIFont) -> NSAttributedString {
        let result = NSMutableAttributedString()

        for child in block.children {
            switch child {
            case let text as Markdown.Text:
                result.append(NSAttributedString(string: text.string,
                                                 attributes: [.font: baseFont]))

            case let strong as Strong:
                let sub = attributedText(for: strong, baseFont: baseFont)
                let bold = NSMutableAttributedString(attributedString: sub)
                bold.addAttributes([.font: UIFont.boldSystemFont(ofSize: baseFont.pointSize)],
                                   range: NSRange(location: 0, length: bold.length))
                result.append(bold)

            case let em as Emphasis:
                let sub = attributedText(for: em, baseFont: baseFont)
                let italic = NSMutableAttributedString(attributedString: sub)
                italic.addAttributes([.font: UIFont.italicSystemFont(ofSize: baseFont.pointSize)],
                                     range: NSRange(location: 0, length: italic.length))
                result.append(italic)

            case let code as InlineCode:
                let attr = NSAttributedString(string: code.code,
                                              attributes: [
                                                .font: UIFont.monospacedSystemFont(ofSize: baseFont.pointSize, weight: .regular),
                                                .backgroundColor: UIColor.systemGray5,
                                                .foregroundColor: UIColor.systemRed
                                              ])
                result.append(attr)

            case let link as Link:
                let sub = attributedText(for: link, baseFont: baseFont)
                let linked = NSMutableAttributedString(attributedString: sub)
                linked.addAttributes([
                    .foregroundColor: UIColor.systemBlue,
                    .underlineStyle: NSUnderlineStyle.single.rawValue,
                    .link: link.destination ?? "",
                ], range: NSRange(location: 0, length: linked.length))
                result.append(linked)
                
            case is LineBreak:
                result.append(NSAttributedString(string: "\n"))

            default:
                result.append(attributedText(for: child, baseFont: baseFont))
            }
        }

        return result
    }
}

// MARK: - 高度计算
public extension AMMarkdownView {
    /// 根据 Markdown 字符串计算渲染高度
    static func height(
        for markdown: String,
        width: CGFloat,
        markdownStyle: AMMarkdownViewStyle = .default
    ) -> CGSize {
        height(for: Document(parsing: markdown), width: width, markdownStyle: markdownStyle)
    }

    /// 根据已解析的 `Document` 计算渲染高度
    static func height(
        for document: Markdown.Document,
        width: CGFloat,
        markdownStyle: AMMarkdownViewStyle = .default
    ) -> CGSize {
        var viewCount: Int = 0
        var totalHeight: CGFloat = 0
        let pendingText = NSMutableAttributedString()
        
        func appendBlockSpacingIfNeeded() {
            guard pendingText.length > 0 else { return }
            pendingText.append(NSAttributedString(string: "\n"))
        }
        
        func appendCommonParagraphStyle(_ attr: NSMutableAttributedString) {
            guard attr.length > 0 else { return }
            attr.addAttribute(.paragraphStyle, value: markdownStyle.paragrahStyle, range: NSRange(location: 0, length: attr.length))
        }
        
        func flushPendingTextIfNeeded() {
            guard pendingText.length > 0 else { return }
            let size = AMMarkdownView.heightWithAttiribute(pendingText, width: width, markdownStyle: markdownStyle, addCommonPragraph: false)
            totalHeight += size.height
            viewCount += 1
            pendingText.setAttributedString(NSAttributedString())
        }
        
        func appendParagraph(_ para: Paragraph) {
            appendBlockSpacingIfNeeded()
            let attr = NSMutableAttributedString(attributedString: AMMarkdownView.attributedText(for: para, baseFont: markdownStyle.baseFont))
            appendCommonParagraphStyle(attr)
            pendingText.append(attr)
        }
        
        func appendHeading(_ heading: Heading) {
            appendBlockSpacingIfNeeded()
            let font = UIFont.boldSystemFont(ofSize: CGFloat(22 - heading.level * 2))
            let attr = NSMutableAttributedString(attributedString: AMMarkdownView.attributedText(for: heading, baseFont: font))
            appendCommonParagraphStyle(attr)
            pendingText.append(attr)
        }
        
        func appendCodeBlock(_ code: CodeBlock) {
            appendBlockSpacingIfNeeded()
            let attr = NSMutableAttributedString(string: code.code, attributes: [
                .font: markdownStyle.codeFont,
                .foregroundColor: UIColor.darkText
            ])
            appendCommonParagraphStyle(attr)
            pendingText.append(attr)
        }
        
        func appendList(_ list: ListItemContainer, ordered: Bool) {
            appendBlockSpacingIfNeeded()
            let items = Array(list.listItems)
            for (idx, item) in items.enumerated() {
                let bullet = ordered ? "\(idx+1). " : "• "
                let lines = AMMarkdownView.attributedTextForListItem(for: item, baseFont: markdownStyle.baseFont)
                for (jdx, line) in lines.enumerated() {
                    let dealt: NSMutableAttributedString
                    if jdx == 0 {
                        dealt = AMMarkdownView.manipulateListItemAttribute(attribute: line, bullet: bullet, markdownStyle: markdownStyle)
                    } else {
                        dealt = AMMarkdownView.manipulateListItemAttribute(attribute: line, markdownStyle: markdownStyle)
                    }
                    pendingText.append(dealt)
                    if jdx != lines.count - 1 {
                        pendingText.append(NSAttributedString(string: "\n"))
                    }
                }
                if idx != items.count - 1 {
                    pendingText.append(NSAttributedString(string: "\n"))
                }
            }
        }
        
        func appendTableHeight(_ table: Table) {
            let layout = computeTableLayout(table: table, availableWidth: width, markdownStyle: markdownStyle)
            let colWidths = layout.colWidths
            let headColCount = table.head.cells.reduce(0) { acc, _ in acc + 1 }
            let colCount = max(colWidths.count, headColCount)
            
            func rowHeight(for cells: [Table.Cell], rowIndex: Int) -> CGFloat {
                var hMax: CGFloat = 0
                for i in 0..<min(cells.count, colCount) {
                    let attr = attributedText(for: cells[i], baseFont: markdownStyle.baseFont)
                    let textWidth = max(1, (i < colWidths.count ? colWidths[i] : tableMinColWidth) - 20)
                    let h = AMMarkdownView.heightWithAttiribute(attr, width: textWidth, markdownStyle: markdownStyle, addCommonPragraph: false).height
                    hMax = max(hMax, h + 16) // top/bottom padding 8
                }
                return max(hMax, 16)
            }
            
            var tableHeight: CGFloat = 0
            tableHeight += rowHeight(for: Array(table.head.cells), rowIndex: 0)
            var idx = 0
            for row in table.body.rows {
                idx += 1
                tableHeight += rowHeight(for: Array(row.cells), rowIndex: idx)
            }
            
            totalHeight += tableHeight
            viewCount += 1
        }
        
        func appendBlockQuoteHeight(_ quote: BlockQuote) {
            flushPendingTextIfNeeded()
            let attr = NSMutableAttributedString(attributedString: attributedText(for: quote, baseFont: markdownStyle.baseFont))
            if attr.length > 0 {
                attr.addAttribute(.paragraphStyle, value: markdownStyle.paragrahStyle, range: NSRange(location: 0, length: attr.length))
            }
            totalHeight += AMMarkdownBlockQuoteView.measuredHeight(text: attr, width: width, style: markdownStyle)
            viewCount += 1
        }
        
        var previousElementIsList = false
        for block in document.children {
            if previousElementIsList {
                appendBlockSpacingIfNeeded()
                previousElementIsList = false
            }
            switch block {
            case let para as Paragraph:
                appendParagraph(para)
            case let heading as Heading:
                appendHeading(heading)
            case let code as CodeBlock:
                appendCodeBlock(code)
            case let list as UnorderedList:
                appendList(list, ordered: false)
                previousElementIsList = true
            case let list as OrderedList:
                appendList(list, ordered: true)
                previousElementIsList = true
            case let table as Table:
                flushPendingTextIfNeeded()
                appendTableHeight(table)
            case let quote as BlockQuote:
                appendBlockQuoteHeight(quote)
            default:
                break
            }
        }
        
        flushPendingTextIfNeeded()
        
        if viewCount > 1 {
            totalHeight += CGFloat(viewCount - 1) * markdownStyle.blockSpacing
        }
        
        return CGSize(width: width, height: ceil(totalHeight))
    }
    
    static func manipulateListItemAttribute(attribute: NSMutableAttributedString, bullet: String? = nil, markdownStyle: AMMarkdownViewStyle) -> NSMutableAttributedString {
        let attr = NSMutableAttributedString()
        if let bullet = bullet {
            attr.append(NSAttributedString(string: bullet, attributes: [.font: UIFont.systemFont(ofSize: 16)]))
            attr.append(attribute)
            
            let paragrahStyle = NSMutableParagraphStyle()
            paragrahStyle.setParagraphStyle(markdownStyle.listParagrahStyle)
            attr.addAttribute(.paragraphStyle, value: paragrahStyle, range: NSRange(location: 0, length: attr.length))
        } else {
            attr.append(attribute)
            
            let paragrahStyle = NSMutableParagraphStyle()
            paragrahStyle.setParagraphStyle(markdownStyle.listParagrahStyle)
            paragrahStyle.firstLineHeadIndent = markdownStyle.listParagrahStyle.firstLineHeadIndent * 2
            paragrahStyle.headIndent = paragrahStyle.firstLineHeadIndent + (markdownStyle.listParagrahStyle.headIndent - markdownStyle.listParagrahStyle.firstLineHeadIndent)
            attr.addAttribute(.paragraphStyle, value: paragrahStyle, range: NSRange(location: 0, length: attr.length))
        }
        return attr
    }
    
    static func heightWithAttiribute(_ attirbute: NSAttributedString, width: CGFloat, markdownStyle: AMMarkdownViewStyle, addCommonPragraph:Bool) -> CGSize {
        let dealedAttr = NSMutableAttributedString(attributedString: attirbute)
        if addCommonPragraph {
            dealedAttr.addAttribute(.paragraphStyle, value: markdownStyle.paragrahStyle, range: NSRange(location: 0, length: dealedAttr.length))
        }
        let size = dealedAttr.boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
        return CGSize(width: ceil(size.width), height: ceil(size.height))
    }
}
