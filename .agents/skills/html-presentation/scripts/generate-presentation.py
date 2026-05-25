#!/usr/bin/env python3
"""
generate-presentation.py — Generic HTML presentation generator.

Produces a single self-contained HTML file (no external assets, no build
step) from either a structured JSON input or a markdown file.

Design references behind this template are in
../references/design-principles.md. Maintain that file when the visual
language changes.

Usage:
    python3 generate-presentation.py --input deck.json --mode report -o out.html
    python3 generate-presentation.py --markdown review.md --title "Review" -o out.html
    python3 generate-presentation.py --markdown - --mode slides -o out.html  # stdin
"""

from __future__ import annotations

import argparse
import html
import json
import os
import re
import sys
from datetime import datetime
from typing import Any


# ---------------------------------------------------------------------------
# Input parsing
# ---------------------------------------------------------------------------

def load_input(args: argparse.Namespace) -> dict[str, Any]:
    if args.input:
        with open(args.input, "r", encoding="utf-8") as fh:
            data = json.load(fh)
    elif args.markdown:
        text = sys.stdin.read() if args.markdown == "-" else open(args.markdown, encoding="utf-8").read()
        data = markdown_to_structured(text, title=args.title)
    else:
        sys.exit("error: must pass --input <json> or --markdown <file|->")

    data.setdefault("title", args.title or "Presentation")
    data.setdefault("subtitle", args.subtitle or "")
    data.setdefault("takeaway", "")
    data.setdefault("meta", {})
    data.setdefault("summary_cards", [])
    data.setdefault("sections", [])
    data.setdefault("code_blocks", [])
    data.setdefault("references", [])
    data.setdefault("reflection", "")
    return data


def markdown_to_structured(text: str, title: str | None = None) -> dict[str, Any]:
    """Best-effort parse of a markdown doc into the structured schema.

    Heuristics:
      - First H1 becomes the title.
      - Lines immediately after the H1 (before any H2) become the takeaway
        + meta (first non-empty paragraph → takeaway).
      - Each H2 starts a new section; its body is everything until the
        next H2 or EOF.
    """
    lines = text.splitlines()
    parsed_title = title
    takeaway = ""
    sections: list[dict[str, Any]] = []

    i = 0
    # Extract title
    while i < len(lines):
        m = re.match(r"^#\s+(.+)$", lines[i])
        if m:
            parsed_title = parsed_title or m.group(1).strip()
            i += 1
            break
        i += 1

    # Extract takeaway (first non-empty paragraph before any H2)
    intro_buf: list[str] = []
    while i < len(lines) and not re.match(r"^##\s+", lines[i]):
        intro_buf.append(lines[i])
        i += 1
    intro_text = "\n".join(intro_buf).strip()
    if intro_text:
        first_para = re.split(r"\n\s*\n", intro_text, maxsplit=1)[0].strip()
        takeaway = first_para

    # Parse sections
    current: dict[str, Any] | None = None
    body_buf: list[str] = []

    def flush() -> None:
        if current is not None:
            current["body_md"] = "\n".join(body_buf).strip()
            sections.append(current)

    while i < len(lines):
        h2 = re.match(r"^##\s+(.+)$", lines[i])
        if h2:
            flush()
            title_text = h2.group(1).strip()
            # Extract optional leading emoji as icon
            icon_m = re.match(r"^([^\w\s])\s+(.*)$", title_text)
            icon, label = (icon_m.group(1), icon_m.group(2)) if icon_m else ("", title_text)
            current = {
                "id": slugify(label),
                "title": label,
                "icon": icon,
                "body_md": "",
            }
            body_buf = []
        else:
            body_buf.append(lines[i])
        i += 1
    flush()

    return {
        "title": parsed_title or "Presentation",
        "takeaway": takeaway,
        "sections": sections,
    }


def slugify(text: str) -> str:
    text = re.sub(r"[^\w\s-]", "", text.lower())
    return re.sub(r"[\s_-]+", "-", text).strip("-") or "section"


# ---------------------------------------------------------------------------
# Markdown → HTML (minimal, safe)
# ---------------------------------------------------------------------------

