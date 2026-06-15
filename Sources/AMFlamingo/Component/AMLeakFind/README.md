# AMLeakFinder

`AMLeakFinder` 是 AMFlamingo 提供的 **DEBUG 专用** ViewController / View 内存泄漏检测工具。通过 Hook 导航栈与视图层级，在页面 **pop / dismiss** 后延迟检查对象是否仍被持有，并在 Xcode 控制台输出报告。

> **Release 构建中为空实现**，不会 Swizzle、不会检测、不会产生运行时开销。

---

## 快速开始

### Swift

```swift
#if DEBUG
import AMFlamingo

// 可选：只检测业务 VC，减少噪音
AMLeakFinder.includedClassPrefixes = ["MyApp", "AMLeakDemo"]

// 可选：pop 后延迟检测时间，默认 2 秒
AMLeakFinder.checkDelay = 1.5

AMLeakFinder.start()
#endif
```

建议在 `AppDelegate` 或 Debug 菜单中调用 `start()`，**只需启动一次**。

### Objective-C

```objc
#if DEBUG
@import AMFlamingo;

[AMLeakFinder setIncludedClassPrefixes:@[@"MyApp"]];
[AMLeakFinder setCheckDelay:1.5];
[AMLeakFinder start];
#endif
```

### 手动登记子 VC

当父 VC 强引用子 VC，但 Runtime **扫描不到**（常见于 Swift `private` 属性、未 `addChild`）时：

```swift
AMLeakFinder.registerChildViewController(child, forParent: parent)
```

```objc
[AMLeakFinder registerChildViewController:child forParent:parent];
```

须在 **父页面仍处于监测中**（尚未 pop）时调用。

---

## 工作原理

1. **开始监测**：`push` / `setViewControllers` / `present` 时，对符合条件的 VC 创建 `AMLeakSnapshot`。
2. **记录关联**：
   - 页面展示期间，通过 Hook `addSubview` / `insertSubview` 记录动态添加的子视图；
   - pop 前收集候选子 VC（`childViewControllers`、ObjC 属性/ivar、视图推断、手动登记）。
3. **触发检测**：`pop` / `popTo` / `dismiss` 后，延迟 `checkDelay` 秒执行检测。
4. **输出报告**：在控制台搜索 `监测到内存泄露`。

### 监测范围过滤

默认 **不监测** 系统 VC，例如：

- `UINavigationController`、`UITabBarController`、`UIAlertController` 等
- 类名以 `UI` 开头（`UIHosting` 除外）
- 类名以 `_` 开头的私有系统类

若设置了 `includedClassPrefixes`，则 **仅监测类名前缀匹配** 的 VC（仍排除上述系统类）。

---

## 能检测到的情况

| 类型 | 说明 | 报告中的关联方式 |
|------|------|------------------|
| **页面自身泄漏** | pop / dismiss 后，被监测的 VC 仍未释放 | `[UIViewController] XXX 未被释放` |
| **子 VC 泄漏** | 父 VC 已释放，子 VC 仍存活 | `addChildViewController` / `property:xxx` / `inferredFromView` / `manualRegister` |
| **addChild 子控制器** | 通过 `addChildViewController` 挂载的子 VC | `addChildViewController` |
| **ObjC 可见属性/ivar** | `@objc` 或暴露给 Runtime 的 `UIViewController` 属性 | `property:属性名` |
| **仅 addSubview 子 view** | 子 VC 的 view 在层级中，可通过 Responder 链推断 owner | `inferredFromView (ViewClass)` |
| **手动登记** | 调用 `registerChildViewController(_:forParent:)` | `manualRegister` |
| **孤立 View 泄漏** | 页面已释放，但监测期间记录的 View 仍存活，且不属于仍存活的业务 VC | `[UIView] 孤立视图未被释放` |
| **挂到 UIWindow 的 View** | 当前顶层业务 VC 展示期间，`UIWindow` 上新增的 View（经 Hook 记录） | 归入孤立 View 检测 |

Example 工程内 **「AMLeakFinder 泄漏检测」** 提供 5 个可复现场景，可在 DEBUG 下对照控制台输出。

---

## 会遗漏的情况

以下场景 **无法保证检出**，请勿将其视为完整 Leak 检测方案：

### 1. 构建与生命周期

| 遗漏原因 | 说明 |
|----------|------|
| **Release 包** | 全部为 no-op，无任何检测 |
| **未走 Hook 的页面进出** | 未经过 `push` / `pop` / `present` / `dismiss` 的 VC（例如纯手动 `addChild` 容器内切换且从不 pop 父页）不会触发检测 |
| **从未被 start 监测** | 在 `AMLeakFinder.start()` 之前就已 push 的页面 |
| **checkDelay 内被释放** | 若对象在延迟窗口内才释放，不会报错；延迟过短可能误报，过长可能与其他对象混淆 |
| **stop 后** | `AMLeakFinder.stop()` 之后不再调度新的检测 |

