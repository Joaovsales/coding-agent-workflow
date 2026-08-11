#!/usr/bin/env python3
"""Migrate the monolithic learning store (tasks/memory.md, tasks/lessons.md,
tasks/bugs.md) into the typed per-document store described in
tasks/solutions/README.md (tasks/solutions/<category>/<slug>.md).

Usage:
    migrate-learning-store.py [--apply] [--force] [--repo <path>] [--report <path>]

With no flags this performs a DRY RUN: it prints the full migration plan
(every document it would write, every file it would archive, every
unmappable/needs_review entry, every date fallback used, and any conflicts)
and writes nothing. Pass --apply to actually perform the migration.

Any of the three source files may be absent; that is normal, not an error.
When none are present the store is considered already migrated and the
script exits 0 having done nothing.
"""

from __future__ import annotations

import argparse
import re
import shutil
import subprocess
import sys
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path


class MigrationError(Exception):
    """Raised for any failure that should abort the migration with a
    non-zero exit code and a message naming the failing source file."""


CATEGORY_MAP = {
    "bug": "bugs",
    "build-failure": "bugs",
    "test-failure": "bugs",
    "runtime-error": "bugs",
    "performance": "performance",
    "security": "security",
    "architecture-decision": "architecture",
    "pattern": "patterns",
    "convention": "conventions",
    "tooling": "tooling",
    "process": "process",
}

RECOGNIZED_MEMORY_SECTIONS = {
    "Project Context",
    "Architecture Decisions",
    "Patterns & Lessons",
    "Session History",
}

SECTION_HEADING_RE = re.compile(r"^##[ \t]+(.+?)[ \t]*$", re.MULTILINE)
SUBHEADING_RE = re.compile(r"^###[ \t]+(.+?)[ \t]*$", re.MULTILINE)
SESSION_HEADING_RE = re.compile(
    r"^###[ \t]+\[(\d{4}-\d{2}-\d{2})\][ \t]*[—-][ \t]*(.+?)[ \t]*$", re.MULTILINE
)
LESSONS_HEADING_RE = re.compile(r"^(#{2,3})[ \t]+(.+?)[ \t]*$", re.MULTILINE)
BULLET_START_RE = re.compile(r"^\s*-\s+")
BULLET_PATTERN_RE = re.compile(r"^\s*-\s*Pattern:\s*(.*)$")


# --------------------------------------------------------------------------
# Small generic helpers
# --------------------------------------------------------------------------

def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def write_text_file(path: Path, content: str) -> None:
    with open(path, "w", encoding="utf-8", newline="\n") as handle:
        handle.write(content)


def rel(path: Path, repo_root: Path) -> str:
    return path.relative_to(repo_root).as_posix()


def normalize_ws(text: str) -> str:
    return re.sub(r"\s+", " ", text).strip()


def strip_trailing_separator(text: str) -> str:
    """Drop trailing blank lines and a trailing '---' rule, so a section's
    tail doesn't leak into the last entry parsed out of it."""
    lines = text.splitlines()
    while lines and lines[-1].strip() in ("", "---"):
        lines.pop()
    return "\n".join(lines)


def slugify(title: str, max_len: int = 60) -> str:
    slug = title.lower()
    slug = re.sub(r"[^a-z0-9]+", "-", slug)
    slug = re.sub(r"-+", "-", slug).strip("-")
    if len(slug) > max_len:
        slug = slug[:max_len].rstrip("-")
    return slug or "untitled"


def derive_title(text: str, max_words: int = 10, max_len: int = 70) -> str:
    words = normalize_ws(text).split()
    title = " ".join(words[:max_words])
    if len(title) > max_len:
        title = title[:max_len].rstrip()
    title = title.rstrip(".,;:")
    return title or "Untitled"


def yaml_scalar(value: str) -> str:
    if value is None:
        value = ""
    if value == "":
        return '""'
    special_start = value[0] in ':#&*!|>%@`"\'-?[]{},'
    if ":" in value or special_start:
        escaped = value.replace("\\", "\\\\").replace('"', '\\"')
        return f'"{escaped}"'
    return value


def utc_timestamp() -> str:
    return datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")


def is_git_repo(repo_root: Path) -> bool:
    try:
        result = subprocess.run(
            ["git", "rev-parse", "--is-inside-work-tree"],
            cwd=repo_root, capture_output=True, text=True, check=False,
        )
    except OSError:
        return False
    return result.returncode == 0 and result.stdout.strip() == "true"


