# Agent files

Run `bash link-dotfiles.sh` from this repository to link the selected files.
To link only the agent files, run `python3 scripts/link-agent-config.py`.
The script keeps previous files in `~/.local/state/dotfiles/backups/`.

| Repository path | Installed path | Use |
| --- | --- | --- |
| `codex/AGENTS.md` | `~/.codex/AGENTS.md` | Global instructions, including the wt-managed block |
| `skills/<name>/` | `~/.codex/skills/<name>/` | User skills and their scripts and references |
| `agent-skills/<name>/` | `~/.agents/skills/<name>/` | Other user skills |
| `wt/config.toml` | `~/.config/wt/config.toml` | Global wt settings |
| `codex/settings.toml` | Copy to `~/.codex/config.toml` on a new machine | Selected Codex settings and PR instructions |

The live Codex config stays local. Codex writes project trust entries, app
runtime paths, and other local state to it. The settings copy includes model,
editor appearance, PR instructions, plugin choices, and selected MCP servers.
It does not include credentials, environment variables, or project trust entries.
Refresh it with `python3.12 scripts/export-codex-settings.py` before a commit.
Python 3.11 or later is sufficient; older Python versions need `tomli`.
On a new machine, the link script copies this file only if no live config exists.
Sign in to Codex and each connected service on that machine.

Codex system skills and plugin caches stay local. The `~/.agents/skills/`
files marked `wt-managed` also stay local; wt maintains them from its own source.
The copied user skills include the installed Cloudflare references. The
`optimise-github-actions` skill now lives here instead of `~/Downloads/dotfiles`.
When you add a user skill to `skills/` or `agent-skills/`, run the link script again.

History, sessions, databases, logs, attachments, automation run state, generated
permission rules, and `~/.config/wt/secrets/` stay outside this repository.
The wt config uses repository `.wt.toml` files for paths such as `main_clone`
and `worktree_root`; run wt inside a configured repository.
