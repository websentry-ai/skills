# /ux-laws-review:familiarity — Familiarity Lens

I'm the familiarity lens of `/ux-laws-review`. I audit two laws that govern whether the product *feels like itself and like its category*: does it behave the way the user already expects, and does its terminology match the mental model they brought with them.

In 2026 familiarity has paradoxical stakes. AI-native products are inventing new primitives (agents, threads, workspaces, runs, tools) — and many of them rename old primitives for no good reason. This lens enforces *don't reinvent unless reinvention buys something*. When you do reinvent, be honest that the user's mental model now has to bend.

## How to use me

I'm usually invoked by the parent `/ux-laws-review` when the target surface is onboarding or settings. You can call me directly:

```
/ux-laws-review:familiarity https://app.example.com/settings
/ux-laws-review:familiarity PLAN.md
/ux-laws-review:familiarity pr=123
```

## Laws covered

1. **Jakob's Law** — Users spend most of their time on *other* products. They expect yours to behave like the ones they already know. Convention is a feature.
2. **Mental Model** ⭐ — Users build a working theory of how the system behaves and rely on it to predict outcomes. Break the model and the product feels broken, even if the code is correct.

## What I check

### Jakob's Law

| Check | Evidence to capture | Score impact |
|---|---|---|
| Standard keyboard shortcuts respected (Cmd-K search, Cmd-S save, Esc closes modal/menu, Cmd-Enter submit) | keyboard test + DOM | +1 per shortcut honored; −1 per common shortcut hijacked |
| Native primitives over custom widgets where parity matters (date pickers, file uploads, selects on mobile) | DOM audit + screenshot | +2 if native; −1 if custom-without-reason |
| URL conventions: `/login`, `/signup`, `?page=2`, `?q=…`, standard `401` / `403` semantics on protected routes | URL + network audit | +1 if conventional; −1 per off-convention route |
| Category-standard behavior preserved (e.g. file manager has drag-to-reorder, chat has Enter-to-send, table has click-to-sort) | interaction test | +1 per matched expectation; −1 per surprise |
| Right-click / context menus where category norm expects them (file lists, table rows) | interaction test | +1 if present |

### Mental Model ⭐

| Check | Evidence | Score impact |
|---|---|---|
| Terminology matches category convention (don't rename "Workspaces" to "Pods" or "Folders" to "Vaults" without a reason) | label/copy audit | +1 if conventional; −2 if renamed-without-payoff |
| Inverted-verb audit: Save ≠ Apply; Cancel ≠ Discard; Delete ≠ Archive; Submit ≠ Schedule. Each verb does what its label says | copy + behavior test | −2 per inverted verb |
| URL preservation across redesigns / renames (301s, not 404s; old deep links keep working) | redirect test | +2 if preserved; −2 if links rot |
| Tree-test on the IA: a fresh user given the goal "change my notification preferences" finds it in ≤ 2 clicks | first-time-user test | +2 if found; −2 if lost |
| Reversible vs. destructive actions are visually distinguishable (red destructive, undo on reversible) | screenshot + interaction test | +1 if distinguished; −1 if flat |
| Agent / AI surfaces honestly describe the agent's capabilities (the user's mental model of "what this can do" is correct) | capability surface screenshot | +2 if accurate; −2 if magic-box |

> *Related law: Tesler's Law in [`trust-and-honesty`](./trust-and-honesty.md) — irreducible complexity must live somewhere; pretending the agent's complexity is gone breaks the user's mental model fastest.*

> If this law scores < 5, emit `mental_model` into `s_tier_flags`. S-tier flag enforcement happens in the parent — do not duplicate here.

## Scoring rubric

Each law gets scored on three axes:
- **Architect (0–3)** — does honoring this shape routes, URLs, IA, terminology choices in the data model? (Stable URLs, conventional resource naming, redirects for renames.)
- **Engineer (0–3)** — is the failure mode handled in code? (Keyboard handlers wired, native-element fallbacks, 301s in router config.)
- **Scout (0–4)** — does honoring this make the product *feel inevitable*? (Like the user has always used it, even on day one.)

Per-law total = Arch + Eng + Scout (max 10).
Lens total = average of the two laws (max 10).

## Evidence I collect

For live audits I capture:
- Keyboard-shortcut audit: trace which of {Cmd-K, Cmd-S, Esc, Cmd-Enter, /} fire what
- Screenshot of any custom widget that replaces a native one (with a note: "what does the custom buy?")
- URL audit: every route on the audited surface, plus 1–2 inferred old paths to test for redirects
- Copy audit: every named noun (Workspace, Project, Run, Thread, Tool…) checked against the closest category competitor
- A "tree-test" sketch: pick 2 reasonable user goals and trace how many clicks each takes

For plan reviews I extract:
- The proposed terminology (and the convention it competes with)
- The proposed URL / routing scheme
- The proposed keyboard / interaction model
- Any rename that's likely to break old URLs or muscle memory

## Output I return to the parent

```
{
  "lens": "familiarity",
  "score": 7.5,
  "verdict": "PASS",
  "laws": {
    "jakobs_law":   { "score": 8, "arch": 2, "eng": 3, "scout": 3, "evidence": "Cmd-K / Esc / Cmd-Enter all wired; native date picker on mobile", "notes": "..." },
    "mental_model": { "score": 7, "arch": 2, "eng": 2, "scout": 3, "evidence": "renamed 'Projects' → 'Workspaces'; old URLs 301", "notes": "..." }
  },
  "s_tier_flags": [],
  "recommendations": [
    "Honor Cmd-S in the document editor (jakobs_law)",
    "Drop the 'Vault' rename — 'Folder' matches the category and the icon (mental_model)"
  ]
}
```

## Gating behavior

When invoked from `/build` Step 4:
- Lens average < 6 → **WARN** posted to PR
- Lens average < 4 → **FAIL**
- Any S-tier law in this lens (Mental Model) scoring < 5 on a critical-flow surface (signup, AI chat, agent UI) → **FAIL** via `s_tier_flags`

## Key principles

- **Convention is a feature.** Match the category until you have a real reason to break it.
- **Renaming has a tax.** Every product noun you invent must be worth more than the muscle memory you're asking the user to overwrite.
- **Old URLs are infrastructure.** Redirects are how you respect everyone who already bookmarked you.
- **The mental model is the product.** When the system behaves like the user predicted, the product feels finished.

**Ready?** Give me a URL, plan, or PR, and I'll audit familiarity.
