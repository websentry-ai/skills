# /ux-laws-review:targeting — Targeting Lens

I'm the targeting lens of `/ux-laws-review`. I audit one law — Fitts's Law — but it touches every interactive element on every page. How big is the target, how far is it from where the user's pointer (or thumb) already is, and is it placed somewhere the user can actually hit?

This is a one-law lens by design. Fitts is geometrically distinct from the other laws and earns its own surface so the score is never diluted by averages. No S-tier law lives here — but on touch and motor-accessibility surfaces, a Fitts failure is a *real* failure, not a polish issue.

## How to use me

I'm usually invoked by the parent `/ux-laws-review` when the target surface is a dashboard. You can call me directly:

```
/ux-laws-review:targeting https://app.example.com/dashboard
/ux-laws-review:targeting PLAN.md
/ux-laws-review:targeting pr=123
```

## Laws covered

1. **Fitts's Law** — The time to hit a target depends on its size and its distance from the starting point. Bigger and closer = faster and safer. The corners and edges of the screen have effectively infinite size (the pointer stops there).

## What I check

### Fitts's Law

| Check | Evidence to capture | Score impact |
|---|---|---|
| Minimum hit-target size: 44×44 pt (Apple HIG) / 48×48 dp (Material) / WCAG 2.5.5 target-size 24×24 CSS px floor | DOM bounding-box audit + screenshot | +2 if ≥ 44pt; +1 if 24–44px; −2 if < 24px |
| Padding lives on the interactive element, not on the parent — so the wrapper is the click target, not the bare SVG | DOM/CSS audit | +2 if wrapper is target; −2 if SVG is target |
| Destructive actions separated from primary actions by whitespace, or guarded by confirmation | screenshot of action row | +2 if separated/confirmed; −2 if Delete sits 8px from Save |
| Corner / edge placement for global actions (close, back, primary CTA on mobile) — Fitts edge advantage | screenshot of layout | +1 if exploited |
| Hit areas don't overlap (clicking near a button boundary doesn't accidentally hit a neighbor) | DOM overlay test | +1 if clean; −1 per overlap |
| Mobile / touch: thumb-reach zones respected on responsive layouts (primary actions in bottom-third or bottom corners, not top-right) | mobile screenshot + thumb-zone overlay | +1 if respected; −1 if primary action lives in the "stretch" zone |
| Misclick telemetry, if available: near-miss clicks within 8px of a target boundary that don't fire | telemetry audit | flag for follow-up if elevated |
| Drag handles, resize handles, scrollbars: visibly larger than the visual hint (handle is 8px wide; hit area is 16+) | hover/interaction test | +1 if expanded hit area |

## Scoring rubric

Each law gets scored on three axes:
- **Architect (0–3)** — does the component system encode min-size and padding-on-target as defaults? (Button base size, icon-button wrapper sizing, design-token spacing.)
- **Engineer (0–3)** — is the failure mode handled in code? (Hit-area utilities, expanded touch targets on mobile breakpoints, confirmation guards on destructive actions.)
- **Scout (0–4)** — does the product *feel* hittable? (Buttons feel like buttons; nothing feels fiddly on touch; destructive actions don't sit next to primary ones.)

With a single law in this lens, the **lens score equals the law score** — no averaging across laws. The output JSON shape is otherwise identical to the other lenses.

## Evidence I collect

For live audits I capture:
- DOM-driven hit-target sizing report: bounding-box dimensions of every interactive element on the audited surface
- Annotated screenshot calling out any target below the 24px WCAG floor
- Mobile breakpoint screenshot with thumb-reach zones overlaid (the bottom-third "easy" zone, the top-right "stretch" zone)
- Hit-area overlap test: hover/tap simulation along boundaries to catch overlapping targets
- Destructive-action proximity audit: distance from the nearest primary action

For plan reviews I extract:
- The proposed component sizing scale (button-sm / button-md / button-lg in px)
- The proposed mobile / responsive layout (where do primary actions live?)
- The proposed destructive-action treatment (confirmation? whitespace? both?)
- Any custom interactive element (drag handles, sliders, sparkline interactions) and its planned hit area

## Output I return to the parent

```
{
  "lens": "targeting",
  "score": 8,
  "verdict": "PASS",
  "laws": {
    "fitts_law": { "score": 8, "arch": 2, "eng": 3, "scout": 3, "evidence": "min target 44pt across audited surface; primary CTA bottom-right on mobile; one 12px close icon flagged", "notes": "Close icon in modal header is the only target below the floor" }
  },
  "s_tier_flags": [],
  "recommendations": [
    "Expand the modal close-icon hit area to 44pt by padding its wrapper, not the SVG (fitts_law)"
  ]
}
```

## Gating behavior

When invoked from `/build` Step 4:
- Lens average < 6 → **WARN** posted to PR
- Lens average < 4 → **FAIL**
- No S-tier laws live in this lens. `s_tier_flags` is always `[]`. **Naturally cannot FAIL on critical-flow surfaces via the S-tier path** — gating proceeds via lens-average only.

## Key principles

- **Pad the wrapper, not the icon.** The SVG is what the eye sees; the wrapper is what the finger hits.
- **Corners and edges are free real estate.** The pointer stops there with infinite effective size — exploit it for global actions.
- **Destructive actions deserve distance.** Delete should never sit 8px from Save.
- **Mobile is not desktop scaled down.** Thumb-reach zones are different geometry; honor them.

**Ready?** Give me a URL, plan, or PR, and I'll audit targeting.
