---
name: gh-create-pr
description: "Create a GitHub pull request from the current branch with a concise title and brief body. Use when the user wants Codex to open, draft, or prepare a PR for the current branch. Default to a draft PR unless the user explicitly asks for a ready-for-review PR. If the branch name contains a Linear-style issue key such as `eng-1234`, prefix the PR title with `[eng-1234]: `. Keep the description concise, omit a Testing section unless requested, and add a Why section only when it can be inferred from the change without fluff."
---

# Gh Create Pr

Create one concise GitHub pull request for the current branch.

## Workflow

1. Inspect the branch context first.
   Run `bash scripts/resolve_pr_context.sh` from this skill directory.
   Use its `branch`, `issue_key`, `title_prefix`, and `base` fields.
   If the user explicitly gives a base branch, override the detected `base`.

2. Check whether a PR already exists for the branch.
   Run `gh pr list --head "<branch>" --json number,title,url,isDraft,state --limit 1`.
   If a PR already exists, do not create a duplicate. Report the existing PR instead unless the user asks to update it.

3. Review the actual change before writing anything.
   Read enough context to describe the outcome, not file churn.
   Prefer:
   `git diff --stat "<base>...HEAD"`
   `git diff --name-only "<base>...HEAD"`
   `git log --oneline "<base>..HEAD"`
   Read targeted diffs when the scope is unclear.

4. Write the PR title.
   Keep it short, specific, and subject-style.
   Do not end the title with a period.
   If `title_prefix` is non-empty, prepend it exactly once.
   Avoid repeating the issue key in the remainder of the title.
   Treat the issue key as a Linear ticket taxonomy value from the branch name, not as freeform text.

5. Write the PR body.
   Keep it brief.
   Start with a `## Summary` section containing one short paragraph or a few tight bullets.
   Add `## Why` only when the reason for the change is clear from the diff, commits, or user request.
   Omit `## Testing` unless the user explicitly asks for it.
   Do not add filler sections such as rollout plans, checklists, or boilerplate.

6. Create the PR non-interactively.
   Default to draft:
   `gh pr create --draft --base "<base>" --title "<title>" --body "<body>"`
   If the user explicitly asks for a non-draft PR, omit `--draft`.

7. Report the result.
   Return the PR URL, final title, base branch, and whether it was created as a draft.

## Title Rules

Good titles:
- `[eng-4821]: Fix quote export ordering`
- `[web-77]: Improve loading state copy`
- `[eng-9012]: Add retry handling for webhook sync`
- `Refactor invoice summary rendering`

Avoid titles that are vague or mechanical:
- `[eng-4821]: updates`
- `[web-77]: changes`
- `fix stuff`
- `address comments`

## Body Template

Use this structure when it fits:

```md
## Summary

- Brief change summary
- Optional second bullet for another meaningful outcome

## Why

- Short reason the change exists
```

If `Why` is not well-supported by the change context, omit that section entirely.

## Guardrails

Do not guess the purpose of the change when the diff only shows refactors or churn.
Do not include a Testing section by default.
Do not create a duplicate PR for the same head branch.
If `gh` blocks the create due to auth, remote state, or validation, surface the exact failure.
