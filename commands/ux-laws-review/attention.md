# /ux-laws-review:attention — Attention Lens

I'm the attention lens of `/ux-laws-review`. I audit three laws that govern what the user *actually sees* and *actually does* once they're past the front door: where their eyes go on a busy screen, what stands out (and what *should*), and what happens when they ignore the documentation and start clicking.

In 2026 this lens has unusually high leverage on onboarding and AI products. Users skip tutorials. They ignore tooltips. They tab in from another product and expect to be productive in 30 seconds. The Paradox of the Active User is no longer a curiosity — it's the default. This lens audits the product as if no one will ever read the docs.

## How to use me

I'm usually invoked by the parent `/ux-laws-review` when the target surface is onboarding (signup, welcome, first-run). You can call me directly:

```
/ux-laws-review:attention https://app.example.com/signup
/ux-laws-review:attention PLAN.md
/ux-laws-review:attention pr=123
```

This lens is unusually plan-doc-friendly. A lot of Paradox-of-the-Active-User design lives in onboarding strategy, empty states, and tooltip choices — often easier to audit in a plan than on a half-built page.

## Laws covered

1. **Selective Attention** — Users filter out anything that looks like noise (ads, banners, decoration), even when it's not. Banner-blindness is universal.
2. **Von Restorff Effect** — An item that visibly differs from its neighbors is remembered. Use distinctiveness to mark the *one* thing that matters; abuse it and nothing stands out.
3. **Paradox of the Active User** ⭐ — Users learn by doing, not by reading. They will ignore the manual, skip the tutorial, and start clicking. Design for the click-first user.

## What I check

### Selective Attention

| Check | Evidence to capture | Score impact |
|---|---|---|
| Critical alerts (errors, warnings) visually distinct from marketing banners and ads | screenshot of error + banner side-by-side | +2 if distinct; −2 if both look the same |
| Content that's *not* an ad but is styled like one (rounded card, colored bg, dismissable X) | screenshot of content blocks | −1 per ad-styled content unit |
| `aria-live` regions for dynamic updates (`polite` for non-urgent, `assertive` for blocking errors) | DOM audit of live regions | +2 if correctly typed; 0 if absent |
| Highlight-then-fade for async row / cell updates (so the user sees what changed) | interaction test + screenshot | +1 if present |
| Color / motion discipline: no autoplaying video, no animated badges on hot paths | screenshot/video | −1 per attention-grabber on critical path |

### Von Restorff Effect

| Check | Evidence | Score impact |
|---|---|---|
| Maximum one primary CTA per view (one visually-distinct button) | screenshot + CTA count | +2 if one; −1 if two; −2 if 3+ |
| Distinctiveness uses more than color alone (icon + shape + weight, not just brand-blue) | screenshot + a11y audit | +1 if multi-channel; −1 if color-only |
| Distinctive element is the *right* thing (primary action, not a marketing pill) | screenshot + intent audit | +1 if aligned; −2 if misused (e.g. "Upgrade" out-shouts "Save") |
| `prefers-reduced-motion` honored on animated highlights | CSS audit + motion test | +1 if honored; −1 if ignored |

### Paradox of the Active User ⭐

| Check | Evidence | Score impact |
|---|---|---|
| Empty states have a clear, single CTA ("Create your first…") and not just placeholder text | screenshot of empty state | +2 if actionable; −2 if dead |
| First-run / first-empty-state works without any tutorial dismissal (the user can act immediately) | first-run test + screenshot | +2 if "just works"; −2 if blocked by tutorial modal |
| Tooltips / inline help present at the point of confusion (not buried in docs) | screenshot of complex control | +1 if inline help present |
| Recoverable mistakes: undo / "did you mean…?" / clear error → fix path | error test + screenshot | +2 if recoverable; −2 if dead-end |
| Pre-filled sensible content on first use (sample data, starter template) | first-run screenshot | +1 if present |
| Surface a "what is this?" affordance on novel controls (especially AI knobs the user hasn't seen elsewhere) | screenshot of novel UI | +1 if explained inline |

> If this law scores < 5, emit `paradox_of_the_active_user` into `s_tier_flags`. S-tier flag enforcement happens in the parent — do not duplicate here.

## Scoring rubric

Each law gets scored on three axes:
- **Architect (0–3)** — does honoring this shape the surface correctly? (Empty-state pages, error-recovery routes, accessibility primitives in the design system.)
- **Engineer (0–3)** — is the failure mode handled in code? (`aria-live` wired, recoverable error states, sample-data seeding.)
- **Scout (0–4)** — does honoring this make the product *land*? (One clear thing to do next; the right thing wearing the loud shirt.)

Per-law total = Arch + Eng + Scout (max 10).
Lens total = average of the three laws (max 10).

## Evidence I collect

For live audits I capture:
- Annotated screenshot showing competing visual weights on a single screen (the "heat-map" of where the eye should go)
- Screenshot of every empty state on the audited surface
- Screenshot of an induced error state (recovery path or dead-end?)
- First-run trace: log in as a fresh user, screenshot the first 30 seconds
- `aria-live` and motion-reduction audit excerpts

For plan reviews I extract:
- The proposed onboarding / first-run flow
- The proposed empty-state designs (these are usually under-specified — flag if so)
- The proposed tooltip / inline-help strategy
- The proposed error-recovery routes
- The proposed primary-CTA hierarchy per view

## Output I return to the parent

```
{
  "lens": "attention",
  "score": 7.3,
  "verdict": "PASS",
  "laws": {
    "selective_attention":  { "score": 8, "arch": 2, "eng": 3, "scout": 3, "evidence": "errors are red + icon; aria-live=assertive correct", "notes": "..." },
    "von_restorff":         { "score": 7, "arch": 2, "eng": 2, "scout": 3, "evidence": "one primary CTA per view; reduced-motion honored", "notes": "..." },
    "paradox_of_the_active_user":  { "score": 7, "arch": 2, "eng": 2, "scout": 3, "evidence": "empty states have CTAs; tutorial is dismissible and non-blocking", "notes": "..." }
  },
  "s_tier_flags": [],
  "recommendations": [
    "Style the in-product changelog so it doesn't read like a banner ad (selective_attention)",
    "Seed first-run users with a sample project so the dashboard isn't empty (paradox_of_the_active_user)"
  ]
}
```

## Gating behavior

When invoked from `/build` Step 4:
- Lens average < 6 → **WARN** posted to PR
- Lens average < 4 → **FAIL**
- Any S-tier law in this lens (Paradox of the Active User) scoring < 5 on a critical-flow surface (signup, onboarding, AI chat first-run) → **FAIL** via `s_tier_flags`

## Key principles

- **Banner-blindness is universal.** If your real content looks like an ad, it gets filtered.
- **The loud shirt goes on the one thing that matters.** Two primary CTAs = zero primary CTAs.
- **The user will not read the manual.** Build the product as if they're click-first, doc-never.
- **Empty states are onboarding.** They are not a placeholder — they are the most important screen in the product on day one.

**Ready?** Give me a URL, plan, or PR, and I'll audit attention.
