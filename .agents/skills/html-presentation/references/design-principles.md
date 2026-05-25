# HTML Presentation — Design Reference

A compact distillation of the working principles that consistently produce HTML presentations people read and remember. Sources are noted inline so you can dig deeper.

## 1. Information Design (the 80%)

### One message per document
Every presentation has exactly one takeaway. Everything else is evidence. Write the takeaway as a complete sentence on a sticky note before you touch HTML. Source: Nancy Duarte, *Resonate*; Chip & Dan Heath, *Made to Stick*.

### Inverted pyramid
Lead with the conclusion, then the supporting evidence, then the nuance. Readers leave at every paragraph break — make sure they leave with the answer first. Source: journalism convention, applied to docs by Jakob Nielsen.

### Miller's law (7 ± 2)
Working memory holds roughly seven items. Apply this to:
- Top-level sections: ≤ 7 (ideally 5)
- Summary cards: 3–5
- Bullet points in a list: ≤ 7
- Menu/nav items: ≤ 7

### Headers as messages
A header like "Auth Module" labels. A header like "Auth is now a deep module" communicates. Use complete-sentence headers where you can — they double as a skim path. Source: Edward Tufte, *Beautiful Evidence*; Andy Matuschak's working notes.

### Density without clutter
Tufte's "data-ink ratio": every pixel should carry information. But density requires whitespace to be legible. The rule is *signal* density, not *ink* density.

### Group, don't alternate
If you have three topics A, B, C with sub-items, present all of A, then all of B, then all of C. Never A1, B1, C1, A2, B2, C2 — that forces the reader to context-switch on every line.

### Progressive disclosure
Show the summary first; collapse the detail behind a click. Long diffs, raw logs, and verbose snippets belong inside collapsible regions. Source: Jakob Nielsen, *Usability Engineering*.

### Captions, not just labels
Every chart, code block, and image gets a caption explaining what to take from it. "Before/after" beats no caption. "Auth before refactor — note the leaked SQL" beats "Before". Source: Tufte's *Visual Display of Quantitative Information*.

## 2. Visual Design (the 20%)

### Typography
- Use **one** typeface for prose (system stack is fine: `-apple-system, "Segoe UI", Roboto, sans-serif`).
- Use **one** monospace typeface for code (`"SF Mono", Monaco, "Fira Code", monospace`).
- Body: 16–18 px, line-height 1.5–1.7, max line length 65–75 characters (≈ `max-width: 70ch`). Lines longer than 80 characters are hard to track. Source: Butterick's *Practical Typography*.
- Heading scale: a modular scale (e.g. 1.25× ratio) — h1 2.5 rem, h2 1.6 rem, h3 1.2 rem, body 1 rem.

### Color
- 1 background, 1 surface (slightly lighter/darker than background), 1 text, 1 secondary text, 1 accent, 1 warn. That's it.
- Maintain WCAG AA contrast: 4.5:1 for body text, 3:1 for large text. Verify in both themes.
- Use color to encode meaning (warn = warn, accent = action), not decoration.
- Both dark and light themes — many users have a preference, and code-heavy docs benefit from dark mode.

### Spacing & rhythm
- Pick an 8 px baseline grid. All margins, paddings, and gaps are multiples of 8 (or 4 for tight cases).
- Whitespace between sections >> whitespace within. The reader's eye groups by gap distance.

### Motion
- Use only for state changes: hover, expand/collapse, theme toggle.
- 150–250 ms is the sweet spot. >300 ms feels sluggish; <100 ms feels jarring.
- Never auto-animate on load. The reader hasn't asked for a performance.

### Iconography
- Emoji icons are fine when used consistently (one icon family). They render everywhere without external assets.
- Don't decorate every header with an icon — use icons to mark categories (📋 summary, 🚩 warning, 💻 code).

## 3. Structure — the canonical layout

For a **report** (default):

```
┌─────────────────────────────────────────────┐
│ Title                                       │
│ One-sentence takeaway                       │  <- first 100 px
│ Meta: project · date · author               │
├─────────────────────────────────────────────┤
│ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐         │
│ │ Card │ │ Card │ │ Card │ │ Card │  3–5    │  <- summary
│ └──────┘ └──────┘ └──────┘ └──────┘         │
├─────────────────────────────────────────────┤
│ ## Section 1 — Context                      │
│ Conclusion first, then evidence...          │
│ ## Section 2 — Analysis                     │
│ ## Section 3 — Recommendations              │
│ ## Section 4 — Reflection / Call to action  │
└─────────────────────────────────────────────┘
   [sidebar nav: section anchors, ≤ 7]
```

For **slides**:

```
Slide 1: Title + takeaway
Slide 2: Why this matters (the stakes)
Slides 3–N: One supporting point per slide
Final slide: The call to action (single sentence)
```

The slide rule: if it doesn't fit on the screen at 1280×720 without scrolling, it's two slides.

## 4. Code & technical content

- Every code block has a language label and a caption (the *intent*, not the syntax).
- Diff highlighting: green for additions, red for deletions, dim for context. WCAG-AA against the background.
- Long code blocks (>30 lines) collapse by default with an "Expand" affordance.
- Provide a copy-to-clipboard button — readers will run the code.
- Inline code uses a subtle background tint to distinguish from prose; never a different color.

## 5. Accessibility (non-negotiable)

- Semantic HTML: `<header>`, `<main>`, `<section>`, `<nav>`, `<footer>`.
- Headings nest correctly: one h1, then h2s, then h3s. Don't skip levels.
- All interactive elements (buttons, toggles) are keyboard-accessible and have visible focus states.
- Color is never the only signal — pair color with text or icon (e.g. "✓ Pass" not just green).
- `prefers-color-scheme` respected on first load; user toggle overrides and persists in `localStorage`.
- Mobile readable at 375 px width without horizontal scroll.

## 6. Self-contained constraint

- No external CDN, no remote fonts, no remote images. One file, opens offline.
- Inline CSS in `<style>`, inline JS in `<script>`. No external `<link>` or `<src>` references.
- Total file size budget: < 500 KB for a typical report. If you're over, you have too much content.

## 7. The shipping checklist

Before declaring done:

- [ ] Title and takeaway visible in the first viewport
- [ ] 3–5 summary cards (not 2, not 8)
- [ ] Sidebar nav has ≤ 7 entries
- [ ] Both light and dark themes legible (AA contrast)
- [ ] Mobile readable at 375 px
- [ ] No external network references
- [ ] Every code block has a caption
- [ ] No section exceeds one screen of prose without sub-structure
- [ ] Reflection / call-to-action present at the end

## Source list

- Edward Tufte — *The Visual Display of Quantitative Information*, *Beautiful Evidence*
- Garr Reynolds — *Presentation Zen*
- Nancy Duarte — *Resonate*, *Slide:ology*
- Robin Williams — *The Non-Designer's Design Book* (CRAP: Contrast, Repetition, Alignment, Proximity)
- Matthew Butterick — *Practical Typography* (practicaltypography.com)
- Jakob Nielsen — *Usability Engineering*; progressive disclosure
- Refactoring UI (Steve Schoger, Adam Wathan) — modern web UI heuristics
- WCAG 2.2 — accessibility baseline
