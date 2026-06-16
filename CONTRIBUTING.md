# Contributing to Vibe Ring

Forked from [open-vibe-island](https://github.com/Octane0411/open-vibe-island). Vibe Ring strips to 3 core agents (Claude Code, Codex, Hermes) and focuses on terminal-native workflows.

## Human Parts

We welcome all good ideas. Check the [Roadmap](docs/roadmap.md) to see where the project is heading and pick an area that interests you.

All code in this project is produced by AI. You should not contribute human-written code either.

### Getting Started

Paste this into your code agent to get oriented:

```
Please read this project's CLAUDE.md and CONTRIBUTING.md, then explain how I should iterate on this project.
```

## Agent Parts

### About the Project

Vibe Ring is a native macOS companion app for AI coding agents. It sits in the notch/top-bar area, monitors local agent sessions, surfaces permission requests, answers questions, and provides "jump back" to the correct terminal context. Local-first, no server dependency.

**Supported agents**: Claude Code, Codex, Hermes

**Supported terminals**: Terminal.app, Ghostty, iTerm2, Warp, WezTerm, Kaku, cmux, tmux, Zellij

### Prerequisites

- macOS 14+
- Swift 6.2+
- Xcode (for app target)

### Build & Test

```bash
swift build
swift test
swift run VibeRingApp
swift build -c release --product VibeRingHooks
```

Open `Package.swift` in Xcode to build and run the app target directly.

### Where to Go Next

- [`CLAUDE.md`](CLAUDE.md) — Architecture, conventions, branching rules, commit policy
- [`docs/architecture.md`](docs/architecture.md) — System design and engineering decisions
- [`docs/hooks.md`](docs/hooks.md) — Supported hook events, payload fields, and directive protocol