### 2. 对象类型

| 遗漏原因 | 说明 |
|----------|------|
| **非 VC 泄漏** | `Model`、`Timer`、`DispatchSource`、闭包循环引用、单例缓存等 **不会检测** |
| **Delegate 循环引用** | 除非间接导致 VC 泄漏且满足下列条件，否则不报告 |
| **被过滤的 VC** | 系统 VC、前缀不匹配的 VC、`includedClassPrefixes` 范围外的 VC |

### 3. Swift / Runtime 扫描限制

| 遗漏原因 | 说明 |
|----------|------|
| **Swift private / fileprivate 属性** | 未暴露给 ObjC Runtime，**不会**被属性扫描发现；需 `registerChildViewController` |
| **纯 Swift 存储属性（无 @objc）** | 无法通过 `class_copyPropertyList` 读取 |
| **子 VC 藏在数组/字典里** | 如 `var children: [UIViewController]`，不会按单属性扫描 |
| **weak 引用未在候选列表** | 父页 pop 时若子 VC 未进入候选集，且之后被其他地方强引用，可能漏报 |

### 4. 视图追踪限制

| 遗漏原因 | 说明 |
|----------|------|
| **未走 Hook 的 add 方式** | 仅 Hook `addSubview` / `insertSubview:*`；若用其他方式挂载视图可能未记录 |
| **pop 前已 removeFromSuperview** | 从层级移除且未被静态持有的 View，不在快照中 |
| **loadView 之后、监测前创建的 View** | 仅同步 **监测开始时** 已存在的子视图；之后依赖 Hook 动态收录 |
| **系统/私有 UI 类 View** | `UILayout*`、`UIKeyboard*` 等前缀会被忽略，不参与孤立 View 检测 |

### 5. 结构与误报

| 遗漏/误报 | 说明 |
|-----------|------|
| **自定义转场 / 非 UINavigationController 栈** | 若未触发标准 pop Hook，可能不检测 |
| **Tab 切换、Present 栈中间页面** | 仅在被 pop/dismiss 时检测，切换 Tab 不会触发 |
| **短时误报** | 延迟检测窗口内若仍有合法强引用（动画、异步清理），可能短暂误报 |

---

## API 参考

| API | 说明 |
|-----|------|
| `start()` | 安装 Hook 并开始监测 |
| `stop()` | 停止监测（不卸载 Hook） |
| `isRunning` | 是否处于运行状态 |
| `checkDelay` | pop/dismiss 后延迟检测秒数，默认 `2.0` |
| `includedClassPrefixes` | 非空时只监测匹配前缀的 VC；空数组表示监测全部非系统 VC |
| `registerChildViewController(_:forParent:)` | 手动登记父子关系 |

---

## 报告示例

```
******** 监测到内存泄露 *****************

[UIViewController] MyDetailController 未被释放 (0x...)

**************************************
```

```
******** 监测到内存泄露 *****************

[UIViewController] MyListController 已释放，但子控制器未被释放:
- MyChildController (0x...)
  关联方式: addChildViewController

[UIView] 孤立视图未被释放（所属页面 MyListController 已释放）:
- MyOrphanView (0x...)
  层级:
    MyOrphanView (0x...)
    UIWindow (0x...)

**************************************
```

---

## 使用建议

1. **仅在 DEBUG 启用**，配合 Example 中 `AMLeakFinderDemoController` 理解各关联方式。
2. 业务 VC 建议统一前缀，并设置 `includedClassPrefixes` 降低系统页面干扰。
3. Swift 中 `private` 强引用子 VC 时，在合适时机调用 `registerChildViewController`。
4. 将 `checkDelay` 设为 `1.5 ~ 3.0` 秒，在误报与漏报之间折中。
5. 本工具是 **辅助手段**，不能替代 Instruments Leaks / Memory Graph 做全面分析。

---

## 相关文件

| 文件 | 职责 |
|------|------|
| `AMLeakFinder.swift` | 对外 API（DEBUG / Release 分支） |
| `AMLeakFinderEngine.swift` | 检测引擎、Runtime 扫描、报告 |
| `AMLeakFinderHooks.swift` | UIViewController / Nav / View Hook |
| `AMLeakSnapshot.swift` | 页面快照与视图追踪 |
| `AMLeakChildCandidate.swift` | 候选子 VC 及关联类型 |
