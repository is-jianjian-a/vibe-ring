# 为 Vibe Ring 做贡献

> Forked from [open-vibe-island](https://github.com/Octane0411/open-vibe-island)。Vibe Ring 精简为 3 个核心 Agent，专注终端原生工作流。

## Human Parts

我们欢迎一切好的想法。查看[路线图](docs/roadmap.md)了解项目方向。

本项目所有代码均由 AI 产出，因此你也不应该贡献人类产出的代码。

### 如何开始

在你的 code agent 中输入：

```
帮我阅读这个项目的 CLAUDE.md 和 CONTRIBUTING.md，然后说明我应该如何迭代这个项目。
```

## Agent Parts

### 项目简介

Vibe Ring 是一个原生 macOS 应用，作为 AI 编码代理的桌面伴侣。驻留在刘海/顶栏区域，监控本地代理会话、展示权限请求、回答问题，并提供一键跳回对应终端上下文。完全本地运行，无需服务端。

**支持的 Agent**：Claude Code、Codex、Hermes

**支持的终端**：Terminal.app、Ghostty、iTerm2、Warp、WezTerm、Kaku、cmux、tmux、Zellij

### 环境要求

- macOS 14+
- Swift 6.2+
- Xcode（用于 app target）

### 构建与测试

```bash
swift build
swift test
swift run VibeRingApp
swift build -c release --product VibeRingHooks
```

可以在 Xcode 中打开 `Package.swift`，直接构建和运行应用。

### 进一步了解

- [`CLAUDE.md`](CLAUDE.md) — 架构、代码规范、分支规则、提交规范
- [`docs/architecture.md`](docs/architecture.md) — 系统设计与工程决策
- [`docs/hooks.md`](docs/hooks.md) — 支持的 Hook 事件、Payload 字段、指令协议
