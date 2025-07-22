# AMFlamingo

AMFlamingo is an iOS UI component library providing common UI extension functionalities.

## Features

- UIView Extensions
  - Flow layout support
  - Nib loading support
- UIButton Extensions
  - Customizable image position
  - Customizable text position
- AMPopupView
  - Bottom sheet & Alert style popup
  - Custom content support
  - Keyboard avoidance

## Installation

### Swift Package Manager

In Xcode, select File > Swift Packages > Add Package Dependency, and enter:

```
https://github.com/owlivendy/AMFlamingo.git
```

### CocoaPods

Add the following to your Podfile:

```ruby
pod 'AMFlamingo'
```

Then run:

```bash
pod install
```

## Usage Example

### AMPopupView

#### 底部弹窗（Bottom Sheet）
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

#### 居中弹窗（Alert）
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

### UIView Flow Layout

```swift
import AMFlamingo

let config = AMFlowlayoutConfig(maxWidth: 300)
let views = [view1, view2, view3]
let height = UIView.heightForFlowHorizontalSubViews(views, config: config)
```

### UIButton Image Position

```swift
import AMFlamingo

button.AM_imagePositionStyle(.right, spacing: 10)
```

## Requirements

- iOS 10.0+
- Swift 5.0+
- Xcode 12.0+

## Dependencies

- SnapKit

## License

MIT License 