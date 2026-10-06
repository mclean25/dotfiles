---
name: check
description: Run an independent fresh-context code review, validate every finding, and apply sound fixes. Use when the user invokes $check or /check, asks for an independent review of current branch changes, or wants a review-and-fix pass over a specific git range or code area.
---

# Check

Run a fresh-context reviewer, then independently verify and apply its valid findings.

## 1. Determine the review subject

With no argument, review the union of:

- committed branch changes against the repository's default base branch;
- staged and unstaged changes; and
- untracked files.

Discover the default base from repository metadata when possible. Fall back to an existing
`main` or `master` branch. Use the merge base so unrelated base-branch movement is excluded.

Interpret an argument as either:

- **Scope redirect:** Replace the default subject with the named range, files, folder, feature,
  or search target. Words such as “only,” “just,” or “review X in Y” usually redirect scope.
- **Lens augmentation:** Keep the default subject and emphasize a concern. Phrases such as
  “focus on,” “pay attention to,” or “make sure” usually augment the lens.

An argument may do both. Ask one short question only when ambiguity would materially change
the review.

## 2. Spawn the reviewer

Use `spawn_agent` to create one independent reviewer. Use a fresh context when supported and
pass only:

1. the concrete review subject;
2. a neutral paragraph describing what the session attempted; and
3. any augmented lens.

Do not claim that the implementation works, tests pass, or the bug is fixed. Those claims
create confirmation bias.

Instruct the reviewer to:

- read applicable `AGENTS.md` and repository guidance;
- inspect the specified diff plus complete changed files and relevant callers/tests;
- treat the working tree as read-only;
- review correctness, maintainability, typing, security, performance, code sharing, tests,
  and project-convention fit;
- re-read the 3–5 most load-bearing files before reporting; and
- return only a numbered list with severity, `file:line`, the concrete failure mode, and a
  specific fix.

If the subject is empty, stop and report that there is nothing to review. If sub-agents are
unavailable, perform the same review locally and disclose that it was not independent.

## 3. Validate and apply

For every finding:

1. Re-read the cited code in its current state.
2. Verify the claimed failure mode against callers, tests, types, and repository conventions.
3. Apply every finding that genuinely improves the code, including worthwhile minor issues.
4. Allow a narrowly related fix outside the diff when needed, such as updating callers after
   a rename.
5. Do not make sprawling changes across unrelated modules or package boundaries. Surface those
   for the user instead.
6. Briefly record why any other finding was rejected.

Run verification proportional to the edits and follow repository-specific validation commands.

## 4. Report

Lead with what changed. Then list rejected or deferred findings with concise reasons. If no
finding survived validation, say so plainly and mention the checks performed.
