# AMToast

[English](README.md) | [简体中文](README_CN.md)

A simple and customizable toast library for iOS.

![Queue Display](./assets/queue_display.gif)

## Features

- Multiple positions (top and center)
- Queue-based display for multiple toasts
- Customizable styles (corner radius, background color)
- Dark mode support
- Customizable font size and style
- Custom view support
- Screen rotation adaptation

## Requirements

- iOS 13.0+
- Swift 5.0+

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/owlivendy/AMToast.git", from: "0.3.0")
]
```

Or in Xcode:
1. Go to File > Swift Packages > Add Package Dependency
2. Enter the repository URL: `https://github.com/owlivendy/AMToast.git`
3. Select the version you want to use

### CocoaPods

```ruby
pod 'AMToast'
```

## Usage

### Basic Usage

```swift
// Show a simple toast
AMToast.show(with: "This is a toast message")

// Show a toast at top position
AMToast.show(with: "This is a top toast", position: .top)

// Show a success toast
AMToast.showSuccess(with: "Operation successful!")
```

### Custom Style

```swift
// Customize corner radius
AMToastConfig.ToastViewStyle.cornerRadius = 20

// Customize background color for light mode
AMToastConfig.ToastViewStyle.BackgroundColor.light = UIColor.red.withAlphaComponent(0.94)

// Customize background color for dark mode
AMToastConfig.ToastViewStyle.BackgroundColor.dark = UIColor(white: 0.2, alpha: 0.94)

// Customize text color for light mode
AMToastConfig.ToastViewStyle.TextColor.light = UIColor.white

// Customize text color for dark mode
AMToastConfig.ToastViewStyle.TextColor.dark = UIColor.white

// Customize font size for light mode
AMToastConfig.ToastViewStyle.Font.light = UIFont.systemFont(ofSize: 16)

// Customize font size for dark mode
AMToastConfig.ToastViewStyle.Font.dark = UIFont.systemFont(ofSize: 16)

// Use bold font
AMToastConfig.ToastViewStyle.Font.light = UIFont.boldSystemFont(ofSize: 14)
AMToastConfig.ToastViewStyle.Font.dark = UIFont.boldSystemFont(ofSize: 14)

// Customize position margins
AMToastConfig.Position.topMarginPortrait = 100
AMToastConfig.Position.topMarginLandscape = 20

// Reset all configurations to default
AMToastConfig.resetToDefault()
```

### Custom View

```swift
// Create custom view
let customView = UIView()
// Add your custom UI elements...

// Create toast view
let toastView = AMToastView()
toastView.contentInsets = UIEdgeInsets(top: 12, left: 20, bottom: 12, right: 20)
toastView.customView = customView

// Show custom toast
AMToast.show(with: toastView, position: .center)
```

## License

AMToast is available under the MIT license. See the LICENSE file for more info.