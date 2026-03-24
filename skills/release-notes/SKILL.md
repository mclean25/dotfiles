---
name: release-notes
description: Generate GitHub release notes from commits since the last git tag, then create a GitHub release. Use when the user wants to cut a release, create release notes, or publish a new version.
argument-hint: [tag-name]
allowed-tools: Bash(git *), Bash(gh *)
---

You are creating a GitHub release. Follow these steps:

## Step 1: Gather context

Run these commands to understand the current state:

```
git tag --sort=-version:refname | head -5
```

to see recent tags, then:

```
git log <last-tag>..HEAD --oneline --no-merges
```

to get all commits since the last tag. Also run:

```
git log <last-tag>..HEAD --pretty=format:"%s" --no-merges
```

for cleaner commit messages.

## Step 2: Draft release notes

Organize the commits into a clean GitHub release message using this structure, summarizing and grouping
them where appropriate to get the point accross:

```markdown
## What's Changed

### Features
- ...

### Bug Fixes
- ...

### Improvements
- ...

### Other Changes
- ...
```

Only include sections that have relevant commits. Keep bullet points concise and
human-readable — rewrite terse commit messages into plain English where needed.
Omit chore/maintenance commits (dependency bumps, formatting, etc.) unless
notable. If a bunch of commits are related, group them into a single message.

## Step 3: Determine the tag name

Ask the user to provide the tag name.

## Step 4: Show a preview and confirm

Display the full release command that will be run, including the tag and release
notes, and ask the user to confirm before creating the release.

## Step 5: Create the GitHub release

Once confirmed, run:

```
gh release create <tag> --title "<tag>" --notes "<release notes>"
```

If creating a draft first is preferred, add `--draft`.

After creating, output the release URL.