def git_log_date(source_path: Path, repo_root: Path) -> str | None:
    if not is_git_repo(repo_root):
        return None
    try:
        result = subprocess.run(
            ["git", "log", "-1", "--format=%cs", "--", str(source_path)],
            cwd=repo_root, capture_output=True, text=True, check=False,
        )
    except OSError:
        return None
    date = result.stdout.strip()
    return date if result.returncode == 0 and date else None


def resolve_date(explicit: str | None, source_path: Path, repo_root: Path) -> tuple[str, str | None]:
    if explicit:
        return explicit, None
    git_date = git_log_date(source_path, repo_root)
    if git_date:
        return git_date, "git-log"
    return datetime.now(timezone.utc).strftime("%Y-%m-%d"), "today"


def parse_markdown_table(content: str) -> list[list[str]]:
    """Return [header_cells, data_row_cells, ...] for the first pipe-table
    found in content, or [] if none is found."""
    table_lines = []
    started = False
    for line in content.splitlines():
        stripped = line.strip()
        if stripped.startswith("|"):
            table_lines.append(stripped)
            started = True
        elif started:
            break
    if len(table_lines) < 2:
        return []
    rows = [[c.strip() for c in line.strip("|").split("|")] for line in table_lines]
    header = rows[0]
    data_rows = rows[2:]  # rows[1] is the '---' separator row
    return [header] + data_rows


# --------------------------------------------------------------------------
# Document model
# --------------------------------------------------------------------------

@dataclass
class Document:
    title: str
    date: str
    problem_type: str
    module: str
    tags: list
    track_fields: dict
    body: str
    needs_review: bool = False
    date_source: str | None = None
    migrated_from: str | None = None
    path: Path | None = None


@dataclass
class ProjectContextWrite:
    path: Path
    body: str
    conflict: bool


@dataclass
class Plan:
    repo_root: Path
    timestamp: str
    documents: list = field(default_factory=list)
    archives: list = field(default_factory=list)
    conflicts: list = field(default_factory=list)
    unmigrated_sections: list = field(default_factory=list)
    session_entries: list = field(default_factory=list)
    project_context: ProjectContextWrite | None = None
    used_slugs: set = field(default_factory=set)


def render_frontmatter(doc: Document) -> str:
    lines = ["---"]
    lines.append(f"title: {yaml_scalar(doc.title)}")
    lines.append(f"date: {doc.date}")
    lines.append(f"problem_type: {doc.problem_type}")
    lines.append(f"module: {yaml_scalar(doc.module)}")
    lines.append(f"tags: [{', '.join(doc.tags)}]")
    for key, value in doc.track_fields.items():
        lines.append(f"{key}: {yaml_scalar(value)}")
    if doc.needs_review:
        lines.append("needs_review: true")
    if doc.date_source:
        lines.append(f"date_source: {doc.date_source}")
    if doc.migrated_from:
        lines.append(f"migrated_from: {yaml_scalar(doc.migrated_from)}")
    lines.append("---")
    return "\n".join(lines)


def render_document(doc: Document) -> str:
    return render_frontmatter(doc) + "\n\n" + doc.body.strip() + "\n"


def render_project_context(body: str) -> str:
    return f"# Project Context\n\n{body.strip()}\n"


# --------------------------------------------------------------------------
# tasks/memory.md
# --------------------------------------------------------------------------

def split_sections(text: str) -> list[tuple[str, str]]:
    matches = list(SECTION_HEADING_RE.finditer(text))
    sections = []
    for i, match in enumerate(matches):
        heading = match.group(1).strip()
        start = match.end()
        end = matches[i + 1].start() if i + 1 < len(matches) else len(text)
        sections.append((heading, text[start:end]))
    return sections


def process_memory(path: Path, repo_root: Path, plan: Plan) -> None:
    text = read_text(path)
    sections = split_sections(text)
    source_rel = rel(path, repo_root)

    for heading, content in sections:
        if heading not in RECOGNIZED_MEMORY_SECTIONS:
            plan.unmigrated_sections.append((source_rel, heading))

    for heading, content in sections:
        if heading == "Project Context":
            handle_project_context(content, repo_root, plan)
        elif heading == "Architecture Decisions":
            handle_architecture(content, path, repo_root, plan)
        elif heading == "Patterns & Lessons":
            handle_patterns(content, path, repo_root, plan)
        elif heading == "Session History":
            handle_session_history(content, path, repo_root, plan)

    plan.archives.append(path)


