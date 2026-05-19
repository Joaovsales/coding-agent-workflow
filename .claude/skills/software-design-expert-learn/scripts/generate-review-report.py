#!/usr/bin/env python3
"""
generate-review-report.py

Generates an interactive HTML presentation from a session design review.
Reads review markdown/text from stdin or a file, and outputs a single
self-contained HTML file with syntax highlighting, collapsible sections,
and external documentation links.

Usage:
    python3 generate-review-report.py < review.md > report.html
    python3 generate-review-report.py -i review.md -o report.html
    python3 generate-review-report.py --session-dir ./my-project --diff-only -o report.html
"""

import argparse
import html
import os
import re
import subprocess
import sys
from datetime import datetime


APOSD_PRINCIPLES = {
    "strategic-programming": {
        "title": "Strategic Programming",
        "summary": "The primary goal is great design that happens to work. Invest 10–20% of dev time in small design improvements.",
        "links": [
            ("APOSD - Strategic vs Tactical", "https://web.stanford.edu/~ouster/cgi-bin/cs190-winter25/lecture.php?topic=philosophy"),
        ]
    },
    "deep-modules": {
        "title": "Deep Modules",
        "summary": "Powerful functionality through a simple interface. Unix I/O is the classic example: 5 calls hide enormous complexity.",
        "links": [
            ("APOSD - Module Depth", "https://web.stanford.edu/~ouster/cgi-bin/cs190-winter25/lecture.php?topic=modularDesign"),
        ]
    },
    "information-hiding": {
        "title": "Information Hiding & Leakage",
        "summary": "Hide implementation decisions. Leakage occurs when a design decision is visible in multiple modules.",
        "links": [
            ("APOSD - Information Hiding", "https://web.stanford.edu/~ouster/cgi-bin/cs190-winter25/lecture.php?topic=informationHiding"),
        ]
    },
    "pull-complexity-downward": {
        "title": "Pull Complexity Downward",
        "summary": "Prefer a more complex implementation over a more complex interface. Callers should pay as little as possible.",
        "links": [
            ("APOSD - Pull Complexity Down", "https://web.stanford.edu/~ouster/cgi-bin/cs190-winter25/lecture.php?topic=modularDesign"),
        ]
    },
    "general-purpose": {
        "title": "General-Purpose Modules",
        "summary": "If a module can be general without much extra code, make it general. Avoid special cases.",
        "links": [
            ("APOSD - General Modules", "https://web.stanford.edu/~ouster/cgi-bin/cs190-winter25/lecture.php?topic=modularDesign"),
        ]
    },
    "different-layer": {
        "title": "Different Layer, Different Abstraction",
        "summary": "Adjacent layers should provide different levels of abstraction. Pass-through methods are a red flag.",
        "links": [
            ("APOSD - Abstraction Layers", "https://web.stanford.edu/~ouster/cgi-bin/cs190-winter25/lecture.php?topic=modularDesign"),
        ]
    },
    "define-errors-out": {
        "title": "Define Errors Out of Existence",
        "summary": "The best error handling is design that prevents the error. Exceptions add complexity—use sparingly.",
        "links": [
            ("APOSD - Error Handling", "https://web.stanford.edu/~ouster/cgi-bin/cs190-winter25/lecture.php?topic=errors"),
        ]
    },
    "design-it-twice": {
        "title": "Design it Twice",
        "summary": "For important design problems, sketch at least two radically different approaches and compare trade-offs.",
        "links": [
            ("APOSD - Design It Twice", "https://web.stanford.edu/~ouster/cgi-bin/cs190-winter25/lecture.php?topic=designItTwice"),
        ]
    },
    "comments-as-design": {
        "title": "Comments as Design Tool",
        "summary": "Write comments first. If a method is hard to describe, the design is wrong. Focus on WHY, not WHAT.",
        "links": [
            ("APOSD - Comments", "https://web.stanford.edu/~ouster/cgi-bin/cs190-winter25/lecture.php?topic=comments"),
        ]
    },
    "names": {
        "title": "Good Names",
        "summary": "Names should be precise and obvious. If a variable needs a comment to explain it, the name is bad.",
        "links": [
            ("APOSD - Naming", "https://web.stanford.edu/~ouster/cgi-bin/cs190-winter25/lecture.php?topic=names"),
        ]
    },
}

