#!/usr/bin/env python3
"""HTML post-processor for the visual-plan/visual-recap skills.

Wraps html-presentation/scripts/generate-presentation.py: runs the base
generator to produce the report/slide HTML, then splices in one inline
<style>/<script> block that adds two purely-visual behaviors on top of the
base output:

  - diff coloring for fenced ```diff code blocks (+/- lines)
  - a tabset for consecutive "keychange-*" sections

Output remains fully self-contained: no network calls, no CDN references,
only inline <style>/<script>.
"""

from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path

INJECTED_STYLE = """
<style>
.diff-add { color: var(--accent-2); }
.diff-del { color: var(--warn); }
.diff-ctx { color: var(--text-secondary); }

.tabset { margin: 1rem 0; }
.tab-btns { display: flex; gap: 0.5rem; flex-wrap: wrap; margin-bottom: 0.75rem; }
.tab-btn {
  background: none; cursor: pointer; border: 1px solid var(--border);
  border-radius: 6px; padding: 0.4rem 0.9rem; color: var(--text-secondary);
  font-size: 0.9rem;
}
.tab-btn.active { color: var(--accent); border-color: var(--accent); }
.tab-panel { display: none; }
.tab-panel.active { display: block; }
</style>
""".strip()

INJECTED_SCRIPT = """
<script>
document.addEventListener('DOMContentLoaded', function () {
  colorDiffBlocks();
  buildKeychangeTabs();
});

function colorDiffBlocks() {
  document.querySelectorAll('pre code.lang-diff').forEach(function (block) {
    var lines = block.textContent.split('\\n');
    block.textContent = '';
    lines.forEach(function (line, i) {
      var span = document.createElement('span');
      if (line.startsWith('+')) {
        span.className = 'diff-add';
      } else if (line.startsWith('-')) {
        span.className = 'diff-del';
      } else {
        span.className = 'diff-ctx';
      }
      span.textContent = line;
      block.appendChild(span);
      if (i < lines.length - 1) {
        block.appendChild(document.createTextNode('\\n'));
      }
    });
  });
}

function buildKeychangeTabs() {
  var sections = Array.from(document.querySelectorAll('main section[id]'));
  var i = 0;
  while (i < sections.length) {
    if (!sections[i].id.startsWith('keychange-')) {
      i += 1;
      continue;
    }
    var group = [];
    while (i < sections.length && sections[i].id.startsWith('keychange-')) {
      group.push(sections[i]);
      i += 1;
    }
    wrapGroupInTabset(group);
  }
}

function wrapGroupInTabset(group) {
  var tabset = document.createElement('div');
  tabset.className = 'tabset';
  var tabBtns = document.createElement('div');
  tabBtns.className = 'tab-btns';
  tabset.appendChild(tabBtns);

  group[0].parentNode.insertBefore(tabset, group[0]);

  group.forEach(function (section, idx) {
    var heading = section.querySelector('h2');
    var label = heading ? heading.textContent.trim() : section.id;

    var btn = document.createElement('button');
    btn.type = 'button';
    btn.className = 'tab-btn' + (idx === 0 ? ' active' : '');
    btn.textContent = label;
    tabBtns.appendChild(btn);

    section.classList.add('tab-panel');
    if (idx === 0) {
      section.classList.add('active');
    }
    tabset.appendChild(section);

    btn.addEventListener('click', function () {
      tabBtns.querySelectorAll('.tab-btn').forEach(function (b) {
        b.classList.remove('active');
      });
      tabset.querySelectorAll('.tab-panel').forEach(function (p) {
        p.classList.remove('active');
      });
      btn.classList.add('active');
      section.classList.add('active');
    });
  });
}
</script>
""".strip()


def find_generator() -> Path:
    """Locate generate-presentation.py relative to this script's skills tree."""
    skills_dir = Path(__file__).resolve().parents[2]
    generator = skills_dir / "html-presentation" / "scripts" / "generate-presentation.py"
    if not generator.is_file():
        raise FileNotFoundError(
            f"generate-presentation.py not found at expected path: {generator}"
        )
    return generator


def run_generator(
    generator: Path, model_path: str, mode: str, out_path: Path,
    title: str | None, subtitle: str | None,
) -> None:
    cmd = [sys.executable, str(generator), "--input", model_path, "--mode", mode, "-o", str(out_path)]
    if title:
        cmd += ["--title", title]
    if subtitle:
        cmd += ["--subtitle", subtitle]
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        raise RuntimeError(
            f"generate-presentation.py failed (exit {result.returncode}):\n"
            f"stdout: {result.stdout}\nstderr: {result.stderr}"
        )


def splice_injected_block(html: str) -> str:
    marker = "</head>"
    if marker not in html:
        raise ValueError("base generator output has no </head> tag to splice into")
    injected = f"{INJECTED_STYLE}\n{INJECTED_SCRIPT}\n"
    return html.replace(marker, injected + marker, 1)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", required=True, help="Structured JSON input file.")
    parser.add_argument("-o", "--output", required=True, help="Output HTML path.")
    parser.add_argument("--mode", default="report", choices=["report", "slides"])
    parser.add_argument("--title", default=None)
    parser.add_argument("--subtitle", default=None)
    args = parser.parse_args()

    generator = find_generator()
    output_path = Path(args.output).resolve()
    tmp_html = output_path.with_suffix(output_path.suffix + ".base.tmp")

    run_generator(generator, args.input, args.mode, tmp_html, args.title, args.subtitle)

    base_html = tmp_html.read_text(encoding="utf-8")
    tmp_html.unlink()

    final_html = splice_injected_block(base_html)
    output_path.write_text(final_html, encoding="utf-8")
    print(str(output_path))


if __name__ == "__main__":
    main()
