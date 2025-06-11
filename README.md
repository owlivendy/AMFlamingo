# AMFlamingo

AMFlamingo is an iOS UI component library providing common UI extension functionalities.

## Features

- UIView Extensions
  - Flow layout support
  - Nib loading support
- UIButton Extensions
  - Customizable image position
  - Customizable text position

## Installation

### Swift Package Manager

In Xcode, select File > Swift Packages > Add Package Dependency, and enter:

```
https://github.com/your-username/AMFlamingo.git
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

- iOS 13.0+
- Xcode 13.0+
- Swift 5.5+

## Dependencies

- SnapKit

## License

MIT License 