# /ux-laws-review:gestalt-visual — Gestalt & Visual Lens

I'm the gestalt-visual lens of `/ux-laws-review`. I audit five Gestalt laws that govern how the eye *groups* what it sees: which elements belong together, which are merely adjacent, and which read as a single shape vs. a pile of parts. This is the lens of *visual structure*.

In 2026 this lens fights the most common form of AI-slop UI: every section gets a card, every card gets a border, every border gets a shadow, every shadow gets a gradient — and the page reads as noise. Gestalt is how you compose; this lens enforces composition over decoration.

No S-tier laws sit in this lens by design. Visual grouping is taste-rich and rarely a critical-flow blocker on its own — but a low score here usually correlates with bad scores in cognition and attention.

## How to use me

I'm usually invoked by the parent `/ux-laws-review` when the target surface is a dashboard. You can call me directly:

```
/ux-laws-review:gestalt-visual https://app.example.com/dashboard
/ux-laws-review:gestalt-visual PLAN.md
/ux-laws-review:gestalt-visual pr=123
```

## Laws covered

1. **Law of Common Region** — Elements enclosed by a shared boundary (border, background, container) are perceived as a group. Use containers to *mean* grouping; don't draw boxes for decoration.
2. **Law of Proximity** — Elements close together are perceived as related; elements with whitespace between them are perceived as separate. Distance is the cheapest grouping primitive.
3. **Law of Similarity** — Elements that share visual treatment (color, shape, size, weight) are perceived as the same kind. Encode kind consistently across the product.
4. **Law of Uniform Connectedness** — Elements visibly linked (lines, shared container, connecting graphic) read as one unit. Strong cue for tree / timeline / pipeline UIs.
5. **Law of Prägnanz** — The eye prefers the simplest interpretation of a complex scene. Reduce visual complexity until the meaning is the first thing the eye reaches.

## What I check

### Law of Common Region

| Check | Evidence to capture | Score impact |
|---|---|---|
| Semantic containers (`<section>`, `<article>`, `<aside>`) used where grouping is real | DOM audit | +1 if semantic; 0 if all `<div>` |
| Visual containers (border / background / rounded corners) reserved for *grouped* content, not used as decoration | screenshot + DOM audit | +2 if disciplined; −2 if every section is a card |
| Surface-level tokens (level-0 page, level-1 panel, level-2 card) used consistently across the product | design-token / CSS audit | +1 if tokenized; −1 if ad-hoc |
| No "double containment" (a card inside a card inside a card with no informational reason) | screenshot review | −1 per gratuitous nesting |

### Law of Proximity