def md_to_html(text: str) -> str:
    """Tiny markdown subset → HTML. Keeps the script self-contained.

    Supports: ### headings, **bold**, *italic*, `inline code`,
    fenced ```code``` blocks, bullet lists, [text](url).
    """
    # Pull out fenced code first to protect content.
    code_placeholders: list[str] = []

    def stash_code(m: re.Match[str]) -> str:
        lang = (m.group(1) or "").strip()
        body = m.group(2)
        idx = len(code_placeholders)
        code_placeholders.append(
            f'<pre><code class="lang-{html.escape(lang)}">{html.escape(body)}</code></pre>'
        )
        return f"\x00CODE{idx}\x00"

    text = re.sub(r"```(\w+)?\n(.*?)```", stash_code, text, flags=re.DOTALL)

    text = html.escape(text)

    # Headings
    text = re.sub(r"^####\s+(.+)$", r"<h4>\1</h4>", text, flags=re.MULTILINE)
    text = re.sub(r"^###\s+(.+)$", r"<h3>\1</h3>", text, flags=re.MULTILINE)

    # Bold / italic / inline code
    text = re.sub(r"\*\*(.+?)\*\*", r"<strong>\1</strong>", text)
    text = re.sub(r"(?<!\*)\*(?!\s)(.+?)(?<!\s)\*(?!\*)", r"<em>\1</em>", text)
    text = re.sub(r"`([^`]+)`", r"<code>\1</code>", text)

    # Links
    text = re.sub(
        r"\[([^\]]+)\]\((https?://[^)]+)\)",
        r'<a href="\2" target="_blank" rel="noopener">\1</a>',
        text,
    )

    # Bullets
    lines = text.splitlines()
    out: list[str] = []
    in_list = False
    for line in lines:
        bullet = re.match(r"^\s*[-*]\s+(.+)$", line)
        if bullet:
            if not in_list:
                out.append("<ul>")
                in_list = True
            out.append(f"<li>{bullet.group(1)}</li>")
        else:
            if in_list:
                out.append("</ul>")
                in_list = False
            out.append(line)
    if in_list:
        out.append("</ul>")

    text = "\n".join(out)

    # Paragraphs: wrap stand-alone lines separated by blank lines.
    blocks = re.split(r"\n\s*\n", text)
    rendered: list[str] = []
    for block in blocks:
        stripped = block.strip()
        if not stripped:
            continue
        if stripped.startswith(("<h", "<ul", "<pre", "<table", "<div", "<blockquote")):
            rendered.append(stripped)
        elif "\x00CODE" in stripped:
            rendered.append(stripped)
        else:
            rendered.append(f"<p>{stripped}</p>")
    text = "\n\n".join(rendered)

    # Restore code blocks
    for idx, code in enumerate(code_placeholders):
        text = text.replace(f"\x00CODE{idx}\x00", code)

    return text


# ---------------------------------------------------------------------------
# HTML rendering
# ---------------------------------------------------------------------------