def handle_project_context(content: str, repo_root: Path, plan: Plan) -> None:
    body = strip_trailing_separator(content).strip("\n")
    target = repo_root / "tasks" / "project-context.md"
    if target.exists():
        conflict_path = repo_root / "tasks" / "project-context.migrated.md"
        plan.project_context = ProjectContextWrite(path=conflict_path, body=body, conflict=True)
        plan.conflicts.append(
            "tasks/project-context.md already exists; writing "
            "tasks/project-context.migrated.md instead"
        )
    else:
        plan.project_context = ProjectContextWrite(path=target, body=body, conflict=False)


def handle_architecture(content: str, source_path: Path, repo_root: Path, plan: Plan) -> None:
    rows = parse_markdown_table(content)
    if not rows:
        return
    header = [normalize_ws(h).lower() for h in rows[0]]
    decision_idx = header.index("decision") if "decision" in header else None
    rationale_idx = header.index("rationale") if "rationale" in header else None
    if decision_idx is None:
        return

    for row in rows[1:]:
        decision = row[decision_idx].strip() if decision_idx < len(row) else ""
        if not decision:
            continue
        rationale = row[rationale_idx].strip() if rationale_idx is not None and rationale_idx < len(row) else ""
        date, date_source = resolve_date(None, source_path, repo_root)
        doc = Document(
            title=decision,
            date=date,
            problem_type="architecture-decision",
            module="general",
            tags=["migrated", "architecture"],
            track_fields={"applies_when": ""},
            body=f"## {decision}\n\n**Rationale**: {rationale}\n",
            needs_review=True,
            date_source=date_source,
            migrated_from=rel(source_path, repo_root),
        )
        plan.documents.append(doc)


def extract_label(text: str, label: str) -> str | None:
    match = re.search(
        rf"\*\*{re.escape(label)}\*\*:\s*(.*?)(?=\n\s*\*\*[A-Za-z]|\Z)", text, re.DOTALL
    )
    if not match:
        return None
    return normalize_ws(match.group(1))


def handle_patterns(content: str, source_path: Path, repo_root: Path, plan: Plan) -> None:
    matches = list(SUBHEADING_RE.finditer(content))
    for i, match in enumerate(matches):
        title = match.group(1).strip()
        start = match.end()
        end = matches[i + 1].start() if i + 1 < len(matches) else len(content)
        entry_text = strip_trailing_separator(content[start:end])

        context = extract_label(entry_text, "Context")
        pattern_text = extract_label(entry_text, "Pattern")
        evidence_text = extract_label(entry_text, "Evidence")
        needs_review = not context

        body_parts = [f"## {title}", ""]
        if pattern_text:
            body_parts += [f"**Pattern**: {pattern_text}", ""]
        if evidence_text:
            body_parts += [f"**Evidence**: {evidence_text}", ""]

        date, date_source = resolve_date(None, source_path, repo_root)
        doc = Document(
            title=title,
            date=date,
            problem_type="pattern",
            module="general",
            tags=["migrated", "pattern"],
            track_fields={"applies_when": context or ""},
            body="\n".join(body_parts).strip() + "\n",
            needs_review=needs_review,
            date_source=date_source,
            migrated_from=rel(source_path, repo_root),
        )
        plan.documents.append(doc)


def group_bullets(lines: list[str]) -> tuple[list[str], list[dict]]:
    """Split a session entry's body lines into a leading run (before any
    bullet) and a list of bullets, each a dict with a 'lines' list."""
    leading: list[str] = []
    bullets: list[dict] = []
    current: dict | None = None
    for line in lines:
        if BULLET_START_RE.match(line):
            if current is not None:
                bullets.append(current)
            current = {"lines": [line]}
        elif current is not None and line.strip() != "":
            current["lines"].append(line)
        elif current is not None and line.strip() == "":
            bullets.append(current)
            current = None
        else:
            leading.append(line)
    if current is not None:
        bullets.append(current)
    return leading, bullets


