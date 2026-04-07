---
description: Full development pipeline — plan, build, test, review, and raise PR. Combines principal-architect planning with principal-engineer execution, elite-pr-review validation, and automated PR landing.
---

# /build — Full Development Pipeline

Execute a complete development workflow from planning through PR review.

---

## Mode Detection

Check `git diff`, `git status`, and existing branches/PRs.

- **If code changes already exist** for the task (dirty working tree, or commits ahead of base branch): enter **Iteration Mode** (skip to Step 2).
- **Otherwise**: enter **Build Mode** (start at Step 0).

Both modes rejoin at **Step 3**.

---

## Build Mode (no existing code)

### Step 0: Plan

Before launching the architect:

1. Review the full conversation history above.
2. Write a bullet-point summary of every decision, constraint, technical direction, and requirement the user has established so far (call this `CONTEXT_SUMMARY`).
3. Launch `principal-architect` agent with a prompt structured exactly like this:

```
## Established Context (DO NOT override these decisions)
{CONTEXT_SUMMARY}

## Task
{the user's task/requirements}

## Constraints
- Follow the architecture and conventions documented in CLAUDE.md
- Propose the minimal set of changes needed
- Identify files that need to change and why
- Call out any risks or trade-offs
- Output a clear, numbered implementation plan
```

4. Present the plan to the user. Wait for approval before proceeding.

### Step 1: Code

Launch `principal-engineer` agent with the approved plan:

```
## Implementation Plan (approved)
{the plan from Step 0}

## Rules
- Follow the plan exactly — do not add scope
- Write integration tests at the outermost layer (API endpoint level or task level), not unit tests for helpers
- Ensure every new code path has test coverage
- Do not add unnecessary abstractions, comments, or type annotations beyond what's needed
```

### Step 2: Simplify

Launch `code-simplifier` agent on the changes:

```
Review all files changed in this session. Focus on:
- Removing unnecessary complexity or abstraction
- Ensuring consistency with surrounding code style
- Eliminating dead code or unused imports introduced
- Keeping the implementation minimal — no speculative features

Do NOT add docstrings, comments, or type annotations to code you didn't change.
Do NOT refactor surrounding code that wasn't part of the task.
```

---

## Iteration Mode (code already exists)

If changes already exist (e.g., the user has been coding and wants to finish the pipeline):

1. Run Step 2 (Simplify) on the existing changes.
2. Continue to Step 3.

---

## Step 3: Test & Verify (principal-engineer)

Launch `principal-engineer` agent focused on testing:

```
## Task: Verify and test the code changes

1. Review all changes made in this session (git diff against the base branch)
2. Ensure integration tests exist for every new/changed code path:
   - API endpoints → test at HTTP request/response level
   - Async tasks → test at task invocation level
   - If a helper is used by an API/task, it gets tested through that layer
   - Tests should be at the OUTERMOST layer, not unit tests for internals
3. If tests are missing, WRITE THEM
4. Run the full test suite and ensure all tests pass
5. If any test fails, fix the issue and re-run until green

Do NOT proceed until all tests pass. Paste the test output as evidence.
```

**Hard gate:** Do not proceed to Step 4 until test output shows all green.

---

## Step 4: Elite PR Review (first pass)

Launch `elite-pr-reviewer` agent on the code changes:

```
Review all changes on this branch vs the base branch (git diff origin/<base>...HEAD).

Focus on:
- Correctness and edge cases
- Security vulnerabilities (OWASP top 10, injection, auth bypasses)
- Performance issues (N+1 queries, missing indexes, unbounded loops)
- Error handling at system boundaries
- Test coverage gaps
- Code style consistency with the existing codebase

Output a structured list of findings with severity (CRITICAL / WARNING / INFO).
For each finding: file:line, problem, and recommended fix.
```

Capture the review output for Step 5.

---

## Step 5: Address Review Findings

For each finding from Step 4:

1. **CRITICAL findings**: Must be fixed. Launch `principal-engineer` agent to fix each one.
2. **WARNING findings**: Fix unless there's a clear reason not to. Use judgment.
3. **INFO findings**: Fix if trivial, skip if not.

After fixes are applied:

- Launch `principal-architect` agent to validate the fixes are architecturally sound:

```
## Task: Validate review fixes

Review the following fixes applied to address PR review findings:
{list of findings and what was changed}

Verify:
- Fixes don't introduce new issues or break the architecture
- The approach is correct, not just a band-aid
- No unnecessary scope creep from the fixes
```

