---
name: sync-wt
description: Sync the exact current local wt checkout and the remote-browser-smoke-test personal Codex skill to reachable dellserver and cozee-devbox hosts without pulling or using repository main. Use when asked to synchronize, deploy, or test the local wt build on the remote machine.
---

# Sync wt

Check `dellserver` and `cozee-devbox` once each via non-interactive SSH with
a five-second connection timeout. For each reachable host, copy the personal
`remote-browser-smoke-test` skill into `~/.codex/skills`, then deploy the
current `~/dev/wt` working tree to `~/.wt` with this skill's script.
Skip unavailable hosts. If neither is reachable, or any reachable host fails
to sync, report the failure and stop; a failed sync does not prevent trying
the remaining host. The skill
uses a locked backup/swap with rollback; the remote Git clone is replaced by a
separate transactionally staged copy of the local tree. No fetch, pull, merge,
commit, or push is part of this workflow.

Run from this skill directory (the script is bundled here, not in the wt repo):

```bash
scripts/sync-wt
```

Use `scripts/sync-wt --dry-run` when the user asks to preview or validate the
snapshot without changing the remote host. Optional overrides are
`--source <path>` and `--host <ssh-host>`. An explicit `--host` or
`WT_SYNC_HOST` targets only that host and fails if unavailable; it does not
fall back to another server. Dry runs check reachability but change neither
host.

Use `scripts/sync-wt --skills-only` when only the personal Codex skill needs
updating. The skill directory is dereferenced while archiving so a Mac-only
symlink cannot become a broken link on Linux. The checksum and `SKILL.md` are
verified before the exact matching remote skill directory is replaced.

The script deliberately includes tracked files plus untracked non-ignored
files, so the remote runs the code being tested rather than just `HEAD`.
Ignored files, `.git`, and `node_modules` are not transferred. It recreates
Git metadata from a bundle of the local `HEAD`, reuses remote dependencies
when `bun.lock` is unchanged, validates the staged tree, swaps it into
`~/.wt`, and restores the old directory if the final probe fails. The remote
config must set `[instance] role = "worker"`; the final probe verifies that
role, worker protocol 2, and the exact local HEAD/dirty build identity.

Only run the mutating form when the user has asked to sync/update/deploy wt or
this personal skill; otherwise explain or use `--dry-run`. After a wt deploy,
tell the user to restart any already-running wt TUI so it cannot retain modules
from the prior build. A copied skill is available to newly started Codex
sessions.
