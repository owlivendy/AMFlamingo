# AMPopupView

AMPopupView 是一个支持底部弹窗（Bottom Sheet）和居中弹窗（Alert）样式的弹窗组件，支持自定义内容、圆角、关闭按钮样式、键盘避让等。

## 功能特性
- 支持底部弹窗和 Alert 弹窗两种样式
- 支持自定义内容视图
- 支持关闭按钮样式（x、back、none）
- 支持键盘弹起时自动避让
- 支持点击背景关闭弹窗

## 用法示例

### 底部弹窗（Bottom Sheet）
```swift
import AMFlamingo

let customView = UILabel()
customView.text = "自定义内容"
customView.textAlignment = .center
customView.backgroundColor = .systemGray6
customView.layer.cornerRadius = 8
customView.clipsToBounds = true
customView.translatesAutoresizingMaskIntoConstraints = false
NSLayoutConstraint.activate([
    customView.heightAnchor.constraint(equalToConstant: 80),
    customView.widthAnchor.constraint(equalToConstant: 220)
])

let popup = AMPopupView(title: "弹窗标题", customView: customView, presentationStyle: .fromBottom)
popup.closeButtonStyle = .x // 可选 .x、.back、.none
popup.show()
```

### 居中弹窗（Alert）
```swift
import AMFlamingo

let customView = UILabel()
customView.text = "Alert 内容"
customView.textAlignment = .center
customView.backgroundColor = .systemGray6
customView.layer.cornerRadius = 8
customView.clipsToBounds = true
customView.translatesAutoresizingMaskIntoConstraints = false
NSLayoutConstraint.activate([
    customView.heightAnchor.constraint(equalToConstant: 80),
    customView.widthAnchor.constraint(equalToConstant: 220)
])

let popup = AMPopupView(title: nil, customView: customView, presentationStyle: .alert)
popup.show()
```

## 常用属性
- `title`：弹窗标题（Alert 样式下不显示）
- `presentationStyle`：弹窗样式（.fromBottom/.alert）
- `closeButtonStyle`：关闭按钮样式（.x/.back/.none）
- `enableKeyboardAdjustment`：是否启用键盘避让
- `tapBackgroundToHide`：点击背景是否关闭弹窗 