BASE_CSS = """
:root {
  --bg: #0d1117; --surface: #161b22; --surface-2: #21262d;
  --border: #30363d; --text: #c9d1d9; --text-secondary: #8b949e;
  --accent: #58a6ff; --accent-2: #3fb950; --warn: #f85149;
  --warn-bg: rgba(248,81,73,0.12); --code-bg: #1e1e1e;
  --shadow: 0 4px 20px rgba(0,0,0,0.4); --radius: 10px;
}
[data-theme="light"] {
  --bg: #ffffff; --surface: #f6f8fa; --surface-2: #eaeef2;
  --border: #d0d7de; --text: #1f2328; --text-secondary: #57606a;
  --accent: #0969da; --accent-2: #1a7f37; --warn: #cf222e;
  --warn-bg: rgba(207,34,46,0.08); --code-bg: #f6f8fa;
  --shadow: 0 4px 20px rgba(31,35,40,0.08);
}
* { box-sizing: border-box; }
html { scroll-behavior: smooth; }
body {
  margin: 0; background: var(--bg); color: var(--text);
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
  line-height: 1.65; font-size: 16px;
  transition: background 0.25s, color 0.25s;
}
a { color: var(--accent); text-decoration: none; }
a:hover { text-decoration: underline; }
.container { max-width: 880px; margin: 0 auto; padding: 2.5rem 1.5rem 4rem; }
@media (min-width: 1100px) { .container { max-width: 920px; } }

/* Hero */
.hero { padding: 3rem 0 2rem; border-bottom: 1px solid var(--border); margin-bottom: 2.5rem; }
.hero h1 {
  font-size: clamp(1.8rem, 4vw, 2.6rem); margin: 0 0 0.5rem; letter-spacing: -0.02em;
  background: linear-gradient(90deg, var(--accent), var(--accent-2));
  -webkit-background-clip: text; -webkit-text-fill-color: transparent;
}
.hero .subtitle { color: var(--text-secondary); font-size: 1rem; margin-bottom: 1rem; }
.hero .takeaway {
  font-size: 1.15rem; line-height: 1.5; padding: 1rem 1.2rem;
  border-left: 3px solid var(--accent); background: var(--surface);
  border-radius: 0 var(--radius) var(--radius) 0; margin: 1.2rem 0;
}
.hero .meta {
  display: flex; flex-wrap: wrap; gap: 0.5rem 1.2rem;
  color: var(--text-secondary); font-size: 0.85rem; margin-top: 1rem;
}
.hero .meta span strong { color: var(--text); margin-right: 0.25rem; }

/* Summary cards */
.cards { display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
  gap: 0.8rem; margin: 1.5rem 0 2.5rem; }
.card {
  background: var(--surface); border: 1px solid var(--border);
  border-radius: var(--radius); padding: 1rem 1.1rem;
  transition: transform 0.15s, box-shadow 0.15s;
}
.card:hover { transform: translateY(-1px); box-shadow: var(--shadow); }
.card .label { font-size: 0.75rem; text-transform: uppercase; letter-spacing: 0.05em;
  color: var(--text-secondary); margin-bottom: 0.25rem; }
.card .value { font-size: 1.6rem; font-weight: 600; color: var(--accent); line-height: 1.1; }
.card .hint { font-size: 0.8rem; color: var(--text-secondary); margin-top: 0.4rem; }

/* Sections */
section { margin: 2.5rem 0; scroll-margin-top: 1.5rem; }
section > h2 {
  font-size: 1.45rem; margin: 0 0 1rem; padding-bottom: 0.4rem;
  border-bottom: 2px solid var(--accent); display: flex; gap: 0.5rem; align-items: baseline;
}
section h3 { font-size: 1.1rem; margin: 1.4rem 0 0.5rem; }
section p { margin: 0.7rem 0; }
section ul { padding-left: 1.4rem; margin: 0.5rem 0; }
section li { margin: 0.3rem 0; }

/* Sidebar nav */
.nav-sidebar {
  position: fixed; top: 0; left: 0; height: 100vh; width: 240px;
  padding: 1.5rem 0.8rem; overflow-y: auto;
  background: var(--surface); border-right: 1px solid var(--border);
  transform: translateX(0); transition: transform 0.25s; z-index: 100;
}
.nav-sidebar.hidden { transform: translateX(-100%); }
.nav-sidebar h3 {
  font-size: 0.7rem; text-transform: uppercase; letter-spacing: 0.08em;
  color: var(--text-secondary); margin: 1rem 0.5rem 0.4rem;
}
.nav-sidebar a {
  display: block; padding: 0.4rem 0.6rem; border-radius: 6px;
  color: var(--text); font-size: 0.9rem; line-height: 1.35;
}
.nav-sidebar a:hover { background: var(--surface-2); text-decoration: none; }
.nav-sidebar a.active { background: var(--surface-2); color: var(--accent); font-weight: 600; }
.layout { display: flex; }
.layout main { flex: 1; margin-left: 240px; min-width: 0; }
@media (max-width: 900px) {
  .nav-sidebar { transform: translateX(-100%); }
  .nav-sidebar.open { transform: translateX(0); box-shadow: var(--shadow); }
  .layout main { margin-left: 0; }
}

/* Toolbar buttons (theme, nav toggle) */
.toolbar { position: fixed; top: 1rem; right: 1rem; display: flex; gap: 0.4rem; z-index: 200; }
.toolbar button, .nav-toggle {
  background: var(--surface); border: 1px solid var(--border); color: var(--text);
  padding: 0.4rem 0.7rem; border-radius: 6px; cursor: pointer; font-size: 0.85rem;
}
.toolbar button:hover, .nav-toggle:hover { background: var(--surface-2); }
.nav-toggle { position: fixed; top: 1rem; left: 1rem; z-index: 200; }

/* Code */
pre {
  margin: 0.5rem 0; padding: 1rem 1.1rem; background: var(--code-bg);
  border: 1px solid var(--border); border-radius: var(--radius);
  overflow-x: auto; font-family: "SF Mono", Monaco, Consolas, "Fira Code", monospace;
  font-size: 0.85rem; line-height: 1.55;
}
code { font-family: "SF Mono", Monaco, Consolas, "Fira Code", monospace; font-size: 0.9em; }
p code, li code {
  padding: 0.1rem 0.35rem; background: var(--surface-2);
  border-radius: 4px; font-size: 0.85em;
}
.code-block { margin: 1rem 0; }
.code-block .caption {
  font-size: 0.85rem; color: var(--text-secondary); margin-bottom: 0.35rem;
  display: flex; justify-content: space-between; align-items: center;
}
.code-block .caption .lang { font-family: monospace; font-size: 0.75rem;
  padding: 0.1rem 0.4rem; border-radius: 4px; background: var(--surface-2); }

/* Collapsible */
details {
  background: var(--surface); border: 1px solid var(--border);
  border-radius: var(--radius); padding: 0.6rem 1rem; margin: 0.8rem 0;
}
details summary { cursor: pointer; font-weight: 600; }
details[open] { padding-bottom: 1rem; }

/* References footer */
.refs { display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 0.6rem; }
.refs a {
  display: block; padding: 0.8rem 1rem; background: var(--surface);
  border: 1px solid var(--border); border-radius: var(--radius);
  color: var(--text); font-size: 0.9rem;
}
.refs a:hover { border-color: var(--accent); text-decoration: none; }

/* Reflection */
.reflection {
  background: linear-gradient(135deg, rgba(88,166,255,0.10), rgba(63,185,80,0.10));
  border: 1px solid var(--accent); border-radius: var(--radius);
  padding: 1.3rem 1.5rem; margin: 2rem 0;
}
.reflection h3 { margin-top: 0; color: var(--accent); }

footer {
  margin-top: 4rem; padding-top: 1.5rem; border-top: 1px solid var(--border);
  color: var(--text-secondary); font-size: 0.85rem; text-align: center;
}

/* Slides mode */
body.mode-slides { overflow: hidden; }
body.mode-slides .layout main { margin-left: 0; }
body.mode-slides .nav-sidebar, body.mode-slides .nav-toggle { display: none; }
body.mode-slides .container { max-width: none; padding: 0; }
body.mode-slides .slide {
  width: 100vw; height: 100vh; padding: 4rem 6rem; display: none;
  flex-direction: column; justify-content: center;
}
body.mode-slides .slide.active { display: flex; }
body.mode-slides .slide h1 { font-size: clamp(2rem, 5vw, 3.5rem); }
body.mode-slides .slide h2 { font-size: clamp(1.6rem, 4vw, 2.4rem); border: none; }
body.mode-slides .slide-counter {
  position: fixed; bottom: 1rem; right: 1.5rem; color: var(--text-secondary);
  font-size: 0.85rem; font-family: monospace;
}
"""

