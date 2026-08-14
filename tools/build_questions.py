#!/usr/bin/env python3
"""Emit the shipped question bank from the verified source data.

Reads the prompts and answers that the verification pipeline produced, and for
each lesson writes `questions.json`, fills in `questionIds` in `topic.yml`, and
appends a Practice section of `[[question:id]]` tags to `lesson.md`.

Re-runnable: every output is rewritten wholesale rather than appended to, so
running twice leaves the tree byte-identical.

    python3 tools/build_questions.py                 # every topic
    python3 tools/build_questions.py <topic-slug>    # just one
"""

import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SOURCE = os.path.join(ROOT, "content_src/source/bryant_heath")
CONTENT = os.path.join(ROOT, "assets/content/number_sense")

PRACTICE_HEADING = "## Practice"

# Provenance for the answers we corrected or derived stays in content_src and in
# git history. The app ships the answer we believe is right and says nothing
# about how it was reached — a student has no use for "the book prints 39".
DROPPED_ANSWER_FIELDS = {"derived", "corrected", "note"}


def classify(answer):
    """The question's type, from the shape of its answer.

    Decided here rather than at runtime so that attempts record something
    meaningful and accuracy can be read per type across every topic.
    """
    kind = answer.get("type", "numeric")
    if kind == "approx":
        return "estimate"
    if kind == "numeric" and "base" in answer:
        return "base"
    return kind


def build_answer(source):
    """The nested answer object the sealed Answer type reads."""
    answer = {k: v for k, v in source.items() if k not in DROPPED_ANSWER_FIELDS}
    # A base-N answer is a numeric one whose digits are read in another base;
    # the app needs it as its own type to grade the digits correctly.
    if answer.get("type") == "numeric" and "base" in answer:
        answer["type"] = "base"
    return answer


def question_number(key):
    """Sorts questions the way the manual prints them, 2 before 10."""
    return int(key) if key.isdigit() else 0


def read_section(topic_dir):
    path = os.path.join(topic_dir, "topic.yml")
    match = re.search(r"^bh_section:\s*'?([\d.]+)'?", open(path).read(), re.M)
    return match.group(1) if match else None


def write_questions(topic_dir, topic, section, prompts, answers):
    questions = []
    for key in sorted(prompts, key=question_number):
        answer = answers.get(key)
        # Every prompt has an answer; a gap would mean an unanswerable question,
        # so skip rather than ship one that can never be got right.
        if answer is None:
            continue
        questions.append(
            {
                "id": f"bh.{section}.q{key}",
                "type": classify(answer),
                "prompt": prompts[key],
                "topic": topic,
                "answer": build_answer(answer),
            }
        )

    path = os.path.join(topic_dir, "questions.json")
    with open(path, "w") as f:
        json.dump(questions, f, indent=2, ensure_ascii=False)
        f.write("\n")
    return questions


def write_question_ids(topic_dir, questions):
    """Rewrites the questionIds block in topic.yml, leaving the rest alone."""
    path = os.path.join(topic_dir, "topic.yml")
    text = open(path).read()

    if questions:
        block = "questionIds:\n" + "".join(
            f"  - {q['id']}\n" for q in questions
        )
    else:
        block = "questionIds: []\n"

    # Matches the key plus any list items under it, empty or populated.
    pattern = re.compile(r"^questionIds:.*\n(?:[ \t]+-.*\n)*", re.M)
    text = pattern.sub(block, text) if pattern.search(text) else text + block
    open(path, "w").write(text)


def write_practice(topic_dir, questions):
    """Replaces the Practice section of lesson.md, or adds one."""
    path = os.path.join(topic_dir, "lesson.md")
    if not os.path.isfile(path):
        return
    text = open(path).read()

    # Drop any existing Practice section so re-running cannot stack them up.
    text = re.sub(
        rf"\n*{re.escape(PRACTICE_HEADING)}\n.*\Z", "", text, flags=re.S
    ).rstrip()

    if questions:
        tags = "\n\n".join(f"[[question:{q['id']}]]" for q in questions)
        text += f"\n\n{PRACTICE_HEADING}\n\n{tags}\n"
    else:
        text += "\n"
    open(path, "w").write(text)


def main():
    prompts = json.load(open(os.path.join(SOURCE, "bh_prompts_vlm.json")))
    answers = json.load(open(os.path.join(SOURCE, "bh_answers.json")))

    only = sys.argv[1] if len(sys.argv) > 1 else None
    written = skipped = total = 0

    for topic in sorted(os.listdir(CONTENT)):
        topic_dir = os.path.join(CONTENT, topic)
        if not os.path.isdir(topic_dir):
            continue
        if only and topic != only:
            continue

        section = read_section(topic_dir)
        # Seven lessons cover material the manual never set problems for. They
        # stay lesson-only: TopicScreen already handles an empty questionIds.
        if section is None or section not in prompts:
            skipped += 1
            continue

        questions = write_questions(
            topic_dir, topic, section, prompts[section], answers.get(section, {})
        )
        write_question_ids(topic_dir, questions)
        write_practice(topic_dir, questions)

        written += 1
        total += len(questions)
        print(f"{topic}: {len(questions)}")

    print(f"\n{written} topics, {total} questions, {skipped} lesson-only")


if __name__ == "__main__":
    main()