def build_extracted_pattern_doc(pattern_text: str, entry: dict, source_path: Path, repo_root: Path) -> Document:
    title = derive_title(pattern_text)
    body = (
        f"## {title}\n\n"
        f"**Pattern**: {pattern_text}\n\n"
        f'_Extracted from session history entry "{entry["title"]}" '
        f'({entry["date"]}) in `tasks/history.md`._\n'
    )
    return Document(
        title=title,
        date=entry["date"],
        problem_type="pattern",
        module="general",
        tags=["migrated", "pattern"],
        track_fields={"applies_when": ""},
        body=body,
        needs_review=True,
        date_source=None,
        migrated_from=rel(source_path, repo_root),
    )


def handle_session_history(content: str, source_path: Path, repo_root: Path, plan: Plan) -> None:
    matches = list(SESSION_HEADING_RE.finditer(content))
    for i, match in enumerate(matches):
        date = match.group(1)
        title = match.group(2).strip()
        start = match.end()
        end = matches[i + 1].start() if i + 1 < len(matches) else len(content)
        body = strip_trailing_separator(content[start:end])
        entry = {"date": date, "title": title}

        leading, bullets = group_bullets(body.splitlines())
        for bullet in bullets:
            pattern_match = BULLET_PATTERN_RE.match(bullet["lines"][0])
            if not pattern_match:
                continue
            pattern_text = normalize_ws(
                " ".join([pattern_match.group(1)] + [l.strip() for l in bullet["lines"][1:]])
            )
            doc = build_extracted_pattern_doc(pattern_text, entry, source_path, repo_root)
            plan.documents.append(doc)
            bullet["cross_link_doc"] = doc

        plan.session_entries.append({
            "date": date, "title": title, "leading": leading, "bullets": bullets,
        })


# --------------------------------------------------------------------------
# tasks/lessons.md
# --------------------------------------------------------------------------

def is_blockquote_only(text: str) -> bool:
    lines = [l for l in text.splitlines() if l.strip() != ""]
    return bool(lines) and all(l.strip().startswith(">") for l in lines)


def split_lessons_blocks(text: str) -> list[tuple[str, str]]:
    matches = list(LESSONS_HEADING_RE.finditer(text))
    blocks = []
    if matches:
        for i, match in enumerate(matches):
            title = match.group(2).strip()
            start = match.end()
            end = matches[i + 1].start() if i + 1 < len(matches) else len(text)
            body = strip_trailing_separator(text[start:end]).strip()
            blocks.append((title, body if body else title))
    else:
        for raw in re.split(r"\n\s*\n", text.strip()):
            raw = raw.strip()
            if raw:
                blocks.append((derive_title(raw), raw))
    return blocks


def process_lessons(path: Path, repo_root: Path, plan: Plan) -> None:
    text = read_text(path)
    for title, body in split_lessons_blocks(text):
        if is_blockquote_only(body):
            continue
        date, date_source = resolve_date(None, path, repo_root)
        doc = Document(
            title=title,
            date=date,
            problem_type="pattern",
            module="general",
            tags=["migrated", "pattern"],
            track_fields={"applies_when": ""},
            body=body.strip() + "\n",
            needs_review=True,
            date_source=date_source,
            migrated_from=rel(path, repo_root),
        )
        plan.documents.append(doc)
    plan.archives.append(path)


# --------------------------------------------------------------------------
# tasks/bugs.md
# --------------------------------------------------------------------------

def process_bugs(path: Path, repo_root: Path, plan: Plan) -> None:
    text = read_text(path)
    rows = parse_markdown_table(text)
    if not rows:
        plan.archives.append(path)
        return

    header = rows[0]
    lower_header = [h.strip().lower() for h in header]

    def col_index(name: str) -> int | None:
        return lower_header.index(name) if name in lower_header else None

    idx_desc = col_index("description")
    idx_root = col_index("root cause")
    idx_fix = col_index("fix")
    idx_files = col_index("files")
    idx_date = col_index("date")
    mapped = {i for i in (idx_desc, idx_root, idx_fix, idx_files, idx_date) if i is not None}

    for row in rows[1:]:
        cells = list(row) + [""] * (len(header) - len(row))
        description = cells[idx_desc].strip() if idx_desc is not None else ""
        if not description:
            continue
        root_cause = cells[idx_root].strip() if idx_root is not None else ""
        resolution = cells[idx_fix].strip() if idx_fix is not None else ""
        module = cells[idx_files].strip() if idx_files is not None and cells[idx_files].strip() else "general"
        explicit_date = cells[idx_date].strip() if idx_date is not None else ""
        date, date_source = resolve_date(explicit_date or None, path, repo_root)
        needs_review = not root_cause or not resolution

        body_lines = [
            f"**{header[i].strip()}**: {cells[i].strip()}"
            for i in range(len(header)) if i not in mapped
        ]
        body = "\n".join(body_lines) if body_lines else f"## {description}\n"

        doc = Document(
            title=description,
            date=date,
            problem_type="bug",
            module=module,
            tags=["migrated", "bug"],
            track_fields={"symptoms": description, "root_cause": root_cause, "resolution": resolution},
            body=body,
            needs_review=needs_review,
            date_source=date_source,
            migrated_from=rel(path, repo_root),
        )
        plan.documents.append(doc)

    plan.archives.append(path)


