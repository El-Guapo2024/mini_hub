#!/usr/bin/env python3
"""Map every Bryant Heath problem-set section onto the lesson topic it belongs to.

The join needs no classification: answers are keyed by BH section, and
tricks.json already maps section -> slug, which is the same key the lesson
folders were generated from. Sections the taxonomy omits fall back to a slug
derived from the lesson heading, exactly as gen_bh_topics.py does.

Emits content_src/source/bryant_heath/bh_map.json:
    {"1.2.1": {"topic": "multiplying_by_11_trick", "answers": 43}, ...}
"""
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / 'content_src/source/bryant_heath'
TOPICS = ROOT / 'assets/content/number_sense'
OUT = SRC / 'bh_map.json'


def sanitize(s):
    return re.sub(r'[^a-z0-9]+', '_', s.lower()).strip('_')


def main():
    tax = {t['trick_id']: t for t in json.loads((SRC / 'tricks.json').read_text())}
    answers = json.loads((SRC / 'bh_answers.json').read_text())
    topics = {p.name for p in TOPICS.iterdir() if p.is_dir()}

    def slug_for(sec):
        if sec in tax:
            return sanitize(tax[sec]['slug'])
        lesson = SRC / 'lessons_clean' / f'{sec}.md'
        if lesson.exists():
            head = re.match(r'#\s+(.+)', lesson.read_text().strip())
            if head:
                return sanitize(head.group(1))
        return None

    mapping, orphans = {}, []
    for sec in sorted(answers, key=lambda s: tuple(int(p) for p in s.split('.'))):
        slug = slug_for(sec)
        if slug in topics:
            mapping[sec] = {'topic': slug, 'answers': len(answers[sec])}
        else:
            orphans.append((sec, slug))

    OUT.write_text(json.dumps(mapping, indent=1))
    covered = {v['topic'] for v in mapping.values()}
    print(f'{len(mapping)} sections mapped -> {len(covered)} topics '
          f'({sum(v["answers"] for v in mapping.values())} answers)')
    if orphans:
        print(f'unmapped sections: {orphans}')
    missing = sorted(topics - covered)
    print(f'topics with no questions: {len(missing)}')
    for t in missing:
        print(f'  {t}')


if __name__ == '__main__':
    main()