RED_FLAGS = {
    "information-leakage": {
        "title": "Information Leakage",
        "icon": "🔓",
        "description": "A design decision is reflected in multiple modules.",
        "fix": "Extract the decision into a single module or interface.",
    },
    "pass-through": {
        "title": "Pass-Through Method/Class",
        "icon": "📨",
        "description": "A method that only forwards to another with a similar signature.",
        "fix": "Merge or rethink the module boundary.",
    },
    "repetition": {
        "title": "Repetition",
        "icon": "🔁",
        "description": "The same pattern appears repeatedly.",
        "fix": "Find the missing abstraction and extract it.",
    },
    "vague-names": {
        "title": "Vague Names",
        "icon": "❓",
        "description": "Variables like count, data, result that don't create a clear image.",
        "fix": "Be precise. Name after the role, not the type.",
    },
    "temporal-decomposition": {
        "title": "Temporal Decomposition",
        "icon": "⏱️",
        "description": "Modules split by execution order rather than functionality.",
        "fix": "Group by what changes together, not by when it runs.",
    },
    "shallow-module": {
        "title": "Shallow Module",
        "icon": "🥣",
        "description": "Complex interface for small functionality.",
        "fix": "Merge with callers or expand functionality.",
    },
    "change-amplification": {
        "title": "Change Amplification",
        "icon": "📣",
        "description": "A small change requires many modifications.",
        "fix": "Identify the leaked information and consolidate.",
    },
    "cognitive-load": {
        "title": "High Cognitive Load",
        "icon": "🧠",
        "description": "Need to know too many unrelated things to use a module.",
        "fix": "Simplify the interface; hide details.",
    },
    "unknown-unknowns": {
        "title": "Unknown Unknowns",
        "icon": "🌑",
        "description": "Hidden side effects or implicit contracts.",
        "fix": "Make contracts explicit in names, types, and comments.",
    },
}


def get_git_info(session_dir):
    """Collect git diff and recent commit info from session_dir."""
    info = {"diff": "", "recent_commits": "", "files_changed": []}
    try:
        result = subprocess.run(
            ["git", "-C", session_dir, "diff", "HEAD~1", "HEAD"],
            capture_output=True, text=True, timeout=30
        )
        info["diff"] = result.stdout or result.stderr or "No diff available."
    except Exception as e:
        info["diff"] = f"Could not get diff: {e}"

    try:
        result = subprocess.run(
            ["git", "-C", session_dir, "log", "--oneline", "-10"],
            capture_output=True, text=True, timeout=10
        )
        info["recent_commits"] = result.stdout or "No recent commits."
    except Exception as e:
        info["recent_commits"] = f"Could not get commits: {e}"

    try:
        result = subprocess.run(
            ["git", "-C", session_dir, "diff", "--name-only", "HEAD~1", "HEAD"],
            capture_output=True, text=True, timeout=10
        )
        info["files_changed"] = [f.strip() for f in result.stdout.splitlines() if f.strip()]
    except Exception:
        pass

    return info


def extract_code_blocks(text):
    """Extract fenced code blocks from markdown text."""
    pattern = r"```(\w+)?\n(.*?)```"
    matches = re.findall(pattern, text, re.DOTALL)
    return [(lang or "text", code) for lang, code in matches]


def detect_principles_in_text(text):
    """Detect which APOSD principles are mentioned in the review text."""
    found = []
    lower = text.lower()
    for key, data in APOSD_PRINCIPLES.items():
        if key.replace("-", " ") in lower or data["title"].lower() in lower:
            found.append((key, data))
    return found


def detect_red_flags_in_text(text):
    """Detect which red flags are mentioned in the review text."""
    found = []
    lower = text.lower()
    for key, data in RED_FLAGS.items():
        if key.replace("-", " ") in lower or data["title"].lower() in lower:
            found.append((key, data))
    return found


def escape_js_string(s):
    return json.dumps(s)


