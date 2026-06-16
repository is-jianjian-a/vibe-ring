# AGENTS

This file defines the working agreement for the coding agent in this repository.

## Goal

Keep all work incremental, reviewable, and reversible. Every meaningful round of changes must end with a Git commit so commits become the control surface for progress, rollback, and review.

## Required Workflow

1. Start each round by checking the current repository state with `git status -sb`.
2. Enter a topic worktree on a feature branch before editing. Do not edit files directly in the shared `main` worktree.
3. Read the relevant files before editing. Do not guess repository structure or behavior.
4. Keep each round focused on a single coherent change.
5. After making changes, run the most relevant verification available for that round.
6. Summarize what changed, including any verification gaps.
7. Commit the round on the feature branch before stopping.

## Commit Policy

- Every round that modifies files must end with a commit.
- Do not batch unrelated changes into one commit.
- Use clear conventional-style commit messages such as `feat:`, `fix:`, `refactor:`, `docs:`, or `chore:`.
- Do not amend existing commits unless explicitly requested.
- Create a feature branch for every independent change. Do not commit directly to `main`.
- Push feature branches and open PRs when the user asks for remote review or integration.
- When the user asks to open or submit a PR, open a normal ready-for-review PR by default.
- All PRs target `main`. Do not chain PRs through another feature branch unless explicitly requested.

## Safety Rules

- Never revert or overwrite user changes unless explicitly requested.
- If unexpected changes appear, inspect them and work around them when possible.
- If a conflict makes the task ambiguous or risky, stop and ask before proceeding.
- Never use destructive Git commands such as `git reset --hard` without explicit approval.

## Engineering Rules

- Prefer small end-to-end slices over large speculative scaffolding.
- Preserve a clean working tree after each round.
- Add documentation when making architectural or workflow decisions.
- Prefer native macOS and Swift-friendly project structure for this repository.

## Branching And Worktree Rules

- Never edit, commit, or push directly on `main`. All changes must go through a feature branch and PR.
- Create one worktree per branch and one branch per worktree.
- Create new worktrees from `origin/main`.
- Use branch names that match the workstream: `feat/<topic>`, `fix/<topic>`, `docs/<topic>`.
- Keep each worktree focused on one coherent slice with a narrow file ownership area.
- Rebase or merge the latest `origin/main` into the feature branch before integrating it back.
- Integrate completed work through a PR targeting `main`.
- Remove merged worktrees and delete merged branches after integration.

## Product Boundaries

- Vibe Ring supports 3 agents: Claude Code, Codex, Hermes.
- Do not broaden the agent set unless the user explicitly asks.
- Keep hook behavior aligned with `docs/hooks.md` and the implementation in `Sources/VibeRingCore`.

## Integration Guardrails

- Treat **Codex CLI** and **Codex Desktop App** as distinct runtime surfaces.
- Keep Claude-family integrations source-specific, even when payload formats are shared.
- Hermes is read-only SQLite polling — no hook installation needed.

## App Targets And Naming

- `VibeRingApp` is the canonical OSS app runtime.
- `swift run VibeRingApp` and the Xcode app target are the source-of-truth way to run the current branch's app code.
- `~/Applications/Vibe Ring Dev.app` is a local dev bundle wrapper, not a separate product.
- When launching the dev app, refresh the bundle first with `zsh scripts/launch-dev-app.sh`.
- For Accessibility/TCC-sensitive work, run `zsh scripts/setup-dev-signing.sh` once.

## Verification

- Run `swift build` and `swift test` after changes.
- If no automated verification exists yet, state that explicitly in the summary and still commit.

## Default Expectation

Unless the user says otherwise, finish each completed round in this order:

1. implement
2. verify
3. summarize
4. commit
