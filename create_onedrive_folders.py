#!/usr/bin/env python3
"""
create_onedrive_folders.py

Default (dry-run): detects local OneDrive path, prints plan, writes report_plan.csv.
--apply           : creates the folders for real.
--path PATH       : override auto-detected OneDrive root.

No cloud API, no login, no internet required.
"""

import argparse
import csv
import glob
import sys
from pathlib import Path

FOLDERS = [
    "01_Arbeit",
    "02_Organisation",
    "03_Schule & Familie",
    "04_Projekte",
    "05_Technik & Tools",
    "99_Eingang (temporär!)",
]

# Safety allowlist: only folders listed here may ever be removed if empty.
# (Currently unused – no deletions in this script.)
REMOVABLE_EMPTY_FOLDERS: list[str] = []


def find_onedrive_root() -> Path | None:
    home = Path.home()
    candidates = sorted(
        glob.glob(str(home / "Library" / "CloudStorage" / "OneDrive*"))
        + glob.glob(str(home / "OneDrive*"))
    )
    for c in candidates:
        p = Path(c)
        if p.is_dir():
            return p
    return None


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Create top-level OneDrive folders locally (no cloud API)."
    )
    parser.add_argument(
        "--apply",
        action="store_true",
        help="Actually create the folders (default: dry-run only)",
    )
    parser.add_argument(
        "--path",
        metavar="DIR",
        help="Override auto-detected OneDrive root path",
    )
    args = parser.parse_args()

    # ── Resolve OneDrive root ─────────────────────────────────────────────────
    if args.path:
        root = Path(args.path).expanduser().resolve()
        if not root.is_dir():
            sys.exit(f"Error: path not found: {root}")
    else:
        root = find_onedrive_root()
        if root is None:
            sys.exit(
                "Could not auto-detect a local OneDrive folder.\n"
                "Searched:\n"
                "  ~/Library/CloudStorage/OneDrive*\n"
                "  ~/OneDrive*\n\n"
                "Use --path /path/to/your/OneDrive to specify it manually."
            )

    print(f"OneDrive root : {root}")
    print(f"Mode          : {'APPLY' if args.apply else 'DRY-run (use --apply to create)'}")
    print()

    # ── Build plan ────────────────────────────────────────────────────────────
    plan: list[dict] = []
    for name in FOLDERS:
        target = root / name
        exists = target.exists()
        action = "skip – already exists" if exists else "create"
        plan.append(
            {
                "folder": name,
                "full_path": str(target),
                "status": "exists" if exists else "missing",
                "action": action,
            }
        )
        marker = "✓" if exists else "+"
        print(f"  [{marker}] {name:<35}  → {action}")

    # ── Write CSV report (always, even in dry-run) ────────────────────────────
    csv_path = Path("report_plan.csv")
    with csv_path.open("w", newline="", encoding="utf-8") as fh:
        writer = csv.DictWriter(
            fh, fieldnames=["folder", "full_path", "status", "action"]
        )
        writer.writeheader()
        writer.writerows(plan)
    print(f"\nReport written → {csv_path.resolve()}")

    # ── Dry-run: stop here ────────────────────────────────────────────────────
    if not args.apply:
        print("\nDry-run complete. Re-run with --apply to create the missing folders.")
        return

    # ── Apply ─────────────────────────────────────────────────────────────────
    print("\nCreating folders …")
    created = skipped = 0
    for row in plan:
        if row["status"] == "exists":
            print(f"  –  {row['folder']}  (skipped)")
            skipped += 1
            continue
        Path(row["full_path"]).mkdir(parents=False, exist_ok=False)
        print(f"  ✓  {row['folder']}  created")
        created += 1

    print(f"\nDone. {created} folder(s) created, {skipped} skipped.")


if __name__ == "__main__":
    main()