- Re-run the test suite to ensure fixes didn't break anything.

**Hard gate:** Do not proceed until tests are green again.

---

## Step 6: Raise PR

### Option A: gstack /ship (if available)

Check if the `/ship` skill is available. If so, invoke it. It handles:
- Merging the base branch
- Running tests (again — verification gate)
- Pre-landing code review
- Version bump + CHANGELOG
- Bisectable commits
- Creating the PR with full summary

**Note:** gstack /ship may find additional issues in its own pre-landing review. Address those before the PR is created.

### Option B: Built-in PR workflow (fallback)

If `/ship` is not available, use this built-in workflow:

1. **Merge base branch:**
```bash
BASE_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')
git fetch origin "$BASE_BRANCH"
git merge "origin/$BASE_BRANCH" --no-edit
```

2. **Run tests again** to verify merge didn't break anything.

3. **Push the branch:**
```bash
git push -u origin HEAD
```

4. **Create the PR:**
```bash
# Generate PR body from commits
COMMITS=$(git log "origin/$BASE_BRANCH"..HEAD --pretty=format:"- %s" --reverse)

gh pr create \
  --title "<concise title describing the change>" \
  --body "$(cat <<EOF
## Summary
<1-3 bullet points summarizing what changed and why>

## Changes
$COMMITS

## Test plan
- [ ] All existing tests pass
- [ ] New integration tests added for changed code paths
- [ ] Manual verification of <specific behavior>

---
*Generated by [build-skill](https://github.com/your-org/build-skill)*
EOF
)"
```

---

## Step 7: Elite PR Review (second pass — on the PR)

After the PR is created, run a second elite-pr-reviewer pass:

```
Review the pull request at {PR_URL}.

This is a second-pass review after the PR has been created.
Focus on:
- The PR as a whole (summary accuracy, test plan completeness)
- Any issues that may have been introduced during the PR workflow (version bump, changelog, doc sync)
- Final sanity check on the full diff
```

Capture the review output.

---

## Step 8: Final Validation

**Wait 5 minutes** for any bot reviews (CI, linters, etc.) to post on the PR.

After waiting:

1. Check the PR for bot review comments:
```bash
gh pr checks {PR_NUMBER} 2>/dev/null
gh api repos/{owner}/{repo}/pulls/{PR_NUMBER}/comments 2>/dev/null | head -100
gh api repos/{owner}/{repo}/pulls/{PR_NUMBER}/reviews 2>/dev/null | head -100
```

2. Launch `principal-engineer` agent to validate all review comments (both elite-pr-reviewer and bot reviews):

```
## Task: Final review validation

Review these comments on PR #{PR_NUMBER}:

### Elite PR Review (second pass):
{review output from Step 7}

### Bot/CI Reviews:
{bot comments from PR}

For each comment:
- If it's a valid issue: fix it, commit, and push
- If it's a false positive: explain why (leave as a reply on the PR)
- If it's informational: acknowledge

After addressing all comments, re-run tests to verify.
```

3. Launch `principal-architect` agent to do a final architectural sign-off:

```
## Task: Final sign-off

Review the PR at {PR_URL} in its final state.
- All review comments have been addressed
- All CI checks should be passing
- The implementation matches the original plan from Step 0

Confirm the PR is ready to merge, or flag any remaining concerns.
```

---

## Output

At the end, output:

```
## /build complete

**PR:** {PR_URL}
**Status:** Ready for merge / Needs attention
**Pipeline:**
  - [x] Step 0: Plan (principal-architect)
  - [x] Step 1: Code (principal-engineer)
  - [x] Step 2: Simplify (code-simplifier)
  - [x] Step 3: Test & verify (principal-engineer)
  - [x] Step 4: Elite PR review (first pass)
  - [x] Step 5: Fix findings + validate (principal-engineer + principal-architect)
  - [x] Step 6: Raise PR
  - [x] Step 7: Elite PR review (second pass)
  - [x] Step 8: Final validation (bot reviews + sign-off)
```

---

## Important Rules

- **Never skip tests.** Every step that changes code must re-run tests.
- **Never skip reviews.** Both elite-pr-review passes are mandatory.
- **Tests must be at the outermost layer** — API/job level, not helper unit tests.
- **Wait for user approval** on the plan (Step 0) before coding.
- **5-minute gap** between Step 7 and Step 8 for bot reviews to land.
- **If any step fails**, stop and report. Don't try to push through.
