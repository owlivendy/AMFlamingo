# AMUserDirManager

AMUserDirManager 是一个用户目录管理工具，支持多用户隔离数据目录，自动创建 Document/Cache/Tmp 子目录。

## 功能特性
- 支持用户唯一键管理，自动切换 guest_user
- 支持登录/登出切换用户目录
- 自动创建用户专属 Document/Cache/Tmp 目录

## 用法示例
```swift
import AMFlamingo

// 登录，设置用户唯一键
AMUserDirManager.shared.login(userKey: "user_123456")

// 获取当前用户唯一键
let userKey = AMUserDirManager.shared.userKey

// 获取当前用户的 Document 目录
let docDir = AMUserDirManager.shared.userDocumentDirectory()

// 获取当前用户的 Cache 目录
let cacheDir = AMUserDirManager.shared.userCacheDirectory()

// 获取当前用户的 Tmp 目录
let tmpDir = AMUserDirManager.shared.userTmpDirectory()

// 登出，切换为 guest_user
AMUserDirManager.shared.logout()
```

## 常用方法
- `login(userKey:)`：登录并切换用户唯一键
- `logout()`：登出，切换为 guest_user
- `userDocumentDirectory()`：获取当前用户 Document 目录
- `userCacheDirectory()`：获取当前用户 Cache 目录
- `userTmpDirectory()`：获取当前用户 Tmp 目录 