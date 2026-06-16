# Vibe Ring — Quick Start

## 跑起来

```bash
cd /path/to/vibe-ring
swift build && swift run VibeRingApp
```

菜单栏出现环形图标 → 点开面板。

## 装上 Agent Hook

打开面板 → Settings → Setup → 打开你要监控的 Agent 开关（Claude Code / Codex）。

装完 Hook 后，在终端里正常使用 Agent，Vibe Ring 自动感知。

## Hermes

你已经在运行的 Hermes CLI（`hermes -p work`）会被自动检测到——Vibe Ring 直接读 `~/.hermes/state.db`，不需要额外配置。
