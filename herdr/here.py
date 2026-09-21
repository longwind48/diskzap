"""Format `diskzap --json` into a popup-sized summary for one directory.

Separate file rather than inlined in here.sh on purpose: piping JSON into
`python3 -` while also feeding it a heredoc makes Python read the heredoc as its
program and leaves nothing on stdin for json.load, which fails as the silent
"produced no output" path rather than as an error.

Usage:  diskzap --root DIR --no-external --json | python3 here.py DIR
"""

import json
import sys

BOLD, DIM, OFF = "\033[1m", "\033[2m", "\033[0m"


def human(n):
    for unit in ("B", "KB", "MB", "GB", "TB"):
        if n < 1024 or unit == "TB":
            return f"{n}B" if unit == "B" else f"{n:.1f}{unit}"
        n /= 1024


def main():
    cwd = sys.argv[1].rstrip("/")
    try:
        items = json.load(sys.stdin).get("items", [])
    except (json.JSONDecodeError, ValueError):
        print("\n  Could not read diskzap's output.\n")
        return

    # Keep only what lives under the directory in question. The same run also
    # resolves every global package cache, and attributing ~/.cache/uv to "this
    # folder" would be a lie — those belong to the full report.
    here = [
        i
        for i in items
        if i.get("bytes", 0) > 0 and i.get("path", "").startswith(cwd + "/")
    ]

    # here.sh prints the header before starting the scan, so the popup has
    # content immediately rather than a blank box. Don't print it twice.
    if not here:
        print("  Nothing reclaimable in this directory.")
        print()
        print(f"  {DIM}Build artifacts only — package caches live outside this tree.{OFF}")
        return

    print(f"  {BOLD}{human(sum(i['bytes'] for i in here))}{OFF} across {len(here)} item(s)")
    print()
    for i in sorted(here, key=lambda x: -x["bytes"])[:7]:
        rel = i["path"][len(cwd) + 1 :]
        if len(rel) > 46:
            rel = "…" + rel[-45:]
        print(f"    {human(i['bytes']):>9}  {rel}")
    if len(here) > 7:
        print(f"    {'':>9}  … and {len(here) - 7} more")



if __name__ == "__main__":
    main()
