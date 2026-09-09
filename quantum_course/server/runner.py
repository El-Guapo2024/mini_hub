"""Execute a submission and grade it, out of process and under limits.

Two roles in one file. Imported, it exposes `grade()`, which the server calls.
Run as `python3 runner.py --child`, it *is* the child: it reads one JSON
request on stdin, runs the submission, and writes one JSON verdict on stdout.

Everything a submission can do wrong -- looping forever, allocating the world,
raising, or simply being wrong -- comes back as a verdict rather than as a
failure of the server.
"""

import json
import os
import subprocess
import sys

# Wall-clock and address-space ceilings for a single submission. The wall
# clock is enforced by the parent, because a child stuck in a C loop inside
# numpy will not notice a signal it never gets scheduled to handle.
TIME_LIMIT = 10  # seconds
MEMORY_LIMIT = 1024 * 1024 * 1024  # 1 GiB, generous enough for numpy

PROBLEM_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "problems")

VERDICTS = (
    "accepted",
    "wrong_answer",
    "runtime_error",
    "time_limit_exceeded",
    "memory_limit_exceeded",
    "no_such_problem",
    "internal_error",
)


# --------------------------------------------------------------------- parent
def grade(problem_id: str, source: str) -> dict:
    """Run `source` against `problem_id`. Always returns a verdict dict."""
    if not _is_safe_id(problem_id):
        return _verdict("no_such_problem", f"bad problem id {problem_id!r}")
    if not os.path.exists(os.path.join(PROBLEM_DIR, problem_id + ".py")):
        return _verdict("no_such_problem", f"no problem called {problem_id!r}")

    request = json.dumps({"problem": problem_id, "source": source})
    try:
        proc = subprocess.run(
            [sys.executable, os.path.abspath(__file__), "--child"],
            input=request,
            capture_output=True,
            text=True,
            timeout=TIME_LIMIT,
        )
    except subprocess.TimeoutExpired:
        return _verdict(
            "time_limit_exceeded",
            f"submission ran for more than {TIME_LIMIT}s and was stopped",
        )

    if proc.returncode != 0 and not proc.stdout.strip():
        # Killed before it could report -- almost always the memory ceiling.
        detail = (proc.stderr or "").strip()[-400:]
        if proc.returncode == -9 or "MemoryError" in detail:
            return _verdict("memory_limit_exceeded", "submission ran out of memory")
        return _verdict("internal_error", detail or f"exit {proc.returncode}")

    try:
        return json.loads(proc.stdout)
    except json.JSONDecodeError:
        return _verdict("internal_error", (proc.stdout or proc.stderr)[-400:])


def _is_safe_id(pid: str) -> bool:
    return bool(pid) and all(ch.isalnum() or ch in "_-" for ch in pid)


def _verdict(verdict, detail="", checks=None):
    passed = sum(1 for c in checks or [] if c["ok"])
    return {
        "verdict": verdict,
        "detail": detail,
        "checks": checks or [],
        "passed": passed,
        "total": len(checks or []),
    }


# ---------------------------------------------------------------------- child
def _child() -> None:
    import resource

    resource.setrlimit(resource.RLIMIT_AS, (MEMORY_LIMIT, MEMORY_LIMIT))
    resource.setrlimit(resource.RLIMIT_NPROC, (64, 64))
    resource.setrlimit(resource.RLIMIT_FSIZE, (8 << 20, 8 << 20))
    os.chdir("/tmp")

    request = json.loads(sys.stdin.read())
    sys.path.insert(0, PROBLEM_DIR)

    try:
        problem = __import__(request["problem"])
    except Exception as exc:
        print(json.dumps(_verdict("internal_error", f"problem failed to load: {exc}")))
        return

    # The submission gets a fresh namespace, not ours.
    namespace: dict = {"__name__": "submission"}
    try:
        exec(compile(request["source"], "<submission>", "exec"), namespace)
    except MemoryError:
        print(json.dumps(_verdict("memory_limit_exceeded", "ran out of memory")))
        return
    except Exception as exc:
        print(json.dumps(_verdict("runtime_error", _short_traceback(exc))))
        return

    try:
        results = list(problem.grade(namespace))
    except MemoryError:
        print(json.dumps(_verdict("memory_limit_exceeded", "ran out of memory")))
        return
    except Exception as exc:
        print(json.dumps(_verdict("runtime_error", _short_traceback(exc))))
        return

    checks = [{"name": n, "ok": bool(ok), "note": note} for n, ok, note in results]
    failed = [c for c in checks if not c["ok"]]
    if failed:
        print(json.dumps(_verdict("wrong_answer", failed[0]["note"], checks)))
    else:
        print(json.dumps(_verdict("accepted", "", checks)))


def _short_traceback(exc: Exception) -> str:
    import traceback

    frames = traceback.extract_tb(exc.__traceback__)
    # Only frames from the submission itself; the harness is not the student's
    # problem and its line numbers would only mislead.
    own = [f for f in frames if f.filename == "<submission>"]
    where = f" (line {own[-1].lineno})" if own else ""
    return f"{type(exc).__name__}: {exc}{where}"


if __name__ == "__main__":
    if "--child" in sys.argv:
        _child()
    else:
        print("this module is imported by app.py; --child runs one submission")
