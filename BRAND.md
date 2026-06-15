# Vibe Ring — Brand Notes

## 名字

**vibe-ring**

## 意象

一个环绕的环，三层含义：

1. **Ring = 菜单栏里的闭合岛环** — 物理形态。一个环形 UI 驻留在屏幕顶部/刘海区域
2. **Ring = 铃声提醒** — 功能直觉。Agent 卡审批、做完任务、需要你输入时，ring 一下
3. **Ring = 环绕伴随** — 最深的一层。Ring 环绕整个屏幕，像一个安静的守护者，和你一起注视屏幕。它不抢焦点、不弹窗喧哗，只是在边缘存在，让你随时感知 Agent 的状态。**这是一种"伴随态"，不是"打扰态"**

## 核心设计原则

- **本地优先** — 无服务器、无账号、无遥测
- **伴随而非打扰** — Ring 在边缘呼吸，不抢占焦点
- **多 Agent 统一** — Claude Code、Codex、Gemini CLI、Cursor、OpenCode、Hermes... 都在一个环里
- **感知优先于管理** — 第一目标是让你"感到"Agent 的状态，第二目标才是去操作它
- **精准跳转** — 需要操作时，一键回到正确的终端/IDE/浏览器窗口

## 产品形态

- macOS 原生 App（SwiftUI + AppKit）
- 驻留在菜单栏 / 刘海区域
- 展开面板显示 Agent 会话列表
- 支持桌面通知、未来可扩展手机推送

## 为什么要 Fork

vibe-ring 基于 vibe-ring 的架构，但有自己的方向：
- 增强即时终端检测（从 open-island fork 嫁入）
- 新增 Hermes Agent 支持（HTTP API 轮询）
- 未来计划：四象限优先级、FIFO 队列、远程审批