def generate_html(title, session_dir, review_text, git_info):
    principles_found = detect_principles_in_text(review_text)
    red_flags_found = detect_red_flags_in_text(review_text)
    code_blocks = extract_code_blocks(review_text)
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M")

    # Build a simple text-only summary for the narrative section
    # Strip code blocks for the narrative display
    narrative = re.sub(r"```.*?```", "\n[code snippet]\n", review_text, flags=re.DOTALL)

    import json

    principles_json = json.dumps([
        {"key": k, "title": d["title"], "summary": d["summary"], "links": d["links"]}
        for k, d in APOSD_PRINCIPLES.items()
    ])
    redflags_json = json.dumps([
        {"key": k, "title": d["title"], "icon": d["icon"], "description": d["description"], "fix": d["fix"]}
        for k, d in RED_FLAGS.items()
    ])

    html_content = f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>{html.escape(title)}</title>
<style>
:root {{
  --bg: #0d1117;
  --surface: #161b22;
  --surface-2: #21262d;
  --border: #30363d;
  --text: #c9d1d9;
  --text-secondary: #8b949e;
  --accent: #58a6ff;
  --accent-2: #3fb950;
  --warn: #f85149;
  --warn-bg: rgba(248,81,73,0.1);
  --code-bg: #1e1e1e;
  --shadow: 0 4px 20px rgba(0,0,0,0.4);
}}
[data-theme="light"] {{
  --bg: #ffffff;
  --surface: #f6f8fa;
  --surface-2: #eaeef2;
  --border: #d0d7de;
  --text: #24292f;
  --text-secondary: #57606a;
  --accent: #0969da;
  --accent-2: #1a7f37;
  --warn: #cf222e;
  --warn-bg: rgba(207,34,46,0.08);
  --code-bg: #f6f8fa;
  --shadow: 0 4px 20px rgba(0,0,0,0.08);
}}
* {{ box-sizing: border-box; }}
body {{
  margin: 0;
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
  background: var(--bg);
  color: var(--text);
  line-height: 1.6;
  transition: background 0.3s, color 0.3s;
}}
.container {{
  max-width: 1200px;
  margin: 0 auto;
  padding: 2rem;
}}
header {{
  text-align: center;
  padding: 3rem 1rem;
  border-bottom: 1px solid var(--border);
  margin-bottom: 2rem;
}}
header h1 {{
  font-size: 2.5rem;
  margin: 0 0 0.5rem;
  background: linear-gradient(90deg, var(--accent), var(--accent-2));
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
}}
header .meta {{
  color: var(--text-secondary);
  font-size: 0.95rem;
}}
.theme-toggle {{
  position: fixed;
  top: 1rem;
  right: 1rem;
  background: var(--surface);
  border: 1px solid var(--border);
  color: var(--text);
  padding: 0.5rem 1rem;
  border-radius: 6px;
  cursor: pointer;
  z-index: 1000;
  font-size: 0.85rem;
}}
.theme-toggle:hover {{ background: var(--surface-2); }}

/* Sidebar nav */
.nav-sidebar {{
  position: fixed;
  left: 0;
  top: 0;
  width: 260px;
  height: 100vh;
  background: var(--surface);
  border-right: 1px solid var(--border);
  overflow-y: auto;
  padding: 1rem;
  transform: translateX(0);
  transition: transform 0.3s;
  z-index: 900;
}}
.nav-sidebar.collapsed {{ transform: translateX(-100%); }}
.nav-toggle {{
  position: fixed;
  top: 1rem;
  left: 1rem;
  background: var(--surface);
  border: 1px solid var(--border);
  color: var(--text);
  padding: 0.5rem;
  border-radius: 6px;
  cursor: pointer;
  z-index: 1001;
  font-size: 1rem;
}}
.nav-sidebar h3 {{
  font-size: 0.75rem;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: var(--text-secondary);
  margin: 1.5rem 0 0.5rem;
  padding-left: 0.5rem;
}}
.nav-sidebar a {{
  display: block;
  padding: 0.4rem 0.5rem;
  color: var(--text);
  text-decoration: none;
  border-radius: 4px;
  font-size: 0.9rem;
}}
.nav-sidebar a:hover {{
  background: var(--surface-2);
  color: var(--accent);
}}
.nav-sidebar a.active {{
  background: var(--surface-2);
  color: var(--accent);
  font-weight: 600;
}}
main {{
  margin-left: 260px;
  transition: margin-left 0.3s;
}}
main.collapsed {{ margin-left: 0; }}

