---
name: ultracheck
description: Run a heavy multi-agent code review with focused finder lenses, adversarial refutation, completeness checking, deduplication, validation, and fixes. Use only when the user explicitly invokes $ultracheck or /ultracheck, or explicitly asks for an ultra/deep swarm review.
---

# Ultracheck

Fan out independent reviews across complementary lenses, aggressively eliminate false positives,
then validate and apply what survives.

## 1. Determine the review subject

With no argument, review committed branch changes from the repository's merge base with its
default base branch, plus staged, unstaged, and untracked files. Discover the default branch
from repository metadata; fall back to an existing `main` or `master`.

Classify an argument as:

- **Scope redirect:** Replace the default subject with a git range, files, folder, feature, or
  search target. “Only,” “just,” and “review X in Y” usually indicate this mode.
- **Lens augmentation:** Keep the default subject and add a focused reviewer for the concern.
  “Focus on,” “pay attention to,” and “make sure” usually indicate this mode.

An argument may do both. Ask one short question only if the ambiguity would materially change
the swarm's subject.

Write a neutral session-goal paragraph describing what was attempted and which areas changed.
Do not include outcome claims such as “works,” “tests pass,” or “fixed.”

## 2. Run the finder swarm

Use independent `spawn_agent` reviewers with fresh context. Respect the available concurrency
limit: fill open slots, collect completed results, then start the next wave. Do not weaken the
review merely because all reviewers cannot run simultaneously.

Run one general reviewer and one focused reviewer for every always-on lens:

1. Type safety: lost information, weak generics, unjustified casts/assertions.
2. DRY: duplication and logic or types likely to drift.
3. SRP/cohesion: mixed concerns, layering, and oversized units.
4. Error handling/invariants: boundary validation, fallbacks, unchecked assumptions.
5. Security: injection, XSS, secrets, auth boundaries, unsafe deserialization.
6. Performance: N+1 work, memory growth, batching, throttling, data structures.
7. Naming/readability: intent, dead code, comments, surprising abstractions.
8. Test quality, but only when tests changed: edge cases and regression-catching assertions.

Add focused reviewers when the subject signals concerns such as concurrency, migrations, public
API compatibility, authorization, cryptography, external-service contracts, UI/render behavior,
data transformations, caching, or resource cleanup. Add a reviewer for any user-supplied lens.

Give each focused reviewer exactly:

- **Lens:** one concern, with instructions to stay within it.
- **Review subject:** concrete git commands/range, file list, or search target.
- **Session goal:** the neutral paragraph.

Give the general reviewer the subject and session goal. Instruct every finder to read applicable
`AGENTS.md`, the complete changed files, relevant callers/tests, and the 3–5 most load-bearing
files; make no edits; and report numbered findings with severity, `file:line`, concrete failure
mode, and suggested fix. If the subject is empty, stop.

## 3. Deduplicate

Cluster findings by nearby `file:line` and equivalent failure mode. Keep one candidate per
cluster, the highest severity, and the union of useful reasoning. Number the resulting list.

If there are no findings, skip refutation, completeness, and application; report a clean review.

## 4. Refute

Spawn exactly three independent refuters, one for each lens below. Each receives the complete
numbered candidate list and original review subject:

- **Correctness:** Is the claim true, or did the finder misread the code?
- **Materiality:** Is there a concrete defect rather than taste or speculative cleanup?
- **Coverage:** Do types, tests, callers, or surrounding code already handle the case?

Give every refuter this mandate: default to refuting a finding unless it can cite a concrete
failing input, trace, line, or contract violation. Have it inspect the files and return only a
YAML list with one entry per finding:

```yaml
- id: 1
  refuted: true
  confidence: high
  reason: One concrete sentence.
```

Aggregate votes per finding:

- 3/3 refuted: drop and note tersely.
- 2/3 refuted: drop and preserve the lone supporter's reason.
- 1/3 refuted: keep as medium-confidence and preserve the dissenting reason.
- 0/3 refuted: keep as high-confidence.

If the user requests a conservative run, keep only 0/3-refuted findings.

## 5. Check completeness

Spawn one focused critic with the original subject and surviving findings. Ask it to identify:

- changed, load-bearing files that escaped meaningful scrutiny;
- relevant dimensions no finder covered; and
- claims nobody checked against tests, callers, or contracts.

Require candidate findings in the same numbered format. If it produces any, send only those
through a second set of exactly three refuters using the lenses and voting rules above. Merge
survivors into the final list. Skip this phase when the original swarm found nothing.

## 6. Validate and apply

For each survivor, re-read the cited file in full against the current working tree. Verify the
failure mode, then apply the fix. Narrow related edits outside the original diff are acceptable;
sprawling changes across unrelated modules or package boundaries must be surfaced instead.
Reject any stale, incorrect, or already-resolved finding with a concise reason.

Run repository-prescribed formatting and verification proportional to the edits.

## 7. Report

Report in this order:

1. **Applied (high confidence)** — `file:line` and the fix.
2. **Applied (medium confidence)** — `file:line`, the fix, and the dissenter's reason.
3. **Surfaced for review** — valid findings too broad or risky to apply automatically.
4. **Refuted by the swarm** — terse bullets; include the lone supporter's note for 2/3 votes.

Keep the refuted section brief. If a section is empty, omit it.