# --------------------------------------------------------------------------
# Slug assignment, report, apply
# --------------------------------------------------------------------------

def next_free_slug(base_dir: Path, slug: str, used: set) -> str:
    candidate = slug
    n = 2
    while True:
        key = (str(base_dir), candidate)
        if key not in used and not (base_dir / f"{candidate}.md").exists():
            used.add(key)
            return candidate
        candidate = f"{slug}-{n}"
        n += 1


def finalize_documents(plan: Plan) -> None:
    for doc in plan.documents:
        category = CATEGORY_MAP[doc.problem_type]
        base_dir = plan.repo_root / "tasks" / "solutions" / category
        slug = next_free_slug(base_dir, slugify(doc.title), plan.used_slugs)
        doc.path = base_dir / f"{slug}.md"


def render_history(plan: Plan) -> str:
    lines = [
        "# History",
        "",
        "> Migrated from the Session History section of tasks/memory.md.",
        "",
    ]
    for entry in sorted(plan.session_entries, key=lambda e: e["date"], reverse=True):
        lines.append(f"### [{entry['date']}] — {entry['title']}")
        lines.extend(entry["leading"])
        for bullet in entry["bullets"]:
            bullet_lines = list(bullet["lines"])
            doc = bullet.get("cross_link_doc")
            if doc is not None:
                cross_link = doc.path.relative_to(plan.repo_root).as_posix()
                bullet_lines[-1] = f"{bullet_lines[-1]} (extracted: {cross_link})"
            lines.extend(bullet_lines)
        lines.append("")
    return "\n".join(lines).rstrip() + "\n"


def render_report(plan: Plan, apply_mode: bool) -> str:
    verb_doc = "WROTE" if apply_mode else "WOULD WRITE"
    verb_arch = "ARCHIVED" if apply_mode else "WOULD ARCHIVE"
    repo_root = plan.repo_root
    lines = [
        f"Migration plan for {repo_root}",
        f"Mode: {'APPLY' if apply_mode else 'DRY RUN'}",
        "",
    ]

    if plan.project_context is not None:
        pc = plan.project_context
        rel_path = pc.path.relative_to(repo_root).as_posix()
        if pc.conflict:
            lines.append(f"CONFLICT: tasks/project-context.md already exists; {verb_doc} {rel_path} instead")
        else:
            lines.append(f"{verb_doc} {rel_path}")

    for doc in plan.documents:
        rel_path = doc.path.relative_to(repo_root).as_posix()
        flags = []
        if doc.needs_review:
            flags.append("needs_review")
        if doc.date_source:
            flags.append(f"date_source={doc.date_source}")
        flag_str = f" [{', '.join(flags)}]" if flags else ""
        lines.append(f"{verb_doc} {rel_path} (problem_type: {doc.problem_type}){flag_str}")

    if plan.session_entries:
        lines.append(f"{verb_doc} tasks/history.md")

    for source_rel, heading in plan.unmigrated_sections:
        lines.append(f"UNMIGRATED SECTION: '## {heading}' in {source_rel} (preserved verbatim in archive)")

    for src in plan.archives:
        rel_path = rel(src, repo_root)
        dest_rel = f"tasks/archive/{plan.timestamp}/{src.name}"
        lines.append(f"{verb_arch} {rel_path} -> {dest_rel}")

    for conflict in plan.conflicts:
        lines.append(f"CONFLICT: {conflict}")

    needs_review_count = sum(1 for d in plan.documents if d.needs_review)
    lines.append("")
    lines.append(
        f"Summary: {len(plan.documents)} document(s), {len(plan.archives)} file(s) archived, "
        f"{needs_review_count} flagged needs_review, {len(plan.conflicts)} conflict(s), "
        f"{len(plan.unmigrated_sections)} unmigrated section(s)."
    )
    return "\n".join(lines) + "\n"


