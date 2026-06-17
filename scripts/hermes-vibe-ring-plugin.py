#!/usr/bin/env python3
"""
Vibe Ring — Hermes Plugin

Installs lifecycle hooks inside Hermes Agent that forward session events
(session start/end, tool calls, approval requests) to the Vibe Ring
macOS companion app in real time over a Unix domain socket.

Installation:
    1. Copy this file to ~/.hermes/plugins/vibe_ring/
    2. Add the plugin directory to your hermes config:

       [plugins]
       paths = ["~/.hermes/plugins/vibe_ring"]

    3. Or let `VibeRingSetup install-hermes-plugin` do it for you.

Design:
    - Observer-only — return values are ignored by Hermes (except pre_llm_call
      context injection, which we don't use).  A crash in this plugin won't
      break the agent.
    - The bridge socket is a Unix domain socket at
      ~/Library/Application Support/VibeRing/bridge.sock.
    - If the bridge is unavailable, events are silently dropped (fail-open).
    - JSON line protocol — same as the Hooks CLI / BridgeCodec in Swift.
"""

from __future__ import annotations

import json
import os
import socket
import sys
from datetime import datetime, timezone
from typing import Any

# ---------------------------------------------------------------------------
# Bridge client
# ---------------------------------------------------------------------------

BRIDGE_SOCKET = os.path.join(
    os.environ.get(
        "VIBE_RING_SOCKET_PATH",
        os.path.join(
            os.path.expanduser("~/Library/Application Support"),
            "VibeRing",
            "bridge.sock",
        ),
    )
)

BRIDGE_TIMEOUT = 5.0  # seconds — non-blocking observer; don't stall the agent


def _send_bridge_envelope(event_type: str, payload: dict[str, Any]) -> None:
    """Encode and send a single event envelope to the Vibe Ring bridge."""
    envelope = {
        "type": "command",
        "command": {
            "type": "processHermesPlugin",
            "hermesPlugin": {
                "hook_event_name": event_type,
                **payload,
            },
        },
    }

    try:
        encoded = json.dumps(envelope, default=str) + "\n"
    except (TypeError, ValueError):
        return

    try:
        sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        sock.settimeout(BRIDGE_TIMEOUT)
        sock.connect(BRIDGE_SOCKET)
        sock.sendall(encoded.encode("utf-8"))
        # Read the acknowledgement — if the bridge is healthy it responds
        # quickly; we don't block the agent waiting for it though.
        try:
            sock.settimeout(0.5)
            sock.recv(4096)
        except (socket.timeout, OSError):
            pass
        finally:
            sock.close()
    except (socket.error, OSError):
        # Bridge unavailable — fail open, let the agent keep running.
        pass


# ---------------------------------------------------------------------------
# Plugin registration
# ---------------------------------------------------------------------------


def register(ctx: Any) -> None:
    """Register hook callbacks with the Hermes plugin system.

    Called once when Hermes loads this plugin.  We register hooks for
    the lifecycle events that matter to Vibe Ring's session display.
    """
    ctx.register_hook("on_session_start", _on_session_start)
    ctx.register_hook("on_session_end", _on_session_end)
    ctx.register_hook("pre_tool_call", _on_pre_tool_call)
    # pre_approval_request fires inside check_all_command_guards before the
    # user is prompted — ideal for surfacing permission requests in the island.
    if hasattr(ctx, "register_hook"):
        try:
            ctx.register_hook("pre_approval_request", _on_approval_request)
            ctx.register_hook("post_approval_response", _on_approval_response)
        except Exception:
            # Older Hermes versions may not have these hooks yet.
            pass


# ---------------------------------------------------------------------------
# Hook callbacks
# ---------------------------------------------------------------------------


def _on_session_start(
    session_id: str,
    model: str = "",
    platform: str = "",
    **kwargs: Any,
) -> None:
    title = _derive_title(session_id=session_id, model=model, platform=platform)
    _send_bridge_envelope(
        "session_start",
        {
            "session_id": session_id,
            "model": model or None,
            "session_title": title,
        },
    )


def _on_session_end(
    session_id: str,
    completed: bool = False,
    interrupted: bool = False,
    model: str = "",
    platform: str = "",
    **kwargs: Any,
) -> None:
    _send_bridge_envelope(
        "session_end",
        {
            "session_id": session_id,
            "completed": completed,
            "interrupted": interrupted,
            "model": model or None,
        },
    )


def _on_pre_tool_call(
    tool_name: str,
    args: dict[str, Any],
    task_id: str = "",
    **kwargs: Any,
) -> None:
    session_id = task_id or _infer_session(**kwargs)
    if not session_id:
        return

    args_preview = _safe_truncate(json.dumps(args, default=str), 200)
    _send_bridge_envelope(
        "tool_call",
        {
            "session_id": session_id,
            "tool_name": tool_name,
            "tool_args": args_preview,
        },
    )


def _on_approval_request(
    command: str = "",
    description: str = "",
    session_key: str = "",
    surface: str = "",
    **kwargs: Any,
) -> None:
    if not session_key:
        return

    _send_bridge_envelope(
        "approval_request",
        {
            "session_id": session_key,
            "command": _safe_truncate(command, 500),
            "description": description or f"Hermes wants to run a command.",
        },
    )


def _on_approval_response(
    command: str = "",
    choice: str = "",
    session_key: str = "",
    **kwargs: Any,
) -> None:
    if not session_key:
        return

    _send_bridge_envelope(
        "approval_response",
        {
            "session_id": session_key,
            "command": _safe_truncate(command, 500),
            "choice": choice,
        },
    )


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _derive_title(
    session_id: str,
    model: str = "",
    platform: str = "",
) -> str:
    """Build a human-readable session title from available context."""
    parts: list[str] = []
    if platform and platform.lower() not in ("", "cli", "unknown"):
        parts.append(platform.title())
    if model:
        parts.append(model)
    if not parts:
        parts.append("Hermes")
    return " · ".join(parts)


def _infer_session(**kwargs: Any) -> str:
    """Best-effort session ID extraction for hooks that don't pass it explicitly."""
    for key in ("session_id", "task_id", "session_key"):
        val = kwargs.get(key)
        if isinstance(val, str) and val:
            return val
    return ""


def _safe_truncate(text: str, max_len: int) -> str:
    """Truncate text to max_len chars, appending '…' if cut."""
    if len(text) <= max_len:
        return text
    return text[: max_len - 1] + "…"
