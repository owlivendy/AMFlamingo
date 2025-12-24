# Fastlane 使用说明 & 工具链安装教程

## 一、Fastlane 简介

Fastlane 是一款自动化工具，主要用于 iOS/Android 项目的打包、签名、上传分发等流程自动化。它可以极大提升开发、测试、运维的效率，减少重复性工作。

---

## 二、环境准备

### 1. 安装 Homebrew（如未安装）

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 2. 安装 Ruby（macOS 自带 Ruby，建议升级到新版本）

推荐用 Homebrew 安装：

```bash
brew install ruby
```

安装后可将 Ruby 路径加入环境变量（如有需要）：

```bash
echo 'export PATH="/opt/homebrew/opt/ruby/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

### 3. 安装 Bundler

```bash
gem install bundler
```

### 4. 安装 Fastlane

**推荐使用 bundle 方式安装 fastlane，因为项目中有 Gemfile，这样可以统一和管理依赖，避免全局依赖冲突。**

在项目根目录下执行：

```bash
bundle install
```

安装完成后，使用 fastlane 命令时建议加上 `bundle exec`，例如：

```bash
fastlane build2pg message:"更新内容"
```

### 5. 安装蒲公英插件（如需上传到蒲公英）

```bash
fastlane add_plugin pgyer
```

---

## 四、常用命令

### 1. 查看所有可用 lane

```bash
fastlane lanes
```

### 2. 执行打包上传蒲公英（以 build2pg 为例）

```bash
fastlane build2pg message:"1.修复xxx\n2.优化yyy"
```

- `message` 参数为必填，填写本次更新内容（支持多行，推荐用单引号或变量传递多行内容）。
- 如需指定测试环境，可加参数：`env:dev`

---

## 五、常见问题

1. **找不到 fastlane 命令？**
   - 检查 Ruby 和 fastlane 是否已正确安装，或用 `bundle exec fastlane` 代替。

2. **打包报签名/描述文件错误？**
   - 检查 Xcode 配置、证书、描述文件、scheme、configuration 是否正确。

3. **ENV 宏未生效？**
   - 确认 target 级别 Preprocessor Macros 配置了 `ENV=$(ENV)`，并且 fastlane xcargs 注入了 ENV。

4. **蒲公英上传失败？**
   - 检查 API Key 是否正确，网络是否畅通，或升级 fastlane 及 pgyer 插件。

---

## 六、参考文档

- [Fastlane 官方文档](https://docs.fastlane.tools/)
- [蒲公英 Fastlane 插件文档](https://www.pgyer.com/doc/view/fastlane)
- [Homebrew 官网](https://brew.sh/)

---
