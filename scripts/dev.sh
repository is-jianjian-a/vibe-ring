#!/bin/zsh
# dev.sh — 一键重启 Vibe Ring App
# 用法: ./scripts/dev.sh
#
# 做的事：
# 1. kill 旧进程
# 2. swift build
# 3. 启动新进程

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

APP_NAME="VibeRingApp"

echo "==> 检查并停止旧进程..."
PIDS=$(pgrep -f "$APP_NAME" 2>/dev/null || true)
if [[ -n "$PIDS" ]]; then
    echo "    发现旧进程: $PIDS"
    echo "$PIDS" | while read pid; do
        [[ -n "$pid" ]] && { kill "$pid" 2>/dev/null && echo "    已终止 PID $pid" || true; }
    done
    sleep 0.5
else
    echo "    没有旧进程在跑"
fi

echo "==> 编译中..."
if swift build 2>&1 | tail -5; then
    echo "==> 编译通过，启动..."
    swift run "$APP_NAME" &
    sleep 1.5
    if pgrep -f "$APP_NAME" > /dev/null 2>&1; then
        echo "==> ✅ Vibe Ring 已启动"
    else
        echo "==> ❌ 进程未能启动"
    fi
else
    echo "==> ❌ 编译失败"
    exit 1
fi
