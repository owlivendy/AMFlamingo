//
//  SandboxFilePreviewerController.swift
//  ChinaHomelife247
//
//  Created by meotech on 2026/01/23.
//  Copyright © 2026 吕欢. All rights reserved.
//

import UIKit

/// 沙盒文件或目录项模型
/// 用于表示应用沙盒中的文件或目录信息
struct SandboxItem {
    /// 文件或目录名称
    let name: String
    /// 文件或目录的完整路径
    let path: String
    /// 是否为目录
    let isDirectory: Bool
    /// 文件大小（字节），目录大小为0
    let size: UInt64
    /// 最后修改日期
    let modificationDate: Date
}

class SandboxFilePreviewerController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    // MARK: - Properties
    private let tableView = UITableView()
//    private var currentPath: String
    private var path: String?
    private var items: [SandboxItem] = []
    private var currentPath: String {
        return self.path ?? NSHomeDirectory()
    }
    
    // MARK: - Initialization
    init(path: String? = nil) {
        self.path = path
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadItems()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        title = self.path == nil ? "沙盒根目录" : URL(fileURLWithPath: currentPath).lastPathComponent
        view.backgroundColor = .white
        
        // Setup TableView
        tableView.dataSource = self
        tableView.delegate = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.tableFooterView = UIView()
        
        // Register cell
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SandboxCell")
        
        view.addSubview(tableView)
        
        // Auto Layout
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Add back button if not at root
        if self.path == nil {
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeAction))
        }
    }
    
    // MARK: - File Loading
    private func loadItems() {
        do {
            // Get all items in directory
            let fileManager = FileManager.default
            let contents = try fileManager.contentsOfDirectory(atPath: currentPath)
            
            // Process each item
            items = try contents.compactMap { itemName -> SandboxItem? in
                let itemPath = currentPath + "/" + itemName
                var isDir: ObjCBool = false
                guard fileManager.fileExists(atPath: itemPath, isDirectory: &isDir) else { return nil }
                
                // Get file attributes
                let attributes = try fileManager.attributesOfItem(atPath: itemPath)
                let size = attributes[.size] as? UInt64 ?? 0
                let modificationDate = attributes[.modificationDate] as? Date ?? Date()
                
                return SandboxItem(
                    name: itemName,
                    path: itemPath,
                    isDirectory: isDir.boolValue,
                    size: size,
                    modificationDate: modificationDate
                )
            }
            
            // Sort: directories first, then files, both alphabetically
            items.sort { (item1, item2) -> Bool in
                if item1.isDirectory && !item2.isDirectory {
                    return true
                } else if !item1.isDirectory && item2.isDirectory {
                    return false
                } else {
                    return item1.name.localizedCompare(item2.name) == .orderedAscending
                }
            }
            
            tableView.reloadData()
        } catch {
            print("Error loading directory contents: \(error)")
            // Show error message
            let alert = UIAlertController(title: "错误", message: "无法加载目录内容", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "确定", style: .default))
            present(alert, animated: true)
        }
    }
    
    // MARK: - Helper Methods
    private func formatFileSize(_ size: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(size))
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func truncateFileName(_ name: String, maxLength: Int) -> String {
        guard name.count > maxLength else { return name }
        let prefixLength = max(0, maxLength - 3)
        return String(name.prefix(prefixLength)) + "..."
    }
    
    // MARK: - Actions
    @objc private func closeAction() {
        dismiss(animated: true)
    }
    
    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SandboxCell", for: indexPath)
        let item = items[indexPath.row]
        
        // Configure cell
        cell.textLabel?.text = truncateFileName(item.name, maxLength: 50)
        cell.detailTextLabel?.text = item.isDirectory ? "目录" : "\(formatFileSize(item.size)) · \(formatDate(item.modificationDate))"
        cell.imageView?.image = item.isDirectory ? UIImage(systemName: "folder.fill") : UIImage(systemName: "doc.text.fill")
        cell.accessoryType = item.isDirectory ? .disclosureIndicator : .none
        
        // Setup detail text label
        if cell.detailTextLabel == nil {
            cell.detailTextLabel?.font = UIFont.systemFont(ofSize: 12)
            cell.detailTextLabel?.textColor = .gray
            cell.detailTextLabel?.text = item.isDirectory ? "目录" : "\(formatFileSize(item.size)) · \(formatDate(item.modificationDate))"
        }
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let item = items[indexPath.row]
        if item.isDirectory {
            // Navigate to subdirectory
            let nextController = SandboxFilePreviewerController(path: item.path)
            navigationController?.pushViewController(nextController, animated: true)
        } else {
            // File selected, can add file preview functionality later
            print("File selected: \(item.name)")
        }
    }
    
    // MARK: - Context Menu Support
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let item = items[indexPath.row]
        
        // 只有文件才显示导出选项
        if !item.isDirectory {
            return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
                // 创建导出动作
                let exportAction = UIAction(title: "导出", image: UIImage(systemName: "square.and.arrow.up")) { [weak self] _ in
                    self?.exportFile(at: indexPath)
                }
                
                return UIMenu(title: "", children: [exportAction])
            }
        }
        
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44.0
    }
    
    // MARK: - File Export
    private func exportFile(at indexPath: IndexPath) {
        let item = items[indexPath.row]
        let fileURL = URL(fileURLWithPath: item.path)
        
        // 创建系统分享控制器
        let activityViewController = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        
        // 设置弹出位置（iPad支持）
        if let popoverPresentationController = activityViewController.popoverPresentationController {
            if let cell = tableView.cellForRow(at: indexPath) {
                popoverPresentationController.sourceView = cell
                popoverPresentationController.sourceRect = cell.bounds
            }
        }
        
        // 显示分享控制器
        present(activityViewController, animated: true)
    }
}
