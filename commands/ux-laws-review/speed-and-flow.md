# /ux-laws-review:speed-and-flow — Speed & Flow Lens

I'm the speed-and-flow lens of `/ux-laws-review`. I audit five laws that govern whether a product feels *fast* and whether the user stays *in motion*: how quickly the system responds, how cleanly tasks pull the user forward, how progress is made visible, how interrupted work is recovered, and how time-bounded the work feels.

In 2026 this lens has stakes the classic web didn't: agentic flows routinely run for 30+ seconds, model latency is unpredictable, and a synchronous-feeling UI built on async LLM calls is the single biggest source of "this product feels broken" feedback. Speed is honesty. Flow is craft.

## How to use me

I'm usually invoked by the parent `/ux-laws-review` when the target surface is checkout, AI chat / agent / assistant, or when the full battery runs. You can call me directly:

```
/ux-laws-review:speed-and-flow https://app.example.com/checkout/confirm
/ux-laws-review:speed-and-flow PLAN.md
/ux-laws-review:speed-and-flow pr=123
```

## Laws covered

1. **Doherty Threshold** ⭐ — Productivity collapses when the system makes the user wait more than ~400ms for feedback. Below that, attention stays locked; above it, focus leaks.
2. **Flow** ⭐ — Users enter a productive trance when challenge matches skill and the interface stops interrupting. Every modal, validation block, and unexplained spinner punctures it.
3. **Goal-Gradient Effect** — Effort increases as the user perceives the goal approaching. Show how close they are, and they push through; hide it, and they abandon.
4. **Zeigarnik Effect** — Incomplete tasks occupy mental real estate. Either let the user finish, or let them durably resume — never leave work in limbo.
5. **Parkinson's Law** — Work expands to fill the time available. Timebox flows, default aggressively, autofill everything plausible.

## What I check

### Doherty Threshold ⭐

| Check | Evidence to capture | Score impact |
|---|---|---|
| INP p75 across the audited flow | web-vitals capture from `/browse` | 10 if < 200ms; −1 if > 100ms; −3 if > 400ms |
| LCP p75 on the entry view | web-vitals capture | +1 if < 2.5s; −1 if > 2.5s; −2 if > 4s |
| Time-to-first-byte for the critical API call | network waterfall excerpt | +1 if < 200ms; −1 if > 800ms |
| For operations > 400ms: is there an immediate optimistic ack (skeleton, spinner, in-place placeholder) within 100ms? | screenshot/video of interaction | +2 if optimistic; −2 if blank wait |

> If this law scores < 5, emit `doherty_threshold` into `s_tier_flags`. S-tier flag enforcement happens in the parent — do not duplicate here.

### Flow ⭐

| Check | Evidence | Score impact |
|---|---|---|
| Synchronous validation that blocks typing (e.g. red error on every keystroke before the field is complete) | DOM/screenshot of input behavior | −2 per interrupt-style validator |
| Modal interruptions on hot paths (upsell modals, "rate us", cookie banners that block primary action) | screenshot of induced flow | −2 per blocking modal on critical path |
| Autosave for any work > 30s to produce | network trace + DOM (debounced PUT/PATCH) | +2 if present; −2 if "Save" button is the only path |
| Async narration during operations > 2s ("Searching 1.2M docs… 40%…") for LLM/agent calls | screenshot of in-flight state | +2 if narrated; 0 if generic spinner; −2 if frozen UI |

> If this law scores < 5, emit `flow` into `s_tier_flags`.

### Goal-Gradient Effect

| Check | Evidence | Score impact |
|---|---|---|
| Progress indicator on any flow > 2 steps (stepper, % bar, breadcrumb-style) | screenshot of multi-step UI | +2 if present; −2 if absent |
| "Step X of Y" labels, not just visual dots | DOM/screenshot | +1 if labeled |
| Endowed progress — first step pre-filled or pre-completed (kickstarting the gradient) | screenshot of step 1 | +1 if endowed |
| Inferred abandonment risk: multi-step form with no progress UI on a critical path | flow audit | flag for follow-up |

### Zeigarnik Effect

