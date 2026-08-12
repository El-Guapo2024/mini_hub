#!/usr/bin/env python3
"""Merge the VLM transcription batches into one prompts file.

Items on a page with no 'Problem Set' heading were recorded under a
CONTINUATION_p<NNN> key. The owning section is simply the last heading at or
before that page, which the PDF answers deterministically — no guessing.

Emits content_src/source/bryant_heath/bh_prompts_vlm.json
"""
import json
import re
import sys
from collections import defaultdict
from pathlib import Path

import fitz

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / 'content_src/source/bryant_heath'
VLM = Path(sys.argv[1]) if len(sys.argv) > 1 else None
OUT = SRC / 'bh_prompts_vlm.json'
# The manual prints both 'Problem Set' and 'Problems Set'.
HEAD = re.compile(r'Problems?\s+Sets?\s+([\d.]+?)\s*:?\s*$', re.M)


def page_sections(doc):
    """page -> (section open when the page began, first heading on the page)."""
    owner, current = {}, None
    for i in range(doc.page_count):
        text = doc[i].get_text()
        if text.lstrip().startswith('5\nSolutions'):
            break
        found = [f.rstrip('.') for f in HEAD.findall(text)]
        owner[i] = (current, found[0] if found else None)
        if found:
            current = found[-1]
    return owner


def main():
    doc = fitz.open(SRC / 'bryant_heath_tricks_manual.pdf')
    owner = page_sections(doc)

    merged = defaultdict(dict)
    conflicts, orphans, blocks = [], [], []
    for f in sorted(VLM.glob('*.json')):
        data = json.loads(f.read_text())
        for key, items in data.items():
            m = re.fullmatch(r'CONTINUATION_p(\d+)', key)
            if m:
                carried, on_page = owner.get(int(m.group(1)), (None, None))
                # Default to the set that was open when the page began. A page
                # can hold the tail of one set and the heading of the next, so
                # its own heading is only preferred when the carried section
                # already holds those item numbers (see collision pass below).
                sec = carried
                blocks.append((key, items, carried, on_page))
                if sec is None:
                    orphans.append((f.name, key, len(items)))
                    continue
            else:
                sec = re.sub(r'^Problems?\s+Set\s+', '', key).strip().rstrip('.')
            for n, tex in items.items():
                if n in merged[sec] and merged[sec][n] != tex:
                    conflicts.append((sec, n, merged[sec][n], tex))
                merged[sec][n] = tex

    # Collision pass: a continuation block whose numbers are already taken in
    # the carried section belongs to the heading that appears on its own page.
    moved = 0
    for key, items, carried, on_page in blocks:
        if on_page is None or carried is None or on_page == carried:
            continue
        clash = sum(1 for n, tex in items.items()
                    if n in merged[carried] and merged[carried][n] != tex)
        if clash > len(items) / 2:
            for n, tex in items.items():
                if merged[carried].get(n) == tex:
                    del merged[carried][n]
                merged[on_page][n] = tex
            moved += 1
    if moved:
        print(f'reassigned {moved} continuation blocks to their own page heading')

    # Recompute conflicts after the move.
    conflicts = [c for c in conflicts
                 if merged.get(c[0], {}).get(c[1]) not in (c[2], c[3])
                 or c[2] == c[3]]

    OUT.write_text(json.dumps(merged, indent=1, sort_keys=True))
    total = sum(len(v) for v in merged.values())
    print(f'{len(merged)} sections, {total} prompts -> {OUT.name}')
    print(f'conflicts (same section+number, different text): {len(conflicts)}')
    for c in conflicts[:8]:
        print(f'  {c[0]} #{c[1]}: {c[2]!r}  vs  {c[3]!r}')
    if orphans:
        print(f'orphan continuation blocks: {orphans}')


if __name__ == '__main__':
    main()