@media (max-width: 900px) {{
  .nav-sidebar {{ transform: translateX(-100%); }}
  .nav-sidebar.open {{ transform: translateX(0); }}
  main {{ margin-left: 0; }}
}}

/* Sections */
section {{
  margin-bottom: 3rem;
  scroll-margin-top: 1rem;
}}
section h2 {{
  font-size: 1.6rem;
  border-bottom: 2px solid var(--accent);
  padding-bottom: 0.3rem;
  margin-bottom: 1rem;
  display: flex;
  align-items: center;
  gap: 0.5rem;
}}

/* Cards */
.card-grid {{
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 1rem;
}}
.card {{
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: 8px;
  padding: 1.2rem;
  transition: transform 0.15s, box-shadow 0.15s;
}}
.card:hover {{
  transform: translateY(-2px);
  box-shadow: var(--shadow);
}}
.card h4 {{
  margin: 0 0 0.5rem;
  color: var(--accent);
  font-size: 1.05rem;
}}
.card p {{
  margin: 0;
  color: var(--text-secondary);
  font-size: 0.9rem;
}}
.card .tag {{
  display: inline-block;
  margin-top: 0.6rem;
  font-size: 0.75rem;
  padding: 0.2rem 0.5rem;
  border-radius: 12px;
  background: var(--surface-2);
  color: var(--text-secondary);
}}
.card.found {{
  border-left: 3px solid var(--accent-2);
}}
.card.flagged {{
  border-left: 3px solid var(--warn);
  background: var(--warn-bg);
}}

/* Red flag specific */
.redflag-card {{
  display: flex;
  align-items: flex-start;
  gap: 0.8rem;
}}
.redflag-card .icon {{
  font-size: 1.5rem;
  flex-shrink: 0;
}}
.redflag-card h4 {{
  margin: 0 0 0.3rem;
  color: var(--warn);
}}
.redflag-card .fix {{
  font-size: 0.85rem;
  color: var(--text-secondary);
  margin-top: 0.4rem;
  font-style: italic;
}}

/* Code */
.code-block {{
  position: relative;
  margin: 1rem 0;
  border-radius: 8px;
  overflow: hidden;
  border: 1px solid var(--border);
}}
.code-header {{
  display: flex;
  justify-content: space-between;
  align-items: center;
  background: var(--surface-2);
  padding: 0.4rem 0.8rem;
  font-size: 0.8rem;
  color: var(--text-secondary);
  border-bottom: 1px solid var(--border);
}}
.code-header button {{
  background: transparent;
  border: 1px solid var(--border);
  color: var(--text-secondary);
  padding: 0.2rem 0.6rem;
  border-radius: 4px;
  cursor: pointer;
  font-size: 0.75rem;
}}
.code-header button:hover {{
  color: var(--text);
  border-color: var(--text);
}}
pre {{
  margin: 0;
  padding: 1rem;
  overflow-x: auto;
  background: var(--code-bg);
  font-family: "SF Mono", Monaco, Inconsolata, "Fira Code", monospace;
  font-size: 0.9rem;
  line-height: 1.5;
}}
code {{
  font-family: "SF Mono", Monaco, Inconsolata, "Fira Code", monospace;
  font-size: 0.9em;
}}