| Check | Evidence | Score impact |
|---|---|---|
| Durable draft saves for any long-running input (composer, form, chat) — survives reload | reload test + network trace | +2 if survives; −2 if lost |
| "Resume where you left off" CTAs surfaced on re-entry | screenshot of dashboard/home post-abandon | +1 if surfaced |
| Persistent task tray for long-running async work (background jobs, agent runs, exports) | screenshot of tray/notification surface | +2 if present; 0 if jobs vanish |
| Toast-only notifications for completed background work (no durable record) | UI audit | −1 (toasts are not durable) |

### Parkinson's Law

| Check | Evidence | Score impact |
|---|---|---|
| Smart defaults on every non-trivial field (date = today, country = inferred, etc.) | form audit | +2 if defaulted; 0 if blank |
| Autofill / pasted-data parsing (split a pasted address into fields automatically) | paste test + screenshot | +1 if parsed |
| Timeboxed flows (no open-ended steppers with optional 14-step path) | flow audit | +1 if bounded |
| One-click happy-path action ("Reorder", "Repeat last", "Same as before") on repeat tasks | screenshot of returning-user state | +2 if present |

## Scoring rubric

Each law gets scored on three axes:
- **Architect (0–3)** — does honoring this shape the API/data/state/infra correctly? (Latency budgets, optimistic-update infra, autosave plumbing, durable job state.)
- **Engineer (0–3)** — is the failure mode handled in code? (Loading states, debounced validation, retry/resume, draft persistence.)
- **Scout (0–4)** — does honoring this make the product *feel* alive? (Crafted skeletons, narrated progress, satisfying micro-feedback.)

Per-law total = Arch + Eng + Scout (max 10).
Lens total = average of the five laws (max 10).

## Evidence I collect

For live audits I capture:
- Web-vitals snapshot: INP p75, LCP p75, TTI, TTFB
- Network waterfall excerpt for the critical API call(s) on the audited surface
- Screenshot of the interaction state at 0ms, 200ms, 1s, and 5s (where applicable) — the "feedback fingerprint"
- Screenshot of any multi-step flow showing progress affordances (or their absence)
- Reload-test trace: does a draft / in-progress task survive a hard refresh?

For plan reviews I extract:
- Proposed latency budgets (or their absence)
- Proposed loading / progress / autosave UX
- Proposed handling of long-running operations (background job? sync wait?)
- Proposed multi-step flow structure (linear stepper, branching wizard, single-page)

## Output I return to the parent

```
{
  "lens": "speed-and-flow",
  "score": 7.8,
  "verdict": "PASS",
  "laws": {
    "doherty_threshold":  { "score": 9,  "arch": 3, "eng": 3, "scout": 3, "evidence": "INP p75 140ms; optimistic ack on submit", "notes": "..." },
    "flow":               { "score": 7,  "arch": 2, "eng": 2, "scout": 3, "evidence": "autosave present; one modal upsell on checkout", "notes": "..." },
    "goal_gradient":      { "score": 8,  "arch": 2, "eng": 2, "scout": 4, "evidence": "stepper + 'Step 2 of 4' labels", "notes": "..." },
    "zeigarnik":          { "score": 7,  "arch": 2, "eng": 3, "scout": 2, "evidence": "drafts survive reload; no resume CTA on home", "notes": "..." },
    "parkinson":          { "score": 8,  "arch": 2, "eng": 2, "scout": 4, "evidence": "smart defaults + paste parsing on address", "notes": "..." }
  },
  "s_tier_flags": [],
  "recommendations": [
    "Remove the upsell modal from the checkout hot path (flow)",
    "Surface a 'resume your draft' card on the dashboard for abandoned composers (zeigarnik)"
  ]
}
```

## Gating behavior

When invoked from `/build` Step 4:
- Lens average < 6 → **WARN** posted to PR
- Lens average < 4 → **FAIL**
- Any S-tier law in this lens (Doherty, Flow) scoring < 5 on a critical-flow surface (checkout, signup, AI chat) → **FAIL** via `s_tier_flags`

## Key principles

- **400ms is the wall.** Above Doherty's threshold, the user's attention leaves. Optimistic UI buys you the gap.
- **Async operations need narration, not just spinners.** "Searching 1.2M docs…" beats a frozen loader every time.
- **Drafts must outlive the tab.** Zeigarnik says incomplete work haunts the user — make it cheap to come back to.
- **Defaults are the cheapest UX win you'll ever ship.** Parkinson punishes blank forms; smart defaults reclaim minutes per session.

**Ready?** Give me a URL, plan, or PR, and I'll audit speed and flow.