BASE_JS = r"""
(function () {
  const root = document.documentElement;
  const saved = localStorage.getItem('html-presentation-theme');
  if (saved) document.body.dataset.theme = saved;
  else if (window.matchMedia && matchMedia('(prefers-color-scheme: light)').matches) {
    document.body.dataset.theme = 'light';
  } else {
    document.body.dataset.theme = 'dark';
  }

  window.toggleTheme = function () {
    const next = document.body.dataset.theme === 'dark' ? 'light' : 'dark';
    document.body.dataset.theme = next;
    localStorage.setItem('html-presentation-theme', next);
  };
  window.toggleNav = function () {
    document.querySelector('.nav-sidebar').classList.toggle('open');
  };
  document.querySelectorAll('.nav-sidebar a[href^="#"]').forEach(a => {
    a.addEventListener('click', () => {
      document.querySelectorAll('.nav-sidebar a').forEach(x => x.classList.remove('active'));
      a.classList.add('active');
    });
  });

  // Active section on scroll
  const sections = document.querySelectorAll('main section[id]');
  const links = new Map();
  document.querySelectorAll('.nav-sidebar a[href^="#"]').forEach(a => {
    links.set(a.getAttribute('href').slice(1), a);
  });
  if (sections.length && 'IntersectionObserver' in window) {
    const io = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          links.forEach(a => a.classList.remove('active'));
          const link = links.get(entry.target.id);
          if (link) link.classList.add('active');
        }
      });
    }, { rootMargin: '-40% 0px -55% 0px' });
    sections.forEach(s => io.observe(s));
  }

  // Slides keyboard nav
  if (document.body.classList.contains('mode-slides')) {
    const slides = Array.from(document.querySelectorAll('.slide'));
    let idx = 0;
    const counter = document.querySelector('.slide-counter');
    function show(n) {
      idx = Math.max(0, Math.min(slides.length - 1, n));
      slides.forEach((s, i) => s.classList.toggle('active', i === idx));
      if (counter) counter.textContent = (idx + 1) + ' / ' + slides.length;
    }
    show(0);
    document.addEventListener('keydown', (e) => {
      if (e.key === 'ArrowRight' || e.key === ' ' || e.key === 'PageDown') show(idx + 1);
      else if (e.key === 'ArrowLeft' || e.key === 'PageUp') show(idx - 1);
      else if (e.key === 'Home') show(0);
      else if (e.key === 'End') show(slides.length - 1);
    });
  }
})();
"""


