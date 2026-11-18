from __future__ import annotations

import argparse
import shutil
from datetime import datetime
from pathlib import Path

BEGIN = "<!-- BEGIN HYBRIDBRAIN-OS MANAGED RULES -->"
END = "<!-- END HYBRIDBRAIN-OS MANAGED RULES -->"


def managed_block(source: Path) -> str:
    text = source.read_text(encoding="utf-8-sig")
    return f"{BEGIN}\n\n{text.strip()}\n\n{END}"


def backup_file(path: Path, stamp: str) -> Path | None:
    if not path.is_file():
        return None
    backup = path.with_name(f"{path.name}.bak_{stamp}")
    if not backup.exists():
        shutil.copy2(path, backup)
    return backup


def merge_rules(path: Path, block: str, stamp: str) -> str:
    current = path.read_text(encoding="utf-8-sig") if path.exists() else ""
    start = current.find(BEGIN)
    end = current.find(END, start + len(BEGIN)) if start >= 0 else -1
    if start >= 0 and end >= 0:
        updated = current[:start].rstrip() + "\n\n" + block + current[end + len(END):]
    else:
        updated = current.rstrip() + ("\n\n" if current.strip() else "") + block + "\n"
    if updated == current:
        return "unchanged"
    backup_file(path, stamp)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(updated, encoding="utf-8", newline="\n")
    return "updated" if current else "created"


def sync_skill(source: Path, target: Path, stamp: str) -> str:
    if not source.is_dir():
        raise FileNotFoundError(f"Skill source does not exist: {source}")
    existed = target.exists()
    if existed:
        source_files = [p for p in source.rglob("*") if p.is_file()]
        same = all(
            (target / p.relative_to(source)).is_file()
            and (target / p.relative_to(source)).read_bytes() == p.read_bytes()
            for p in source_files
        ) and not any(
            p.is_file() and not (source / p.relative_to(target)).exists()
            for p in target.rglob("*")
        )
        if same:
            return "unchanged"
        backup = target.with_name(f"{target.name}.bak_{stamp}")
        if not backup.exists():
            shutil.copytree(target, backup)
    shutil.copytree(source, target, dirs_exist_ok=True)
    return "updated" if existed else "created"


def main() -> int:
    parser = argparse.ArgumentParser(description="Back up and sync HybridBrain-OS rules and skill to installed clients.")
    parser.add_argument("--dry-run", action="store_true", help="Show client targets without writing.")
    args = parser.parse_args()

    root = Path(__file__).resolve().parent
    rule_source = root / "brain" / "AGENTS.md"
    skill_source = root / "skills" / "local-llm-offload"
    if not rule_source.is_file() or not skill_source.is_dir():
        parser.error("Expected brain/AGENTS.md and skills/local-llm-offload/ inside this project.")
    block = managed_block(rule_source)
    home = Path.home()
    clients = [
        ("Codex CLI", home / ".codex", "AGENTS.md"),
        ("Claude Code", home / ".claude", "CLAUDE.md"),
        ("Gemini / Antigravity", home / ".gemini", "GEMINI.md"),
        ("WorkBuddy", home / ".workbuddy", "AGENTS.md"),
    ]
    stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    synced = 0
    for name, base, rule_name in clients:
        if not base.is_dir():
            print(f"SKIP {name}: client directory not found")
            continue
        if args.dry_run:
            print(f"PLAN {name}: rule file + local-llm-offload skill")
            continue
        status = merge_rules(base / rule_name, block, stamp)
        skill_status = sync_skill(skill_source, base / "skills" / "local-llm-offload", stamp)
        print(f"{name}: rules={status}; skill={skill_status}")
        synced += 1
    if args.dry_run:
        print("Dry run complete; no files changed.")
    else:
        print(f"Client sync complete ({synced} installed client(s)).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
