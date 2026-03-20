//
//  AMMarkdownView.swift
//  Flamingo
//
//  Created by xiaofei shen on 2025/8/30.
//

import UIKit
import Markdown

struct AMMarkdownViewStyle {
    var TableCellSpace: CGFloat = 1
    
    // MARK: - Table style
    /// 表格斑马纹：偶数行背景色（不含表头）
    var tableRowEvenBackgroundColor: UIColor = .white
    /// 表格斑马纹：奇数行背景色（不含表头）
    var tableRowOddBackgroundColor: UIColor = UIColor.hex(string: "#FFF7F4")
    /// 表头背景色
    var tableHeaderBackgroundColor: UIColor = .systemGray6
    /// 表头字体（会覆盖表头单元格内部 attributedText 的 font）
    var tableHeaderFont: UIFont = .systemFont(ofSize: 16, weight: .semibold)
    /// 通用段落样式：正文、标题、列表、表格文本等未单独覆盖时都会继承该样式。
    var paragrahStyle: NSParagraphStyle
    /// 列表首行缩进（包含 bullet/序号），用于控制列表项第一行的左侧起点。
    var listItemFirstHeadIntent: CGFloat = 14
    /// 列表后续行缩进（换行后的文本起点），通常应大于 `listItemFirstHeadIntent`。
    var listItemHeadIntent: CGFloat = 24
    /// 同一列表项内部（多段/多行）之间的垂直间距；建议为字体大小的 0.3~0.5 倍。
    var listItemSpacing: CGFloat = 8
    /// 块级元素（段落、标题、列表、表格）之间的垂直间距；建议为行间距的 1.5~2 倍。
    var blockSpacing: CGFloat = 16
    
    /// 正文基础字体：普通文本、列表文本、表格内容等默认使用该字体。
    var baseFont: UIFont = .systemFont(ofSize: 16)
    /// 代码字体：代码块与内联代码优先使用等宽字体，便于对齐与阅读。
    var codeFont: UIFont = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
    
    var isDebug = false
    
    static var `default`: AMMarkdownViewStyle = {
        return AMMarkdownViewStyle()
    }()
    
    init() {
        let _paragrahstyle = NSMutableParagraphStyle()
        _paragrahstyle.lineSpacing = 8
        _paragrahstyle.paragraphSpacing = 16
        paragrahStyle = _paragrahstyle
    }
}

/// 主视图：用于渲染 Markdown Document（不使用 UIStackView 版本）
class AMMarkdownView: UIView {
    private let container = UIView() // 用于承载所有子元素的容器
    private var lastSubview: UIView? // 记录上一个添加的子视图，用于约束布局

    let markdownStyle: AMMarkdownViewStyle
    
    var onLinkTapped:((URL) -> Void)?
    
    init(frame: CGRect, markdownStyle: AMMarkdownViewStyle = .default) {
        self.markdownStyle = markdownStyle
        super.init(frame: frame)
        setupContainer()
    }
    
    func update(document: Markdown.Document?) {
        lastSubview = nil
        container.subviews.forEach { $0.removeFromSuperview() }
        if let document = document {
            render(document)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
    
    private func assignLabel(_ label:UILabel, markup: Markup, width: CGFloat, addCommonPragraphSyle: Bool = false) {
        let attribute = AMMarkdownView.attributedText(for: markup, baseFont: markdownStyle.baseFont)
        assignLabel(label, attribute: attribute, width: width, addCommonPragraphSyle: addCommonPragraphSyle)
    }
    
    
    private func assignLabel(_ label:UILabel, attribute: NSAttributedString, width: CGFloat, addCommonPragraphSyle: Bool = false) {
        let finalAttri = NSMutableAttributedString(attributedString: attribute)
        if addCommonPragraphSyle {
            finalAttri.addAttribute(.paragraphStyle, value: markdownStyle.paragrahStyle, range: NSRange(location: 0, length: attribute.length))
        }
        label.attributedText = finalAttri
        let labelHeight = AMMarkdownView.heightWithAttiribute(label.attributedText!, width: width, markdownStyle: markdownStyle, addCommonPragraph: addCommonPragraphSyle).height
        label.heightAnchor.constraint(equalToConstant: labelHeight).isActive = true
        
        if let linkurl = AttributedStringLinkDetector.extractLinkUrls(from: attribute).first {
            label.accessibilityIdentifier = linkurl.absoluteString
            label.isUserInteractionEnabled = true
            label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onLinkLabelPress)))
        }
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
        for block in document.children {
            let subview: UIView?
            switch block {
            case let para as Paragraph:
                let label = UILabel(frame: .zero)
                label.numberOfLines = 0
                assignLabel(label, markup: para, width: width, addCommonPragraphSyle: true)
                subview = label

            case let heading as Heading:
                let font = UIFont.boldSystemFont(ofSize: CGFloat(22 - heading.level * 2))
                let label = UILabel(frame: .zero)
                label.numberOfLines = 0
                let attr = AMMarkdownView.attributedText(for: heading, baseFont: font)
                label.attributedText = attr
                assignLabel(label, attribute: attr, width: width, addCommonPragraphSyle: true)
                subview = label

            case let code as CodeBlock:
                let label = UILabel(frame: .zero)
                label.numberOfLines = 0
                label.font = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
                label.text = code.code
                label.layer.cornerRadius = 6
                label.layer.masksToBounds = true
                label.textColor = UIColor.darkText
                label.textAlignment = .left
                subview = label

            case let list as UnorderedList:
                subview = makeListView(list: list, ordered: false)

            case let list as OrderedList:
                subview = makeListView(list: list, ordered: true)

            case let table as Table:
                subview = makeTableView(table: table)
                
            default:
                subview = nil
            }

            // 添加子视图并设置约束
            if let subview = subview {
                addSubviewToContainer(subview)
            }
        }
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