def render_meta(meta: dict[str, Any]) -> str:
    if not meta:
        return ""
    parts = [
        f"<span><strong>{html.escape(str(k))}:</strong>{html.escape(str(v))}</span>"
        for k, v in meta.items()
    ]
    return f'<div class="meta">{"".join(parts)}</div>'


def render_cards(cards: list[dict[str, Any]]) -> str:
    if not cards:
        return ""
    items = []
    for c in cards[:6]:  # cap at 6 per design rule
        label = html.escape(str(c.get("label", "")))
        value = html.escape(str(c.get("value", "")))
        hint = html.escape(str(c.get("hint", "")))
        hint_html = f'<div class="hint">{hint}</div>' if hint else ""
        items.append(
            f'<div class="card"><div class="label">{label}</div>'
            f'<div class="value">{value}</div>'
            f"{hint_html}</div>"
        )
    return f'<div class="cards">{"".join(items)}</div>'


def render_sections_report(sections: list[dict[str, Any]]) -> str:
    parts: list[str] = []
    for sec in sections:
        sid = html.escape(sec.get("id") or slugify(sec.get("title", "section")))
        icon = html.escape(sec.get("icon", ""))
        title = html.escape(sec.get("title", "Section"))
        body = md_to_html(sec.get("body_md", ""))
        parts.append(
            f'<section id="{sid}"><h2>{icon + " " if icon else ""}{title}</h2>{body}</section>'
        )
    return "\n".join(parts)


def render_sections_slides(data: dict[str, Any]) -> str:
    slides: list[str] = []
    title = html.escape(data.get("title", ""))
    subtitle = html.escape(data.get("subtitle", ""))
    takeaway = html.escape(data.get("takeaway", ""))
    sub_html = f'<p class="subtitle">{subtitle}</p>' if subtitle else ""
    take_html = f'<p class="takeaway">{takeaway}</p>' if takeaway else ""
    slides.append(
        f'<div class="slide"><h1>{title}</h1>{sub_html}{take_html}</div>'
    )
    for sec in data.get("sections", []):
        icon = html.escape(sec.get("icon", ""))
        sec_title = html.escape(sec.get("title", ""))
        body = md_to_html(sec.get("body_md", ""))
        slides.append(f'<div class="slide"><h2>{icon + " " if icon else ""}{sec_title}</h2>{body}</div>')
    if data.get("reflection"):
        slides.append(
            f'<div class="slide"><h2>Reflect</h2><p>{html.escape(data["reflection"])}</p></div>'
        )
    counter = '<div class="slide-counter">1 / 1</div>'
    return "".join(slides) + counter


def render_code_blocks(blocks: list[dict[str, Any]]) -> str:
    if not blocks:
        return ""
    out = ['<section id="code-blocks"><h2>💻 Code</h2>']
    for b in blocks:
        lang = html.escape(b.get("lang", "text"))
        code = html.escape(b.get("code", ""))
        caption = html.escape(b.get("caption", ""))
        out.append(
            f'<div class="code-block">'
            f'<div class="caption"><span>{caption}</span><span class="lang">{lang}</span></div>'
            f'<pre><code class="lang-{lang}">{code}</code></pre>'
            f"</div>"
        )
    out.append("</section>")
    return "".join(out)


