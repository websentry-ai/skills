# /ux-laws-review:decision-architecture — Decision Architecture Lens

I'm the decision-architecture lens of `/ux-laws-review`. I audit four laws that shape how the product *frames choices*: how many options it presents, how it routes the user toward a sensible default, what irreducible knobs it actually exposes, and which 20% of the surface earns 80% of the polish.

In 2026, "configurability" has become a tax. AI-native products ship with dozens of model knobs, dozens of prompt knobs, dozens of integration toggles — and the user is asked to pick. This lens enforces that *choices are a product decision, not a feature dump*.

## How to use me

I'm usually invoked by the parent `/ux-laws-review` when the target surface is checkout, settings, or when the full battery runs. You can call me directly:

```
/ux-laws-review:decision-architecture https://app.example.com/checkout/payment
/ux-laws-review:decision-architecture PLAN.md
/ux-laws-review:decision-architecture pr=123
```

## Laws covered

1. **Choice Overload** ⭐ — Past a small number of options, the user's odds of choosing *anything* drop. More choice often means less conversion.
2. **Hick's Law** — Decision time grows roughly logarithmically with the number of choices. Cluster, group, and hide what the user doesn't need right now.
3. **Occam's Razor** ⭐ — The best feature is one the user never has to see. Strip every knob that doesn't earn its weight; defaults are the load-bearing UX.
4. **Pareto Principle** — Roughly 80% of usage flows through 20% of the surface. Spend 80% of the polish budget on that 20%.

## What I check

### Choice Overload ⭐

| Check | Evidence to capture | Score impact |
|---|---|---|
| Visible option count at any single decision point (payment methods, plan tiers, model picker, export format, etc.) | screenshot + count | +1 if ≤ 4; −2 if ≥ 7; −3 if ≥ 12 |
| Smart-default present and pre-selected (one option highlighted as "recommended") | screenshot of decision UI | +2 if present; −2 if all options shown neutrally |
| Search / filter on any list > 10 selectable items | DOM/screenshot of long list | +1 if searchable |
| Virtualized rendering for selectable lists > 50 items | scroll test + DOM audit | +1 if virtualized |
| Progressive disclosure: "Show more options" link instead of dumping all upfront | screenshot of collapsed state | +1 if disclosed; 0 if all visible |

> *Related law: Tesler's Law in [`trust-and-honesty`](./trust-and-honesty.md) — irreducible complexity must live somewhere; smart defaults are where it lives architecturally.*

> If this law scores < 5, emit `choice_overload` into `s_tier_flags`. S-tier flag enforcement happens in the parent — do not duplicate here.

### Hick's Law

| Check | Evidence | Score impact |
|---|---|---|
| Top-level nav item count (sidebar, header) | screenshot + count | +1 if ≤ 6; −1 if 7–10; −2 if > 10 |
| Grouped nav (sections, dividers) over a flat list | screenshot of nav structure | +1 if grouped |
| Command palette (Cmd-K) for power-users to bypass nav | keyboard test + screenshot | +2 if present; 0 if absent |
| Settings / preferences: search box at the top of a long settings tree | screenshot of settings entry | +1 if searchable |

### Occam's Razor ⭐

| Check | Evidence | Score impact |
|---|---|---|
| Configurable knobs with < 1% telemetry usage that are still front-and-center | telemetry audit + screenshot | −1 per useless front-page knob |
| Settings tabs / sections that exist for one or two power-users | settings audit | −1 per long-tail tab |
| Advanced settings: hidden behind "Advanced" disclosure rather than mixed with common ones | screenshot of disclosure | +2 if disclosed; −1 if mixed |
| Prop / API surface: the public component / endpoint takes ≤ 4 required args and doesn't expose internal state | code/API audit | +1 if minimal; −1 if 8+ args |
| Removal test: "what disappears with no harm?" — anything found | removal audit / scout judgment | −1 per "could remove" item |

> If this law scores < 5, emit `occams_razor` into `s_tier_flags`.

### Pareto Principle

| Check | Evidence | Score impact |
|---|---|---|
| Per-feature DAU/MAU available (telemetry exists at all) | analytics check | +1 if exists |
| Eng-hours-per-feature vs. usage scatter (if measurable from PR/commit history) | repo audit | +1 if top-20% features got top-80% of recent commits |
| The product's "headline" feature is visibly its most-used (not buried) | screenshot + telemetry | +2 if aligned; −2 if vanity-feature dominates UI |
| Long-tail features hidden behind clear disclosure (not equal-weighted with core) | UI hierarchy audit | +1 if hierarchical |

## Scoring rubric

Each law gets scored on three axes:
- **Architect (0–3)** — does the product's API / data model / config surface reflect a real decision about what to expose vs. abstract? (Sensible defaults baked into the schema; minimal required config.)
- **Engineer (0–3)** — is the failure mode handled in code? (Smart defaults, debounced searches on long lists, telemetry-driven knob culling.)
- **Scout (0–4)** — does the product feel *opinionated and considered*? (Not a config dump; not a feature museum.)

Per-law total = Arch + Eng + Scout (max 10).
Lens total = average of the four laws (max 10).

## Evidence I collect

For live audits I capture:
- Screenshot of every multi-option decision point on the audited surface
- Annotated count of selectable items at each
- Nav screenshot + top-level item count
- Settings tree depth + section count
- Removal-audit notes ("if this widget vanished, would any user notice?")

For plan reviews I extract:
- The proposed configuration / options surface
- The proposed nav and IA
- The proposed default behavior (or absence)
- The proposed scope-vs-polish split (which features get how much love)

## Output I return to the parent

```
{
  "lens": "decision-architecture",
  "score": 6.5,
  "verdict": "WARN",
  "laws": {
    "choice_overload":  { "score": 5,  "arch": 2, "eng": 1, "scout": 2, "evidence": "9 payment methods, no recommended default", "notes": "..." },
    "hicks_law":        { "score": 7,  "arch": 2, "eng": 2, "scout": 3, "evidence": "8 nav items, ungrouped", "notes": "..." },
    "occams_razor":     { "score": 6,  "arch": 2, "eng": 2, "scout": 2, "evidence": "3 settings tabs each < 1% DAU usage", "notes": "..." },
    "pareto":           { "score": 8,  "arch": 3, "eng": 2, "scout": 3, "evidence": "headline feature is top-clicked and front-and-center", "notes": "..." }
  },
  "s_tier_flags": ["choice_overload"],
  "recommendations": [
    "Add a 'Recommended' badge + pre-selection to one payment method (choice_overload)",
    "Move 3 long-tail settings tabs behind an 'Advanced' disclosure (occams_razor)"
  ]
}
```

## Gating behavior

When invoked from `/build` Step 4:
- Lens average < 6 → **WARN** posted to PR
- Lens average < 4 → **FAIL**
- Any S-tier law in this lens (Choice Overload, Occam's Razor) scoring < 5 on a critical-flow surface (checkout, signup, AI chat) → **FAIL** via `s_tier_flags`

## Key principles

- **Defaults are the product.** Every option without a default is a tax the user pays. Choose for them, let them override.
- **Configurability is a debt.** Knobs nobody touches still appear in screenshots, docs, and bug reports.
- **Hick's growth is logarithmic — but it still grows.** Grouping is cheap; flat 12-item menus are not.
- **Polish the 20% that matters.** A perfect checkout beats a polished settings page every time.

**Ready?** Give me a URL, plan, or PR, and I'll audit the choice architecture.