    // MARK: - 列表渲染（保持原有逻辑，仅布局方式改为直接添加）
    private func makeListView(list: ListItemContainer,
                              ordered: Bool) -> UIView {
        let width = bounds.width
        let container = UIView()
        var lastItemView: UIView?

        for (idx, item) in list.listItems.enumerated() {
            let bullet = ordered ? "\(idx+1). " : "• "
            
            let lines = AMMarkdownView.attributedTextForListItem(for: item, baseFont: markdownStyle.baseFont)
            for (jdx, line) in lines.enumerated() {
                
                let label = UILabel(frame: .zero)
                label.numberOfLines = 0
                
                let attr: NSMutableAttributedString
                if jdx == 0 {
                    attr = AMMarkdownView.manipulateListItemAttribute(attribute: line, bullet: bullet, markdownStyle: markdownStyle)
                } else {
                    attr = AMMarkdownView.manipulateListItemAttribute(attribute: line, markdownStyle: markdownStyle)
                }
                assignLabel(label, attribute: attr, width: width)
                let heigcon = label.constraints.first { con in
                    con.firstAttribute == .height
                }
                if markdownStyle.isDebug {
                    print("[AMMarkdownView] [listItem]: \(label.text ?? ""),  height: \(heigcon?.constant ?? 0)")
                }
                
                container.addSubview(label)
                label.translatesAutoresizingMaskIntoConstraints = false
                
                // 设置列表项约束
                NSLayoutConstraint.activate([
                    label.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                    label.trailingAnchor.constraint(equalTo: container.trailingAnchor)
                ])
                
                if let last = lastItemView {
                    label.topAnchor.constraint(equalTo: last.bottomAnchor, constant: markdownStyle.listItemSpacing).isActive = true
                } else {
                    label.topAnchor.constraint(equalTo: container.topAnchor).isActive = true
                }
                lastItemView = label
            }

        }
        
        // 确保容器底部与最后一个子视图对齐
        if let last = lastItemView {
            last.bottomAnchor.constraint(equalTo: container.bottomAnchor).isActive = true
        } else {
            // 空列表时设置最小高度
            container.heightAnchor.constraint(equalToConstant: 0).isActive = true
        }
        
        return container
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

private final class AMMarkdownTableCellView: UIView {
    var lineColor: UIColor = UIColor.hex(string: "#E9E9E9")
    var lineWidth: CGFloat = 1.0 / UIScreen.main.scale
    
    var drawTop: Bool = false
    var drawLeft: Bool = false
    var drawRight: Bool = true
    var drawBottom: Bool = true
    
    private let topLayer = CALayer()
    private let leftLayer = CALayer()
    private let rightLayer = CALayer()
    private let bottomLayer = CALayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.addSublayer(topLayer)
        layer.addSublayer(leftLayer)
        layer.addSublayer(rightLayer)
        layer.addSublayer(bottomLayer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        topLayer.backgroundColor = lineColor.cgColor
        leftLayer.backgroundColor = lineColor.cgColor
        rightLayer.backgroundColor = lineColor.cgColor
        bottomLayer.backgroundColor = lineColor.cgColor
        
        topLayer.isHidden = !drawTop
        leftLayer.isHidden = !drawLeft
        rightLayer.isHidden = !drawRight
        bottomLayer.isHidden = !drawBottom
        
        let w = bounds.width
        let h = bounds.height
        topLayer.frame = CGRect(x: 0, y: 0, width: w, height: lineWidth)
        leftLayer.frame = CGRect(x: 0, y: 0, width: lineWidth, height: h)
        rightLayer.frame = CGRect(x: w - lineWidth, y: 0, width: lineWidth, height: h)
        bottomLayer.frame = CGRect(x: 0, y: h - lineWidth, width: w, height: lineWidth)
    }
}

// MARK: - 内联文本处理（保持不变）
extension AMMarkdownView {
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

// MARK: - 高度计算（保持不变）
extension AMMarkdownView {
    static func height(for document: Markdown.Document, width: CGFloat, markdownStyle: AMMarkdownViewStyle = .default) -> CGSize {
        var total: CGFloat = 0
        let padding: CGFloat = markdownStyle.blockSpacing
        var maxWidth: CGFloat = 0
        var stringCount = 0

        for block in document.children {
            switch block {
            case let para as Paragraph:
                let attr = attributedText(for: para, baseFont: markdownStyle.baseFont)
                
                let size = AMMarkdownView.heightWithAttiribute(attr, width: width, markdownStyle: markdownStyle, addCommonPragraph: true)
                maxWidth = max(size.width, maxWidth)
                total += size.height + padding

                stringCount += attr.length
            case let heading as Heading:
                let font = UIFont.boldSystemFont(ofSize: CGFloat(22 - heading.level * 2))
                let attr = attributedText(for: heading, baseFont: font)
                total += AMMarkdownView.heightWithAttiribute(attr, width: width, markdownStyle: markdownStyle, addCommonPragraph: true).height + padding

                stringCount += attr.length
            case let code as CodeBlock:
                let attr = NSAttributedString(string: code.code,
                                              attributes: [.font: markdownStyle.codeFont])
                total += AMMarkdownView.heightWithAttiribute(attr, width: width, markdownStyle: markdownStyle, addCommonPragraph: false).height + padding

                stringCount += attr.length
            case let list as UnorderedList:
                total += listHeight(list, ordered: false, width: width, markdownStyle: markdownStyle, textLength: &stringCount) + padding

            case let list as OrderedList:
                total += listHeight(list, ordered: true, width: width, markdownStyle: markdownStyle, textLength: &stringCount) + padding

            case let table as Table:
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
                        stringCount += attr.length
                    }
                    // 空列占位也要保证最小高度
                    return max(hMax, 16)
                }
                
                total += rowHeight(for: Array(table.head.cells), rowIndex: 0)
                var idx = 0
                for row in table.body.rows {
                    idx += 1
                    total += rowHeight(for: Array(row.cells), rowIndex: idx)
                }
                
                total += padding

            default:
                break
            }
        }
        
        if stringCount > 20 {
            maxWidth = width
        }

        return CGSize(width: width, height: total - padding)
    }
    
    private static func listHeight(_ list: ListItemContainer,
                                   ordered: Bool,
                                   width: CGFloat,
                                   markdownStyle: AMMarkdownViewStyle,
                                   textLength: inout Int) -> CGFloat {
        var total: CGFloat = 0
         
        for (idx, item) in list.listItems.enumerated() {
            let bullet = ordered ? "\(idx+1). " : "• "
            let lines = attributedTextForListItem(for: item, baseFont: markdownStyle.baseFont)
            
            for (jdx, line) in lines.enumerated() {
                let attr: NSMutableAttributedString
                if jdx == 0 {
                    attr = AMMarkdownView.manipulateListItemAttribute(attribute: line, bullet: bullet, markdownStyle: markdownStyle)
                } else {
                    attr = AMMarkdownView.manipulateListItemAttribute(attribute: line, markdownStyle: markdownStyle)
                }
                let h = AMMarkdownView.heightWithAttiribute(attr, width: width, markdownStyle: markdownStyle, addCommonPragraph: false).height
                
                if markdownStyle.isDebug {
                    print("[AMMarkdownView] [listItem]_calculate_H: \(attr.string),  height: \(h)")
                }
                
                total += h + markdownStyle.listItemSpacing
                
                textLength += attr.length
            }

        }
        return total - markdownStyle.listItemSpacing
    }
    
    static func manipulateListItemAttribute(attribute: NSMutableAttributedString, bullet: String? = nil, markdownStyle: AMMarkdownViewStyle) -> NSMutableAttributedString {
        let attr = NSMutableAttributedString()
        if let bullet = bullet {
            attr.append(NSAttributedString(string: bullet, attributes: [.font: UIFont.systemFont(ofSize: 16)]))
            attr.append(attribute)
            
            let paragrahStyle = NSMutableParagraphStyle()
            paragrahStyle.setParagraphStyle(markdownStyle.paragrahStyle)
            paragrahStyle.firstLineHeadIndent = markdownStyle.listItemFirstHeadIntent
            paragrahStyle.headIndent = markdownStyle.listItemHeadIntent
            attr.addAttribute(.paragraphStyle, value: paragrahStyle, range: NSRange(location: 0, length: attr.length))
        } else {
            attr.append(attribute)
            
            let paragrahStyle = NSMutableParagraphStyle()
            paragrahStyle.setParagraphStyle(markdownStyle.paragrahStyle)
            paragrahStyle.firstLineHeadIndent = markdownStyle.listItemFirstHeadIntent * 2
            paragrahStyle.headIndent = paragrahStyle.firstLineHeadIndent + (markdownStyle.listItemHeadIntent - markdownStyle.listItemFirstHeadIntent)
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
