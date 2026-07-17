# Codex 用量

一个 macOS 桌面小组件，用于显示 Codex 剩余用量、已用比例和重置时间。

它会读取本机 `~/.codex` 下 Codex 会话日志里的 `rate_limits` 字段，不需要账号密码，也不会上传任何数据。

## 下载使用

1. 到 GitHub Releases 下载 `Codex用量.zip`。
2. 解压后打开 `Codex 用量.app`。
3. 如果 macOS 提示无法验证开发者，右键点击 App，选择“打开”。

启动后会出现一个桌面小组件，并在菜单栏显示一个闪电图标。菜单栏可以刷新、显示/隐藏、退出。

## 功能

- 显示 Codex 剩余用量百分比
- 显示已用百分比
- 显示真实重置时间
- 每 20 秒后台刷新
- 桌面层级显示，不遮挡激活窗口
- 支持拖动位置
- 菜单栏控制

## 数据来源

优先读取：

```text
~/.codex/**/*.jsonl
```

并从最新日志中的字段解析：

```json
{
  "rate_limits": {
    "primary": {
      "used_percent": 15.0,
      "resets_at": 1785295869
    }
  }
}
```

如果没有找到 Codex 日志，会回退读取：

```text
~/Library/Application Support/CodexUsageWidget/usage.json
~/.codex/usage-widget.json
```

## 本地构建

需要 macOS 和 Xcode Command Line Tools。

```bash
chmod +x build.sh
./build.sh
open "Codex 用量.app"
```

构建脚本会生成：

```text
Codex 用量.app
```

## 手动写入测试数据

```bash
chmod +x codex-usage-set.sh
./codex-usage-set.sh 86 "7月20日 09:18 重置" "Codex"
```

注意：真实 Codex 日志存在时，App 会优先显示真实日志数据。

## 发布

生成可上传 GitHub Release 的 zip：

```bash
./scripts/package-release.sh
```

输出：

```text
dist/Codex用量.zip
```

## 隐私

这个 App 只在本机读取 `~/.codex` 日志中的用量字段，不读取 `auth.json`，不联网，不上传数据。
