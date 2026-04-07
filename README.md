# build-skill

A full development pipeline for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) that takes a task from idea to merge-ready PR. It orchestrates specialized agents across 9 steps with hard quality gates at each stage.

```
/build
```

That's it. One command. Plan -> Code -> Simplify -> Test -> Review -> Fix -> Ship -> Review Again -> Validate.

## What it does

`/build` is a production-grade CI pipeline running inside your Claude Code conversation:

| Step | Agent | What Happens |
|------|-------|-------------|
| **0. Plan** | `principal-architect` | Produces a numbered implementation plan. Waits for your approval. |
| **1. Code** | `principal-engineer` | Implements the approved plan with integration tests. |
| **2. Simplify** | `code-simplifier` | Strips unnecessary complexity from all changed files. |
| **3. Test** | `principal-engineer` | Ensures integration tests exist for every code path. Runs suite. **Hard gate.** |
| **4. Review** | `elite-pr-reviewer` | Multi-pass review: correctness, security, performance, style. |
| **5. Fix** | `principal-engineer` + `principal-architect` | Fixes CRITICAL/WARNING findings. Architect validates fixes. **Hard gate.** |
| **6. Ship** | `/ship` or built-in | Merges base branch, pushes, creates PR via `gh`. |
| **7. Review** | `elite-pr-reviewer` | Second-pass review on the final PR. |
| **8. Validate** | `principal-engineer` + `principal-architect` | Waits for CI/bot reviews, addresses comments, final sign-off. |

### Two entry modes

- **Build Mode** — no code exists yet. Starts from planning (Step 0).
- **Iteration Mode** — code already exists (dirty tree or commits ahead). Skips to simplification (Step 2).

### Key design principles

- **Never skip tests** — every step that changes code re-runs the suite
- **Never skip reviews** — both review passes are mandatory
- **Tests at the outermost layer** — API/task level, not helper unit tests
- **User approval required** on the plan before coding begins
- **Fail-stop** — if any step fails, it stops and reports

## What's included

```
build-skill/
├── commands/
│   └── build.md              # The /build slash command
├── agents/
│   ├── principal-architect.md    # Architecture & planning
│   ├── principal-engineer.md     # Implementation & testing
│   ├── principal-engineer-review.md  # Codebase-wide review
│   ├── elite-pr-reviewer.md     # PR-level code review
│   └── code-simplifier.md       # Code simplification
├── install.sh                # One-command installer
└── README.md
```

### Agent overview

| Agent | Role | When it's used |
|-------|------|---------------|
| **principal-architect** | Translates requirements into implementation plans. Pushes back on unrealistic scope. Validates architectural decisions. | Steps 0, 5, 8 |
| **principal-engineer** | Implements code with production-grade quality. Writes integration tests. Makes surgical, minimal changes. | Steps 1, 3, 5, 8 |
| **code-simplifier** | Reviews changed code for unnecessary complexity, dead code, style inconsistencies. Preserves functionality. | Step 2 |
| **elite-pr-reviewer** | Multi-pass code review (architecture, correctness, performance, security, style, testing). Outputs structured findings. | Steps 4, 7 |
| **principal-engineer-review** | Comprehensive codebase audit (security, reliability, velocity). Not used in `/build` directly but included as a standalone tool. | Standalone |

## Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI installed and authenticated
- [GitHub CLI](https://cli.github.com/) (`gh`) installed and authenticated (used for PR creation in Step 6)
- A git repository with a remote

### Optional

- [gstack](https://github.com/garrytan/gstack) — if installed, `/build` auto-detects the `/ship` skill and uses it for PR creation (Step 6) instead of the built-in `gh`-based fallback. gstack adds version bumping, CHANGELOG updates, bisectable commits, and its own pre-landing review.

## Install — 30 seconds

Open Claude Code and paste this. Claude does the rest.

> Install build-skill: run **`git clone --depth 1 https://github.com/websentry-ai/build-skill.git /tmp/build-skill && /tmp/build-skill/install.sh --force && rm -rf /tmp/build-skill`** — this installs the /build command and 5 specialized agents (principal-architect, principal-engineer, elite-pr-reviewer, code-simplifier, principal-engineer-review) into ~/.claude/. Then verify it worked by confirming /build is now available as a slash command.

That's it. No manual terminal steps. Claude clones, installs, cleans up.

### Alternative: manual install

If you prefer doing it yourself:

```bash
git clone https://github.com/websentry-ai/build-skill.git
cd build-skill
./install.sh
```

Or copy the files directly:

```bash
git clone --depth 1 https://github.com/websentry-ai/build-skill.git /tmp/build-skill
cp /tmp/build-skill/agents/*.md ~/.claude/agents/
cp /tmp/build-skill/commands/build.md ~/.claude/commands/
rm -rf /tmp/build-skill
```

### Team install — share with your repo

Want teammates to get build-skill automatically? Add it to your project:

```bash
# From your project root
mkdir -p .claude/commands .claude/agents
cp ~/.claude/commands/build.md .claude/commands/
cp ~/.claude/agents/principal-architect.md .claude/agents/
cp ~/.claude/agents/principal-engineer.md .claude/agents/
cp ~/.claude/agents/elite-pr-reviewer.md .claude/agents/
cp ~/.claude/agents/code-simplifier.md .claude/agents/
git add .claude/ && git commit -m "Add build-skill pipeline for AI-assisted development"
```

Now every teammate who opens Claude Code in this repo gets `/build` with zero setup.

### Verify

Open Claude Code in any git repo and type `/build`. You should see the pipeline start with Step 0 (Plan).

## Usage

### Full build from scratch

```
> /build Add a REST endpoint for user preferences with CRUD operations
```

Claude will:
1. Plan the implementation and ask for your approval
2. Code it with tests
3. Simplify, test, review, fix, and ship a PR

### Iterate on existing code

If you've already been coding:

```
> /build
```

Claude detects existing changes, skips planning, and picks up from simplification through PR.

### Use agents individually

Each agent works standalone too:

```
> Use the principal-architect agent to plan a migration from PostgreSQL to CockroachDB

> Use the principal-engineer agent to implement the approved plan

> Use the elite-pr-reviewer agent to review PR #142
```

## Customization

### Adjusting agent behavior

Edit the agent `.md` files in `~/.claude/agents/` to:

- Change code style standards (function length limits, nesting depth, etc.)
- Add project-specific conventions
- Adjust the testing philosophy (e.g., if you prefer unit tests)
- Add framework-specific guidelines

### Adjusting the pipeline

Edit `~/.claude/commands/build.md` to:

- Skip steps (e.g., remove the second review pass)
- Add steps (e.g., add a security scan step)
- Change the PR template
- Modify hard gates

### Project-level overrides

Add project-specific instructions in your project's `CLAUDE.md` file. The agents respect `CLAUDE.md` conventions, so you can override behavior per-repo without modifying the global agent definitions.

## How it works under the hood

`/build` is a Claude Code [slash command](https://docs.anthropic.com/en/docs/claude-code/slash-commands) that orchestrates multiple [agents](https://docs.anthropic.com/en/docs/claude-code/agents) via the `Agent` tool. Each agent runs as a subagent with its own context and specialized prompt.

The pipeline uses two hard quality gates:

1. **After Step 3 (Test)** — all tests must pass before review begins
2. **After Step 5 (Fix)** — all tests must pass again after review fixes

If either gate fails, the pipeline stops and reports the failure instead of pushing through.

## License

MIT
