#!/usr/bin/env python3
"""Save selected Codex settings without local state or credentials."""

import json
from pathlib import Path

try:
    import tomllib
except ImportError:
    import tomli as tomllib

REPO = Path(__file__).resolve().parents[1]
SOURCE = Path.home() / ".codex/config.toml"
ROOT_KEYS = (
    "model", "model_reasoning_effort", "personality", "service_tier",
    "approvals_reviewer", "approval_policy", "sandbox_mode",
    "project_doc_max_bytes", "project_doc_fallback_filenames",
)
DESKTOP_KEYS = (
    "appearanceLightCodeThemeId", "appearanceDarkCodeThemeId",
    "usePointerCursors", "git-branch-prefix", "git-create-pull-request-as-draft",
    "git-show-sidebar-pr-icons", "git-pr-instructions",
    "keepRemoteControlAwakeWhilePluggedIn", "followUpQueueMode",
    "dock-icon-preference", "conversationDetailMode",
    "appearanceLightChromeTheme", "appearanceDarkChromeTheme",
)
# The app manages its computer-use servers and runtime paths.
MCP_NAMES = ("graphite", "openaiDeveloperDocs", "supabase", "executor", "cozee")
MCP_KEYS = ("command", "args", "url", "enabled", "startup_timeout_sec")


def select(data, keys):
    return {key: data[key] for key in keys if key in data}


def value(item):
    if isinstance(item, bool):
        return "true" if item else "false"
    if isinstance(item, (str, int, float)):
        return json.dumps(item, ensure_ascii=False)
    if isinstance(item, list):
        return "[" + ", ".join(value(element) for element in item) + "]"
    raise TypeError(f"Unsupported setting type: {type(item).__name__}")


def table(data, path=()):
    lines = []
    if path:
        lines.append("[" + ".".join(json.dumps(key) for key in path) + "]")
    for key, item in data.items():
        if not isinstance(item, dict):
            lines.append(f"{json.dumps(key)} = {value(item)}")
    for key, item in data.items():
        if isinstance(item, dict):
            lines.extend(["", *table(item, path + (key,))])
    return lines


def main():
    data = tomllib.loads(SOURCE.read_text())
    result = select(data, ROOT_KEYS)
    result["features"] = select(data.get("features", {}), ("multi_agent", "js_repl"))
    result["tui"] = select(data.get("tui", {}), ("animations", "theme"))
    result["desktop"] = select(data.get("desktop", {}), DESKTOP_KEYS)
    result["plugins"] = {
        name: select(config, ("enabled",))
        for name, config in data.get("plugins", {}).items()
    }
    result["mcp_servers"] = {
        name: select(data["mcp_servers"][name], MCP_KEYS)
        for name in MCP_NAMES if name in data.get("mcp_servers", {})
    }
    # Stop if an endpoint includes credentials in its URL.
    from urllib.parse import urlsplit, parse_qsl
    for name, config in result["mcp_servers"].items():
        url = urlsplit(config.get("url", ""))
        if url.username or url.password or any(
            any(word in key.lower() for word in ("token", "secret", "password", "key"))
            for key, _ in parse_qsl(url.query)
        ):
            raise ValueError(f"Remove credentials from the {name} server URL before export")
    output = "# Selected user settings. Refresh with scripts/export-codex-settings.py.\n"
    output += "\n".join(table(result)) + "\n"
    assert tomllib.loads(output) == result
    destination = REPO / "codex/settings.toml"
    destination.write_text(output)
    print(f"Saved selected settings to {destination}")


if __name__ == "__main__":
    main()
