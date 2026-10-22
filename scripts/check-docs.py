#!/usr/bin/env python3
"""Check repository-local Markdown links and demo GIF presence, without networking."""
from __future__ import annotations

import argparse
import re
from pathlib import Path
from urllib.parse import unquote, urlsplit


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--allow-missing-demo-image", action="store_true",
                        help="Only for preparation before the real demo recording is added.")
    arguments = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    documents = [root / name for name in (
        "README.md", "README_EN.md", "CHANGELOG.md", "CONTRIBUTING.md")]
    documents.extend(sorted((root / "docs").rglob("*.md")))
    failures: list[str] = []
    checked = 0
    link_pattern = re.compile(r"\[[^\]]*\]\(([^\s)]+)(?:\s+\"[^\"]*\")?\)")
    for document in documents:
        if not document.is_file():
            failures.append(f"Missing document: {document.relative_to(root)}")
            continue
        text = document.read_text(encoding="utf-8")
        for match in link_pattern.finditer(text):
            target = match.group(1).strip("<>")
            parts = urlsplit(target)
            if parts.scheme or target.startswith(("#", "//")):
                continue
            destination = (document.parent / unquote(parts.path)).resolve()
            if (arguments.allow_missing_demo_image and
                    destination == root / "docs/images/demo.gif"):
                continue
            checked += 1
            if not destination.exists():
                failures.append(f"{document.relative_to(root)}: missing target {target}")
    gif = root / "docs/images/demo.gif"
    if gif.exists():
        if gif.read_bytes()[:6] not in (b"GIF87a", b"GIF89a"):
            failures.append("docs/images/demo.gif is not a GIF file")
    elif not arguments.allow_missing_demo_image:
        failures.append("Missing real demo recording: docs/images/demo.gif")
    if failures:
        print("\n".join(failures))
        return 1
    print(f"Checked {len(documents)} Markdown documents and {checked} local links.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