def apply_plan(plan: Plan) -> None:
    try:
        for doc in plan.documents:
            doc.path.parent.mkdir(parents=True, exist_ok=True)
            write_text_file(doc.path, render_document(doc))

        if plan.project_context is not None:
            pc = plan.project_context
            pc.path.parent.mkdir(parents=True, exist_ok=True)
            write_text_file(pc.path, render_project_context(pc.body))

        if plan.session_entries:
            write_text_file(plan.repo_root / "tasks" / "history.md", render_history(plan))

        if plan.archives:
            archive_dir = plan.repo_root / "tasks" / "archive" / plan.timestamp
            archive_dir.mkdir(parents=True, exist_ok=True)
            for src in plan.archives:
                shutil.move(str(src), str(archive_dir / src.name))
    except OSError as exc:
        raise MigrationError(f"Failed to write migration output: {exc}") from exc


# --------------------------------------------------------------------------
# Git safety gate + CLI plumbing
# --------------------------------------------------------------------------

def determine_repo_root(explicit: str | None) -> Path:
    if explicit:
        return Path(explicit).resolve()
    try:
        result = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            capture_output=True, text=True, check=False,
        )
        if result.returncode == 0 and result.stdout.strip():
            return Path(result.stdout.strip()).resolve()
    except OSError:
        pass
    return Path.cwd().resolve()


def check_dirty(repo_root: Path, force: bool) -> None:
    if not is_git_repo(repo_root):
        print("Note: target is not a git repository; skipping dirty-tree check.")
        return
    result = subprocess.run(
        ["git", "status", "--porcelain"], cwd=repo_root, capture_output=True, text=True, check=False,
    )
    if result.returncode != 0:
        raise MigrationError(f"git status failed: {result.stderr.strip()}")
    if result.stdout.strip() and not force:
        print(
            "ERROR: repo has uncommitted changes; refusing to run.\n"
            "Commit or stash your changes, or pass --force to override.",
            file=sys.stderr,
        )
        sys.exit(1)


def safe_process(fn, path: Path, repo_root: Path, plan: Plan) -> None:
    try:
        fn(path, repo_root, plan)
    except MigrationError:
        raise
    except Exception as exc:
        raise MigrationError(f"Failed to process {rel(path, repo_root)}: {exc}") from exc


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Migrate tasks/memory.md, tasks/lessons.md, tasks/bugs.md into "
                     "the typed tasks/solutions/<category>/<slug>.md learning store."
    )
    parser.add_argument("--apply", action="store_true", help="perform the migration (default: dry run)")
    parser.add_argument("--force", action="store_true", help="proceed despite a dirty git tree")
    parser.add_argument("--repo", default=None, help="target repo root (default: git toplevel, else cwd)")
    parser.add_argument("--report", default=None, help="also write the report to this file")
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv if argv is not None else sys.argv[1:])

    try:
        repo_root = determine_repo_root(args.repo)
        memory_path = repo_root / "tasks" / "memory.md"
        lessons_path = repo_root / "tasks" / "lessons.md"
        bugs_path = repo_root / "tasks" / "bugs.md"
        sources = [p for p in (memory_path, lessons_path, bugs_path) if p.exists()]

        if not sources:
            message = (
                f"Nothing to migrate: no tasks/memory.md, tasks/lessons.md, or "
                f"tasks/bugs.md found under {repo_root}.\n"
                "Migration already completed, or this project has no legacy learning store."
            )
            print(message)
            if args.report:
                write_text_file(Path(args.report), message + "\n")
            return 0

        check_dirty(repo_root, args.force)

        plan = Plan(repo_root=repo_root, timestamp=utc_timestamp())
        if memory_path.exists():
            safe_process(process_memory, memory_path, repo_root, plan)
        if lessons_path.exists():
            safe_process(process_lessons, lessons_path, repo_root, plan)
        if bugs_path.exists():
            safe_process(process_bugs, bugs_path, repo_root, plan)

        finalize_documents(plan)

        if args.apply:
            apply_plan(plan)

        report_text = render_report(plan, args.apply)
        print(report_text, end="")
        if args.report:
            write_text_file(Path(args.report), report_text)

        return 0
    except MigrationError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
