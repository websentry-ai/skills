# skills

A growing library of [Claude Code](https://docs.anthropic.com/en/docs/claude-code) skills and specialized agents for shipping production software with an AI-assisted dev loop. One install, one `~/.claude/` directory, every skill available as a slash command.

Built for teams that treat their AI workflows as real engineering — where specs get multi-lens reviewed before code is written, and every ticket goes through a plan → build → test → review → ship pipeline.

---

## Skills

| Command | What it does |
|---|---|
| [`/council`](#council--multi-lens-spec-review) | Multi-lens spec review — product, CISO, eng leader, architect, and PR reviewer critique a spec in parallel. Run this **before** you write code. |
| [`/build`](#build--full-development-pipeline) | Full dev pipeline — plan, code, simplify, test, review, raise PR, validate. The default "how we ship a feature." |

Chain them: `/council` the spec → fix the issues → `/build` the feature.

---

## Install — 30 seconds

Open Claude Code and paste this. Claude does the rest.

> Install the skills repo: run **`git clone --depth 1 https://github.com/websentry-ai/skills.git /tmp/skills && /tmp/skills/install.sh --force && rm -rf /tmp/skills`** — this installs all commands (`/build`, `/council`) and all agents (principal-architect, principal-engineer, elite-pr-reviewer, code-simplifier, principal-engineer-review, product-vision-scout, ciso-evaluator, eng-leader-evaluator) into `~/.claude/`. Then verify by confirming `/build` and `/council` are available as slash commands.

That's it. No manual terminal steps.

### Alternative: manual install

```bash
git clone https://github.com/websentry-ai/skills.git
cd skills
./install.sh
```

The installer globs `agents/*.md` and `commands/*.md` — any skill added to this repo will be installed automatically.

### Team install — vendor into your project

Want teammates to get the skills automatically when they open Claude Code in your project?

```bash
# From your project root
mkdir -p .claude/commands .claude/agents
cp ~/.claude/commands/build.md .claude/commands/
cp ~/.claude/commands/council.md .claude/commands/
cp ~/.claude/agents/*.md .claude/agents/
git add .claude/ && git commit -m "Vendor skills for AI-assisted development"
```

Now every teammate who opens Claude Code in this repo gets `/build` and `/council` with zero setup.

---

## `/council` — Multi-Lens Spec Review

```
/council PLAN.md
/council https://linear.app/unbound/issue/ENG-1234
/council <paste spec inline>
```

Convenes five reviewers **in parallel** on a spec or plan, then fuses the critiques into one verdict.

| Lens | Agent | What it asks |
|---|---|---|
| **Product vision** | inline (CEO/founder mode) | Is this the 10x version? What's missing? |
| **CISO** | `ciso-evaluator` | Does this survive a Fortune 500 buyer? Compliance blockers? |
| **Eng leader** | `eng-leader-evaluator` | DX friction? Adoption path? Revolt risk? |
| **Architecture** | `principal-architect` | Feasible? Edge cases? Realistic effort? |
| **PR reviewer dry-run** | `elite-pr-reviewer` | What will bite us at review time if we build as spec'd? |

Output:

- **Verdict** — BUILD / BUILD-WITH-CHANGES / RETHINK / KILL
- **Consensus items** — auto-escalated when two or more lenses flag the same issue
- **Dissents** — surfaced honestly, not papered over
- **Sharpened Definition of Done** — verifiable bullets you can test against
- **Scenarios to run** — concrete (often non-deterministic) test scenarios
- **Open questions** — what the author must answer before `/build`

### When to use `/council`

- Before every `/build` on a non-trivial feature
- When a spec feels thin and you want forcing questions
- When the team disagrees on scope and you need the disagreement surfaced
- Before a design doc goes to review — catch issues while the spec is cheap to change

### Key design principles

- **All five lenses run in parallel** — one message, five subagents, one synthesis
- **Consensus auto-escalates** — two lenses raising the same concern = blocker, not nice-to-have
- **Dissents are the point** — when the lenses disagree, that's high-signal; `/council` surfaces the disagreement instead of averaging it out
- **No code is written** — `/council` reviews specs, `/build` writes code

---

## `/build` — Full Development Pipeline

```
/build Add a REST endpoint for user preferences with CRUD operations
```

A production-grade CI pipeline running inside your Claude Code conversation. One command. Plan → Code → Simplify → Test → Review → Fix → Ship → Review Again → Validate.

| Step | Agent | What happens |
|---|---|---|
| **0. Plan** | `principal-architect` | Numbered implementation plan. Waits for your approval. |
| **1. Code** | `principal-engineer` | Implements the approved plan with integration tests. |
| **2. Simplify** | `code-simplifier` | Strips unnecessary complexity from changed files. |
| **3. Test** | `principal-engineer` | Integration tests for every code path. Runs suite. **Hard gate.** |
| **4. Review** | `elite-pr-reviewer` | Multi-pass review: correctness, security, performance, style. |
| **5. Fix** | `principal-engineer` + `principal-architect` | CRITICAL/WARNING findings fixed and validated. **Hard gate.** |
| **6. Ship** | `/ship` or built-in | Merges base branch, pushes, creates PR. |
| **7. Review again** | `elite-pr-reviewer` | Second-pass review on the final PR. |
| **8. Validate** | `principal-engineer` + `principal-architect` | Waits for CI/bot reviews, addresses comments, final sign-off. |

### Two entry modes

- **Build mode** — no code exists yet. Starts from planning (Step 0).
- **Iteration mode** — code already exists (dirty tree or commits ahead). Skips to simplification (Step 2).

### Key design principles

- **Never skip tests** — every code-changing step re-runs the suite
- **Never skip reviews** — both review passes are mandatory
- **Tests at the outermost layer** — API/task level, not helper unit tests
- **User approval required** on the plan before coding
- **Fail-stop** — if any step fails, stop and report

---

## Agent library

Every agent is also usable standalone via the `Agent` tool or direct invocation.

| Agent | Role |
|---|---|
| `principal-architect` | Translates requirements into implementation plans. Pushes back on unrealistic scope. |
| `principal-engineer` | Implements with production-grade quality. Writes integration tests. Surgical changes. |
| `principal-engineer-review` | Comprehensive codebase audit (security, reliability, velocity). |
| `elite-pr-reviewer` | Multi-pass code review (architecture, correctness, performance, security, style, testing). |
| `code-simplifier` | Reviews changed code for unnecessary complexity, dead code, style inconsistency. |
| `product-vision-scout` | World-class product strategist. Evaluates existing product through buyer + user lens. |
| `ciso-evaluator` | Fortune 500 CISO persona — compliance, risk, audit trail, board-reportable ROI. |
| `eng-leader-evaluator` | VP/SVP Engineering persona — DX, velocity, adoption path, revolt risk. |

---

## Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI installed and authenticated
- [GitHub CLI](https://cli.github.com/) (`gh`) — used by `/build` for PR creation
- A git repository with a remote (for `/build`)

### Optional

- [gstack](https://github.com/garrytan/gstack) — `/build` auto-detects `/ship` and uses it for PR creation with version bump + CHANGELOG + bisectable commits.
- [Playwright MCP](https://github.com/microsoft/playwright-mcp) — `product-vision-scout` uses it to navigate and screenshot live product.
- [Linear MCP](https://developers.linear.app/docs/mcp) — `/council` can consume Linear ticket URLs directly.

---

## Adding a new skill

The repo is designed to grow. To add a new skill:

1. Drop the command file in `commands/{name}.md` (with frontmatter `description:`).
2. Drop any new agents in `agents/{name}.md` (with frontmatter `name:`, `description:`).
3. Add a row to the Skills table at the top of this README.
4. Add a section below describing the command.

`install.sh` auto-picks up everything in `commands/*.md` and `agents/*.md` — no script changes needed.

---

## Customization

### Adjust agent behavior

Edit the agent `.md` files in `~/.claude/agents/` to change code style standards, testing philosophy, or add framework-specific guidelines.

### Adjust pipelines

Edit `~/.claude/commands/build.md` or `council.md` to skip steps, add steps, or change hard gates.

### Project-level overrides

Add project-specific instructions in your project's `CLAUDE.md`. Agents respect `CLAUDE.md` conventions, so you can override behavior per-repo without modifying global agent definitions.

---

## How it works under the hood

Each command is a Claude Code [slash command](https://docs.anthropic.com/en/docs/claude-code/slash-commands) that orchestrates one or more [agents](https://docs.anthropic.com/en/docs/claude-code/agents) via the `Agent` tool. Agents run as subagents with their own context and specialized prompts.

`/build` uses hard quality gates — if tests fail after Step 3 or Step 5, the pipeline stops instead of pushing through.

`/council` runs all five lenses in parallel in a single message, then synthesizes. No lens sees another lens's output — critiques stay independent.

---

## License

MIT