| Check | Evidence | Score impact |
|---|---|---|
| Label-input pairs wrapped in a single container with consistent `gap` (label is visibly closer to its own input than to the next field's label) | DOM excerpt + screenshot | +2 if tight; −2 if orphan labels |
| Consistent spacing scale (4/8/12/16/24/32) via design tokens — no `margin: 13px` or `padding: 7px` ad-hoc | CSS audit | +2 if tokenized; −1 per ad-hoc value |
| Related items have less whitespace between them than between groups (group-vs-group > item-vs-item) | screenshot + spacing audit | +1 if hierarchical; −1 if flat spacing |
| Group separators (dividers) used only where proximity already fails to do the job | screenshot review | +1 if minimal; −1 if over-dividered |

### Law of Similarity

| Check | Evidence | Score impact |
|---|---|---|
| Buttons of the same kind look the same across pages (primary, secondary, destructive) | screenshot comparison across pages | +2 if consistent; −2 per drift |
| State encoded by more than color (shape + icon + weight, not just brand-blue) — also an a11y win | screenshot + a11y audit | +1 if multi-channel; −1 if color-only |
| Shared CSS variables / tokens across surfaces (color, type, spacing, radius) | CSS audit | +1 if tokenized |
| Icons in the same family / weight / fill style throughout (no Lucide + Material + emoji mash-up) | screenshot review | +1 if consistent |

### Law of Uniform Connectedness

| Check | Evidence | Score impact |
|---|---|---|
| Related items share a container *or* a connecting line (tree, timeline, pipeline) — not just spatial proximity | screenshot review | +2 if connected; −1 if relied solely on proximity |
| Step indicators visibly connect (line through the stepper, not just disconnected dots) | screenshot of stepper | +1 if connected |
| Tag / chip groups read as one unit (consistent treatment + spatial cluster) | screenshot of chip group | +1 if cohesive |

### Law of Prägnanz

| Check | Evidence | Score impact |
|---|---|---|
| SVG path-count budget per icon (icons simplified via SVGO; no 200-node decorative SVGs) | SVG audit | +1 if minimal; −1 per overweight icon |
| Single-color glyphs in icon sets (no 3-color illustrations dressed up as icons) | screenshot review | +1 if disciplined |
| Avoid 3D / skeuomorphism in data viz (flat bars / lines beat gradient bars / animated 3D pies) | screenshot review | −1 per 3D viz |
| `prefers-reduced-motion` honored on entrance / hover animations | CSS / motion audit | +1 if honored; −1 if ignored |
| Page screenshot, squinted: does the macro-shape read clearly? (Header / nav / content / footer recognizable in 1 second) | scout judgment | 0–3 |

## Scoring rubric

Each law gets scored on three axes:
- **Architect (0–3)** — does the design system / token set express grouping correctly? (Surface levels, spacing scale, semantic container conventions.)
- **Engineer (0–3)** — is the failure mode handled in code? (Tokens enforced, no ad-hoc margins, semantic HTML, motion-reduction wired.)
- **Scout (0–4)** — does the screen *compose*? (Macro-shape readable; visual hierarchy intentional; nothing decorative survives the squint test.)

Per-law total = Arch + Eng + Scout (max 10).
Lens total = average of the five laws (max 10).

This lens is taste-rich; the scout weight does most of the work. Engineering and architecture set the *floor* (tokens, semantics), but Gestalt failures are almost always taste failures.

## Evidence I collect

For live audits I capture:
- Full-page screenshot of the audited surface, plus an annotated overlay calling out grouping boundaries
- Spacing audit: every margin/padding value used on the page (looking for ad-hoc values outside the scale)
- Button / chip / icon inventory: screenshots of the same component across 3+ pages to check Similarity
- "Squint test" screenshot: does the macro composition survive losing detail?
- Motion audit: any entrance / hover animation, plus `prefers-reduced-motion` behavior

For plan reviews I extract:
- The proposed component / surface system (and whether grouping is expressed in tokens)
- The proposed spacing scale
- The proposed iconography family and weight
- The proposed motion treatment

## Output I return to the parent

```
{
  "lens": "gestalt-visual",
  "score": 7.6,
  "verdict": "PASS",
  "laws": {
    "common_region":         { "score": 7, "arch": 2, "eng": 2, "scout": 3, "evidence": "two-level surface tokens used; one gratuitous card-in-card on the dashboard", "notes": "..." },
    "proximity":             { "score": 8, "arch": 2, "eng": 3, "scout": 3, "evidence": "label-input gaps consistent; spacing scale honored", "notes": "..." },
    "similarity":            { "score": 8, "arch": 2, "eng": 3, "scout": 3, "evidence": "primary button consistent across 5 audited pages", "notes": "..." },
    "uniform_connectedness": { "score": 7, "arch": 2, "eng": 2, "scout": 3, "evidence": "stepper has connecting line; pipeline UI uses shared container", "notes": "..." },
    "pragnanz":              { "score": 8, "arch": 2, "eng": 2, "scout": 4, "evidence": "icons single-color, motion-reduction honored, squint test passes", "notes": "..." }
  },
  "s_tier_flags": [],
  "recommendations": [
    "Remove the inner card on the dashboard widget — proximity already groups it (common_region)",
    "Unify the icon set: replace the 3 Material outliers with Lucide equivalents (similarity)"
  ]
}
```

## Gating behavior

When invoked from `/build` Step 4:
- Lens average < 6 → **WARN** posted to PR
- Lens average < 4 → **FAIL**
- No S-tier laws live in this lens. `s_tier_flags` is always `[]`. **Naturally cannot FAIL on critical-flow surfaces via the S-tier path** — gating proceeds via lens-average only.

## Key principles

- **Containers must mean grouping.** A card around every section is decoration, not structure.
- **Proximity is the cheapest grouping primitive.** Use whitespace first, dividers second, borders last.
- **Similarity is a contract.** A primary button must look like a primary button across every page.
- **Squint at the screen.** If the macro-composition doesn't survive losing detail, the hierarchy isn't doing its job.

**Ready?** Give me a URL, plan, or PR, and I'll audit composition.