/* Diff */
.diff-block {{
  background: var(--code-bg);
  border-radius: 8px;
  overflow-x: auto;
  border: 1px solid var(--border);
}}
.diff-line {{
  padding: 0.15rem 1rem;
  font-family: monospace;
  font-size: 0.85rem;
  white-space: pre;
}}
.diff-add {{ background: rgba(46,160,67,0.15); color: #3fb950; }}
.diff-del {{ background: rgba(248,81,73,0.15); color: #f85149; }}
.diff-hdr {{ color: var(--accent); font-weight: bold; }}
.diff-ctx {{ color: var(--text-secondary); }}

/* Collapsible */
.collapsible-header {{
  cursor: pointer;
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0.8rem 1rem;
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: 6px;
  margin-bottom: 0.5rem;
}}
.collapsible-header:hover {{ background: var(--surface-2); }}
.collapsible-body {{
  display: none;
  padding: 0 1rem 1rem;
}}
.collapsible-body.open {{ display: block; }}
.chevron {{ transition: transform 0.2s; }}
.collapsible-header.open .chevron {{ transform: rotate(180deg); }}

/* Narrative */
.narrative {{
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: 8px;
  padding: 1.5rem;
  white-space: pre-wrap;
  font-size: 0.95rem;
  line-height: 1.7;
}}
.narrative code {{
  background: var(--code-bg);
  padding: 0.15rem 0.35rem;
  border-radius: 4px;
  border: 1px solid var(--border);
}}

/* Links */
.doc-link {{
  display: inline-flex;
  align-items: center;
  gap: 0.3rem;
  color: var(--accent);
  text-decoration: none;
  font-size: 0.85rem;
  margin-top: 0.5rem;
}}
.doc-link:hover {{ text-decoration: underline; }}

/* Footer */
footer {{
  text-align: center;
  padding: 3rem 1rem;
  color: var(--text-secondary);
  font-size: 0.85rem;
  border-top: 1px solid var(--border);
  margin-top: 3rem;
}}

/* Takeaway box */
.takeaway {{
  background: linear-gradient(135deg, rgba(88,166,255,0.1), rgba(63,185,80,0.1));
  border: 1px solid var(--accent);
  border-radius: 10px;
  padding: 1.5rem;
  margin-top: 1rem;
}}
.takeaway h4 {{
  margin: 0 0 0.5rem;
  color: var(--accent);
}}
</style>
</head>
<body data-theme="dark">

<button class="theme-toggle" onclick="toggleTheme()">🌓 Theme</button>
<button class="nav-toggle" onclick="toggleNav()">☰</button>

<nav class="nav-sidebar" id="navSidebar">
  <h3>Sections</h3>
  <a href="#summary" class="active" onclick="setActive(this)">Session Summary</a>
  <a href="#diff" onclick="setActive(this)">Git Diff</a>
  <a href="#narrative" onclick="setActive(this)">Review Narrative</a>
  <a href="#principles" onclick="setActive(this)">Principles Applied</a>
  <a href="#redflags" onclick="setActive(this)">Red Flags Found</a>
  <a href="#code" onclick="setActive(this)">Code Snippets</a>
  <a href="#takeaway" onclick="setActive(this)">Key Takeaway</a>

  <h3>External Docs</h3>
  <a href="https://web.stanford.edu/~ouster/cgi-bin/cs190-winter25/" target="_blank">APOSD Course</a>
  <a href="https://www.amazon.com/Philosophy-Software-Design-John-Ousterhout/dp/1732102201" target="_blank">Buy the Book</a>
  <a href="https://web.stanford.edu/~ouster/cgi-bin/cs190-winter25/lecture.php?topic=redFlags" target="_blank">Red Flags Lecture</a>
</nav>

<main id="mainContent">
  <div class="container">
    <header>
      <h1>🎓 Session Design Review</h1>
      <div class="meta">
        <strong>Project:</strong> {html.escape(session_dir or "Current Session")} &nbsp;|&nbsp;
        <strong>Date:</strong> {timestamp}
      </div>
    </header>

    <section id="summary">
      <h2>📋 Session Summary</h2>
      <div class="card-grid">
        <div class="card">
          <h4>Files Changed</h4>
          <p>{len(git_info.get('files_changed', []))} file(s)</p>
          <div class="tag">{', '.join(html.escape(f) for f in (git_info.get('files_changed') or ['N/A'])[:5])}{'...' if len(git_info.get('files_changed') or []) > 5 else ''}</div>
        </div>
        <div class="card">
          <h4>Principles Evaluated</h4>
          <p>{len(principles_found)} principle(s) discussed</p>
          <div class="tag">{'Found' if principles_found else 'Check references'}</div>
        </div>
        <div class="card">
          <h4>Red Flags</h4>
          <p>{len(red_flags_found)} flag(s) identified</p>
          <div class="tag">{'Review needed' if red_flags_found else 'Clean session!'}</div>
        </div>
        <div class="card">
          <h4>Code Snippets</h4>
          <p>{len(code_blocks)} snippet(s)</p>
          <div class="tag">Review below</div>
        </div>
      </div>
    </section>

    <section id="diff">
      <h2>🔍 Git Diff</h2>
      <div class="collapsible-header" onclick="toggleCollapse(this)">
        <span>View diff (click to expand)</span>
        <span class="chevron">▼</span>
      </div>
      <div class="collapsible-body">
        <div class="diff-block">
"""
    # Render git diff with simple syntax highlighting
    diff_lines = git_info.get("diff", "").splitlines()
    for line in diff_lines[:500]:  # limit for perf
        escaped = html.escape(line)
        if line.startswith("+") and not line.startswith("+++"):
            html_content += f'<div class="diff-line diff-add">{escaped}</div>\n'
        elif line.startswith("-") and not line.startswith("---"):
            html_content += f'<div class="diff-line diff-del">{escaped}</div>\n'
        elif line.startswith("@@") or line.startswith("diff ") or line.startswith("index "):
            html_content += f'<div class="diff-line diff-hdr">{escaped}</div>\n'
        else:
            html_content += f'<div class="diff-line diff-ctx">{escaped}</div>\n'
    if len(diff_lines) > 500:
        html_content += f'<div class="diff-line diff-ctx">... ({len(diff_lines) - 500} more lines) ...</div>\n'

    html_content += """        </div>
      </div>
    </section>

    <section id="narrative">
      <h2>📝 Review Narrative</h2>
      <div class="narrative">"""
    # Simple markdown-ish formatting for narrative
    narrative_html = html.escape(narrative)
    # Convert headers
    narrative_html = re.sub(r'^(#{1,3})\s+(.+)$', r'<h3>\2</h3>', narrative_html, flags=re.MULTILINE)
    # Convert bold
    narrative_html = re.sub(r'\*\*(.+?)\*\*', r'<strong>\1</strong>', narrative_html)
    # Convert bullets
    narrative_html = re.sub(r'^\s*[-*]\s+(.+)$', r'<li>\1</li>', narrative_html, flags=re.MULTILINE)
    # Wrap consecutive li in ul
    narrative_html = re.sub(r'((?:<li>.+</li>\n)+)', r'<ul>\1</ul>', narrative_html)
    # Convert links
    narrative_html = re.sub(r'\[([^\]]+)\]\(([^)]+)\)', r'<a href="\2" target="_blank" class="doc-link">\1</a>', narrative_html)
    html_content += narrative_html
    html_content += """</div>
    </section>

    <section id="principles">
      <h2>📐 Principles from <em>A Philosophy of Software Design</em></h2>
      <div class="card-grid" id="principlesGrid">
        <!-- Populated by JS -->
      </div>
    </section>

    <section id="redflags">
      <h2>🚩 Red Flags Checklist</h2>
      <div class="card-grid" id="redflagsGrid">
        <!-- Populated by JS -->
      </div>
    </section>

    <section id="code">
      <h2>💻 Code Snippets from Review</h2>
"""
    for i, (lang, code) in enumerate(code_blocks[:20]):
        safe_code = html.escape(code)
        html_content += f"""
      <div class="code-block">
        <div class="code-header">
          <span>{html.escape(lang)}</span>
          <button onclick="copyCode(this)">Copy</button>
        </div>
        <pre><code>{safe_code}</code></pre>
      </div>
"""
    if not code_blocks:
        html_content += '<p style="color:var(--text-secondary)">No code blocks found in the review text.</p>'

    html_content += """
    </section>

    <section id="takeaway">
      <h2>🎯 Key Takeaway</h2>
      <div class="takeaway">
        <h4>Reflect on this session:</h4>
        <p>If you had to change the most important design decision from this session tomorrow, how many files would you touch?</p>
        <p style="margin-top:0.8rem; color:var(--text-secondary); font-size:0.9rem;">
          The best design is one where a single change requires a single modification.
        </p>
      </div>
    </section>

    <footer>
      Generated by <strong>software-design-expert-learn</strong> skill &nbsp;|&nbsp;
      Based on <em>A Philosophy of Software Design</em> by John Ousterhout
    </footer>
  </div>
</main>

<script>
const PRINCIPLES = """ + principles_json + """;
const REDFLAGS = """ + redflags_json + """;
const FOUND_KEYS = new Set(""" + json.dumps([k for k, _ in principles_found]) + """);
const FOUND_FLAGS = new Set(""" + json.dumps([k for k, _ in red_flags_found]) + """);

function renderPrinciples() {
  const grid = document.getElementById('principlesGrid');
  grid.innerHTML = PRINCIPLES.map(p => {
    const found = FOUND_KEYS.has(p.key);
    return `<div class="card ${found ? 'found' : ''}">
      <h4>${p.title} ${found ? '✓' : ''}</h4>
      <p>${p.summary}</p>
      ${p.links.map(l => `<a href="${l[1]}" target="_blank" class="doc-link">📖 ${l[0]}</a>`).join('')}
      ${found ? '<span class="tag">Discussed</span>' : '<span class="tag">Reference</span>'}
    </div>`;
  }).join('');
}

function renderRedFlags() {
  const grid = document.getElementById('redflagsGrid');
  grid.innerHTML = REDFLAGS.map(r => {
    const found = FOUND_FLAGS.has(r.key);
    return `<div class="card redflag-card ${found ? 'flagged' : ''}">
      <span class="icon">${r.icon}</span>
      <div>
        <h4>${r.title} ${found ? '⚠️' : ''}</h4>
        <p>${r.description}</p>
        <div class="fix">Fix: ${r.fix}</div>
        ${found ? '<span class="tag">Found in review</span>' : '<span class="tag">Clean</span>'}
      </div>
    </div>`;
  }).join('');
}

function toggleTheme() {
  const body = document.body;
  body.dataset.theme = body.dataset.theme === 'dark' ? 'light' : 'dark';
  localStorage.setItem('sdr-theme', body.dataset.theme);
}

function toggleNav() {
  const nav = document.getElementById('navSidebar');
  nav.classList.toggle('open');
}

function setActive(el) {
  document.querySelectorAll('.nav-sidebar a').forEach(a => a.classList.remove('active'));
  el.classList.add('active');
}

function toggleCollapse(header) {
  const body = header.nextElementSibling;
  body.classList.toggle('open');
  header.classList.toggle('open');
}

function copyCode(btn) {
  const code = btn.closest('.code-block').querySelector('code').innerText;
  navigator.clipboard.writeText(code).then(() => {
    btn.textContent = 'Copied!';
    setTimeout(() => btn.textContent = 'Copy', 1500);
  });
}

// Restore theme
const savedTheme = localStorage.getItem('sdr-theme');
if (savedTheme) document.body.dataset.theme = savedTheme;

renderPrinciples();
renderRedFlags();
</script>

</body>
</html>"""

    return html_content


def main():
    parser = argparse.ArgumentParser(
        description="Generate an interactive HTML design review report."
    )
    parser.add_argument("-i", "--input", help="Input review text file (default: stdin)")
    parser.add_argument("-o", "--output", default="software-design-expert-learn.html", help="Output HTML file")
    parser.add_argument("--title", default="Session Design Review", help="Report title")
    parser.add_argument("--session-dir", default=".", help="Directory of the coding session (for git diff)")
    parser.add_argument("--diff-only", action="store_true", help="Only include git diff, no review text")
    args = parser.parse_args()

    if args.input:
        with open(args.input, "r", encoding="utf-8") as f:
            review_text = f.read()
    else:
        review_text = sys.stdin.read()

    if args.diff_only:
        review_text = "(Diff-only mode. See Git Diff section for changes.)"

    git_info = get_git_info(args.session_dir)

    html_out = generate_html(args.title, args.session_dir, review_text, git_info)

    with open(args.output, "w", encoding="utf-8") as f:
        f.write(html_out)

    print(f"Report written to: {os.path.abspath(args.output)}")


if __name__ == "__main__":
    main()
