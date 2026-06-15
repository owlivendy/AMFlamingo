//
//  AMPopoverMenuView.swift
//  AMFlamingo
//

import UIKit

/// 气泡菜单项
@objc(AMPopoverMenuItem)
@objcMembers
open class AMPopoverMenuItem: NSObject {

    open var title: String = ""
    open var action: (() -> Void)?

    @objc(itemWithTitle:action:)
    public static func item(withTitle title: String, action: (() -> Void)?) -> AMPopoverMenuItem {
        let item = AMPopoverMenuItem()
        item.title = title
        item.action = action
        return item
    }
}

/// 基于 `AMPopoverView` 的菜单气泡
@objc(AMPopoverMenuView)
@objcMembers
open class AMPopoverMenuView: UIView, UITableViewDelegate, UITableViewDataSource {

    /// 菜单宽度，默认 100
    open var menuWidth: CGFloat = 100
    /// 行高，默认 44
    open var rowHeight: CGFloat = 44
    /// 最大高度，默认 5 行
    open var maxHeight: CGFloat = 44 * 5

    private let tableView = UITableView(frame: .zero, style: .plain)
    private weak var popoverView: AMPopoverView?
    private let menuItems: [AMPopoverMenuItem]

    @objc(initWithMenuItems:)
    public init(menuItems: [AMPopoverMenuItem]) {
        self.menuItems = menuItems
        super.init(frame: .zero)
        setupUI()
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 显示气泡
    /// - Parameters:
    ///   - anchorView: 锚点视图， 弹窗以该视图为锚点弹出；
    open func show(anchorView: UIView) {
        let itemHeight = CGFloat(menuItems.count) * rowHeight
        let actualHeight = min(itemHeight, maxHeight)

        frame = CGRect(x: 0, y: 0, width: menuWidth, height: actualHeight)
        tableView.isScrollEnabled = actualHeight > maxHeight

        let popover = AMPopoverView(contentView: self)
        popoverView = popover
        popover.show(anchorView: anchorView)
    }

    open func show(_ anchorView: UIView) {
        show(anchorView: anchorView)
    }

    open func hide() {
        popoverView?.hide()
    }

    // MARK: - Private

    private func setupUI() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .singleLine
        tableView.backgroundColor = .clear
        tableView.showsVerticalScrollIndicator = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.topAnchor.constraint(equalTo: topAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    // MARK: - UITableViewDataSource

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        menuItems.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let item = menuItems[indexPath.row]
        cell.textLabel?.text = item.title
        cell.textLabel?.textAlignment = .center
        cell.textLabel?.font = .systemFont(ofSize: 14)
        cell.textLabel?.textColor = .black
        cell.backgroundColor = .clear
        return cell
    }

    // MARK: - UITableViewDelegate

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        rowHeight
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        menuItems[indexPath.row].action?()
        popoverView?.hide()
    }
}
