#!/usr/bin/env python3
"""Generate mini_hub topic folders from the Bryant Heath lesson prose.

Source of truth is content_src/source/bryant_heath/:
  lessons_clean/<trick_id>.md   faithful prose extracted from the manual
  tricks.json                   trick_id -> slug/name taxonomy

Emits, under assets/content/number_sense/:
  course.yml
  <slug>/topic.yml
  <slug>/lesson.md

Lesson text only — no questions.json, no [[question:...]] refs. Those come later.
LaTeX formatting lives in the source .md files — edit those, not this script.
Re-runnable: regenerates every topic folder from source each time.
"""
import json
import re
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / 'content_src/source/bryant_heath'
OUT = ROOT / 'assets/content/number_sense'

COURSE_ID = 'number_sense'
COURSE_TITLE = 'Number Sense'
COURSE_ICON = 'calculate'


def load_taxonomy() -> dict[str, dict]:
    tricks = json.loads((SRC / 'tricks.json').read_text())
    return {t['trick_id']: t for t in tricks}


def sort_key(trick_id: str) -> tuple:
    return tuple(int(p) for p in trick_id.split('.'))


def sanitize(s: str) -> str:
    """Folder-safe slug. Taxonomy slugs contain '/' (e.g. 'a_times_a/b_trick')."""
    return re.sub(r'[^a-z0-9]+', '_', s.lower()).strip('_')


def slug_for(trick_id: str, tax: dict, title: str) -> str:
    entry = tax.get(trick_id)
    if entry:
        return sanitize(entry['slug'])
    # Sections present in the manual but absent from the taxonomy (1.1, 3.3, 3.4)
    # fall back to a slug derived from the heading.
    return sanitize(title) or trick_id.replace('.', '_')


def title_for(trick_id: str, body: str, tax: dict) -> str:
    heading = re.match(r'#\s+(.+)', body.strip())
    if heading:
        return heading.group(1).strip()
    entry = tax.get(trick_id)
    return entry['name'].title() if entry else trick_id


def strip_heading(body: str) -> str:
    """Drop the leading '# Title' — the app renders the title in the app bar."""
    return re.sub(r'\A#\s+.+\n+', '', body.strip()) + '\n'


def yaml_quote(s: str) -> str:
    return "'" + s.replace("'", "''") + "'"


def main() -> None:
    tax = load_taxonomy()
    lessons = sorted(
        (SRC / 'lessons_clean').glob('*.md'),
        key=lambda p: sort_key(p.stem),
    )

    if OUT.exists():
        shutil.rmtree(OUT)
    OUT.mkdir(parents=True)

    topic_ids: list[str] = []
    for path in lessons:
        trick_id = path.stem
        body = path.read_text()
        title = title_for(trick_id, body, tax)
        slug = slug_for(trick_id, tax, title)

        folder = OUT / slug
        folder.mkdir()
        (folder / 'lesson.md').write_text(f'# {title}\n\n{strip_heading(body)}')
        (folder / 'topic.yml').write_text(
            f'id: {slug}\n'
            f'title: {yaml_quote(title)}\n'
            f'logo: assets/icons/number_sense.png\n'
            f'bh_section: {yaml_quote(trick_id)}\n'
            f'questionIds: []\n'
        )
        topic_ids.append(slug)

    (OUT / 'course.yml').write_text(
        f'id: {COURSE_ID}\n'
        f'title: {yaml_quote(COURSE_TITLE)}\n'
        f'icon: {COURSE_ICON}\n'
        'topics:\n' + ''.join(f'  - {t}\n' for t in topic_ids)
    )

    print(f'wrote {len(topic_ids)} topics to {OUT.relative_to(ROOT)}')
    print('\npubspec.yaml asset entries:\n')
    print('    - assets/content/number_sense/')
    for t in topic_ids:
        print(f'    - assets/content/number_sense/{t}/')


if __name__ == '__main__':
    main()