def render_references(refs: list[dict[str, Any]]) -> str:
    if not refs:
        return ""
    items = "".join(
        f'<a href="{html.escape(r.get("url", "#"))}" target="_blank" rel="noopener">'
        f'{html.escape(r.get("title", r.get("url", "Reference")))}</a>'
        for r in refs
    )
    return f'<section id="references"><h2>📚 References</h2><div class="refs">{items}</div></section>'


def render_reflection(text: str) -> str:
    if not text:
        return ""
    return (
        f'<section id="reflection"><div class="reflection">'
        f"<h3>Reflect</h3><p>{html.escape(text)}</p></div></section>"
    )


def render_nav(data: dict[str, Any]) -> str:
    links: list[str] = []
    for sec in data.get("sections", []):
        sid = html.escape(sec.get("id") or slugify(sec.get("title", "section")))
        title = html.escape(sec.get("title", "Section"))
        links.append(f'<a href="#{sid}">{title}</a>')
    if data.get("code_blocks"):
        links.append('<a href="#code-blocks">Code</a>')
    if data.get("reflection"):
        links.append('<a href="#reflection">Reflect</a>')
    if data.get("references"):
        links.append('<a href="#references">References</a>')
    if not links:
        return ""
    return (
        '<nav class="nav-sidebar" id="navSidebar">'
        '<h3>Contents</h3>'
        + "".join(links)
        + "</nav>"
    )


def render_html(data: dict[str, Any], mode: str) -> str:
    title = html.escape(data.get("title", "Presentation"))
    subtitle = html.escape(data.get("subtitle", ""))
    takeaway = html.escape(data.get("takeaway", ""))
    generated = datetime.now().strftime("%Y-%m-%d %H:%M")

    toolbar = (
        '<div class="toolbar">'
        '<button onclick="toggleTheme()" aria-label="Toggle theme">🌓 Theme</button>'
        "</div>"
        '<button class="nav-toggle" onclick="toggleNav()" aria-label="Toggle navigation">☰</button>'
    )

    if mode == "slides":
        body_inner = render_sections_slides(data)
        body_class = "mode-slides"
        nav = ""
    else:
        sub_html = f'<p class="subtitle">{subtitle}</p>' if subtitle else ""
        take_html = f'<p class="takeaway">{takeaway}</p>' if takeaway else ""
        hero = (
            f'<header class="hero"><h1>{title}</h1>'
            f"{sub_html}{take_html}"
            f"{render_meta(data.get('meta', {}))}</header>"
        )
        body_inner = (
            hero
            + render_cards(data.get("summary_cards", []))
            + render_sections_report(data.get("sections", []))
            + render_code_blocks(data.get("code_blocks", []))
            + render_reflection(data.get("reflection", ""))
            + render_references(data.get("references", []))
            + f'<footer>Generated {generated} — html-presentation skill</footer>'
        )
        body_class = "mode-report"
        nav = render_nav(data)

    return f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>{title}</title>
<style>{BASE_CSS}</style>
</head>
<body class="{body_class}" data-theme="dark">
{toolbar}
<div class="layout">
{nav}
<main><div class="container">{body_inner}</div></main>
</div>
<script>{BASE_JS}</script>
</body>
</html>
"""


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def main() -> None:
    p = argparse.ArgumentParser(description="Generate a self-contained HTML presentation.")
    src = p.add_mutually_exclusive_group(required=True)
    src.add_argument("--input", help="Structured JSON input file.")
    src.add_argument("--markdown", help="Markdown input file ('-' for stdin).")
    p.add_argument("--mode", choices=["report", "slides"], default="report")
    p.add_argument("--title", default=None)
    p.add_argument("--subtitle", default=None)
    p.add_argument("-o", "--output", default="presentation.html")
    args = p.parse_args()

    data = load_input(args)
    if args.subtitle:
        data["subtitle"] = args.subtitle

    html_out = render_html(data, args.mode)
    with open(args.output, "w", encoding="utf-8") as fh:
        fh.write(html_out)
    print(os.path.abspath(args.output))


if __name__ == "__main__":
    main()
