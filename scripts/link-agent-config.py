#!/usr/bin/env python3
"""Link selected agent files. Keep existing files in a local backup."""

from datetime import datetime
from pathlib import Path
import shutil

REPO = Path(__file__).resolve().parents[1]
HOME_DIR = Path.home()


def main():
    backup = HOME_DIR / ".local/state/dotfiles/backups" / datetime.now().strftime("%Y%m%d-%H%M%S-%f")
    links = [
        (REPO / "codex/AGENTS.md", HOME_DIR / ".codex/AGENTS.md"),
        (REPO / "wt/config.toml", HOME_DIR / ".config/wt/config.toml"),
    ]
    for source_dir, target_dir in [
        (REPO / "skills", HOME_DIR / ".codex/skills"),
        (REPO / "agent-skills", HOME_DIR / ".agents/skills"),
    ]:
        links.extend((source, target_dir / source.name) for source in sorted(source_dir.iterdir())
                     if (source / "SKILL.md").is_file())
    for source, target in links:
        if target.is_symlink() and target.resolve() == source.resolve():
            continue
        target.parent.mkdir(parents=True, exist_ok=True)
        if target.exists() or target.is_symlink():
            saved = backup / target.relative_to(HOME_DIR)
            saved.parent.mkdir(parents=True, exist_ok=True)
            target.rename(saved)
        target.symlink_to(source, target_is_directory=source.is_dir())
        print(f"Linked {target.relative_to(HOME_DIR)}")
    config = HOME_DIR / ".codex/config.toml"
    if not config.exists():
        shutil.copy2(REPO / "codex/settings.toml", config)
        config.chmod(0o600)
        print("Created a local Codex config from selected settings")
    if backup.exists():
        print(f"Previous files are in {backup}")


if __name__ == "__main__":
    main()
