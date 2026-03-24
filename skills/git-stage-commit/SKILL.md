---
name: git-stage-commit
description: Stage all tracked and untracked repository changes and create a git commit with a concise, high-signal message. Use when the user wants Codex to commit current work, prepare a clean checkpoint, or write a commit message from the staged or unstaged diff. Always enforce a commit subject of 88 characters or fewer and add a body only when the change is complex enough to need extra context.
---

# Git Stage Commit

Stage every current change and create one non-interactive commit.

## Workflow

1. Inspect the working tree before changing anything.
   Run `git status --short` and review the diff when the scope is unclear.
2. Derive the commit message from the actual changes.
   Read enough of the diff to describe the user-visible or developer-visible outcome,
   not the implementation trivia.
3. Stage everything.
   Run `git add -A` unless the user explicitly asks for partial staging.
4. Write the commit message.
   Keep the subject line at 88 characters or fewer.
   Use imperative mood.
   Prefer one clear outcome over a list of file edits.
5. Decide whether a body is needed.
   Omit the body for simple, obvious changes.
   Add a short body when the change is complicated, risky, or spans multiple concerns.
6. Commit non-interactively.
   Use `git commit -m "<subject>"` for subject-only commits.
   Use multiple `-m` flags when adding a body.
7. Report the exact commit created.
   Include the new commit SHA and subject in the final response.

## Commit Message Rules

Keep the subject specific and compact.

Good subjects:
- `Fix invoice export sorting for multi-period reports`
- `Add retry handling for failed S3 metadata writes`
- `Refactor model summary parsing for quarterly filings`

Avoid subjects that are vague or mechanical:
- `updates`
- `fix stuff`
- `change files`
- `address review comments`

Use a body only when it adds context that would help a reviewer later.
Keep the body short and factual.
Focus on why the change exists, notable tradeoffs, or any important side effects.

Example with body:

```text
Refactor company sync to batch Dynamo writes

Reduce write amplification during large syncs by grouping updates per company.
This keeps the handler under the timeout threshold and preserves existing retry behavior.
```

## Guardrails

Do not create an empty commit unless the user explicitly asks for one.
If there are no changes, say so instead of committing.
If unrelated user changes are present, commit them together only because this skill is
specifically for staging all changes.
If the repo blocks the commit with hooks or validation, surface the failure clearly.
