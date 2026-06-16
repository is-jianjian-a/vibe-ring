# Vibe Ring

**开源、本地优先、原生 macOS AI 编码助手伴侣。**

Vibe Ring 驻留在 Mac 的刘海（或顶栏），给你一个实时控制面——会话状态、权限审批、一键跳回正确的终端窗口。不用离开心流。

> Forked from [open-vibe-island](https://github.com/Octane0411/open-vibe-island)，精简为核心三 Agent 形态。

## 为什么用 Vibe Ring

- **开源** — GPL v3，Fork 它，改它，发布你自己的版本
- **本地优先** — 无服务器、无遥测、无账号。一切跑在你的 Mac 上
- **原生 macOS** — SwiftUI + AppKit，不是 Electron 套壳
- **多 Agent 一屏** — Claude Code、Codex、Hermes，一个环里全看到
- **纯终端** — 一键跳回正确的终端窗口，不跟 IDE 绑定

## 支持的 Agent

| Agent | 探测方式 | 审批 | 问答 | 跳转 |
|-------|---------|------|------|------|
| **Claude Code** | Hook 注入（14 个事件） + `ps` 进程发现 | ✅ | ✅ | 🎯 终端 |
| **Codex** | Hook 注入 + Codex.app 深度集成 | ✅ | — | 🎯 终端 / `codex://` |
| **Hermes** | SQLite 直读 `~/.hermes/state.db`（5s 轮询） | — | — | 🌐 浏览器 |

## 支持的终端

**独立终端**：Terminal.app、Ghostty、iTerm2、Warp、WezTerm、Kaku、cmux

**多路复用**：tmux、Zellij

## 快速开始

### 从源码构建

```bash
git clone https://github.com/is-jianjian-a/vibe-ring.git
cd vibe-ring
swift build && swift run VibeRingApp
```

> **环境要求**：macOS 14+，Swift 6.2

首次启动后，Vibe Ring 自动发现活跃的 Agent 会话并启动实时桥接。Hook 安装通过应用内的 **Settings** 窗口管理。

## 工作原理

```
Agent 进程 (Claude Code / Codex / Hermes)
  ↓ hook 事件 / SQLite 轮询
VibeRingHooks CLI (stdin → Unix socket)
  ↓ JSON envelope
BridgeServer (app 内)
  ↓ 状态更新
刘海覆盖层 UI ← 你在这里看到
  ↓ 点击会话
跳回 → 正确的终端窗口
```

Hook **fail open** — 即使 Vibe Ring 不运行，你的 Agent 也照常工作，不受影响。

## License

[GPL v3](LICENSE)
