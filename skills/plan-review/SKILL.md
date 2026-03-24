---
name: plan-review
description: Use when the user asks to review a plan, critique a plan, or wants feedback on an implementation plan before writing code. Triggers on "review this plan", "plan review", "/plan-review", or similar requests to evaluate a proposed approach.
version: 1.0.0
---

# Plan Review Mode

Review this plan thoroughly before making any code changes. For every issue or recommendation, explain the concrete tradeoffs, give me an opinionated recommendation, and ask for my input before assuming a direction.

## Priority hierarchy

If you are running low on context or the user asks you to compress: Step 0 > Test diagram > Opinionated recommendations > Everything else. Never skip Step 0 or the test diagram.

## My engineering preferences (use these to guide your recommendations):

- DRY is important—flag repetition aggressively.
- Well-tested code is non-negotiable; I'd rather have too many tests than too few.
- I want code that's "engineered enough" — not under-engineered (fragile, hacky) and not over-engineered (premature abstraction, unnecessary complexity).
- I err on the side of handling more edge cases, not fewer; thoughtfulness > speed.
- Bias toward explicit over clever.
- Minimal diff: achieve the goal with the fewest new abstractions and files touched.

## Step 0: Understand the current state

Before evaluating anything, read and summarize:
- The files the plan proposes to change
- Any existing tests covering those files
- Adjacent code that might be affected

Do not skip this step. Output a short summary of what exists today.

## Step 1: Draw the test diagram

Sketch out what the test surface should look like after implementation:
- Which behaviors need unit tests?
- Which need integration tests?
- Are there edge cases the plan doesn't mention that need coverage?

Output this as a simple bullet or table. Flag any gaps in the plan's testing story.

## Step 2: Opinionated recommendations

For each concern, structure your output as:

**Issue:** [what the problem is]
**Tradeoff:** [what you gain vs. lose by addressing it]
**Recommendation:** [your opinionated suggestion]
**Question for you:** [what you need from me to proceed]

Cover at minimum:
- DRY violations or duplication the plan introduces
- Over- or under-engineering concerns
- Missing edge case handling
- Abstraction count (new files, classes, helpers)
- Test coverage gaps identified in Step 1

## Step 3: Final check

Before finishing, confirm:
- [ ] Step 0 summary was output
- [ ] Test diagram was output
- [ ] Every recommendation includes a concrete tradeoff and a question

Do not begin implementation until the user has responded to your questions.
