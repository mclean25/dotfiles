#!/usr/bin/env bash

set -euo pipefail

branch=""
base=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --branch)
      branch="${2:-}"
      shift 2
      ;;
    --base)
      base="${2:-}"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

git_output() {
  git "$@" 2>/dev/null || true
}

if [[ -z "$branch" ]]; then
  branch="$(git_output branch --show-current | tr -d '\n')"
fi

if [[ -z "$branch" ]]; then
  echo "Could not determine the current branch." >&2
  exit 1
fi

issue_key=""
branch_lower="$(printf '%s' "$branch" | tr '[:upper:]' '[:lower:]')"
if [[ "$branch_lower" =~ (^|/)([a-z][a-z0-9]*-[0-9]+)([^a-z0-9]|$) ]]; then
  issue_key="${BASH_REMATCH[2]}"
fi

if [[ -z "$base" ]]; then
  origin_head="$(git_output symbolic-ref --quiet --short refs/remotes/origin/HEAD | tr -d '\n')"
  if [[ -n "$origin_head" && "$origin_head" == */* ]]; then
    base="${origin_head##*/}"
  fi
fi

if [[ -z "$base" ]]; then
  if git show-ref --verify refs/heads/main >/dev/null 2>&1; then
    base="main"
  elif git show-ref --verify refs/heads/master >/dev/null 2>&1; then
    base="master"
  else
    base="main"
  fi
fi

title_prefix=""
if [[ -n "$issue_key" ]]; then
  title_prefix="[$issue_key]: "
fi

printf '{\n'
printf '  "branch": "%s",\n' "$branch"
if [[ -n "$issue_key" ]]; then
  printf '  "issue_key": "%s",\n' "$issue_key"
else
  printf '  "issue_key": null,\n'
fi
printf '  "title_prefix": "%s",\n' "$title_prefix"
printf '  "base": "%s",\n' "$base"
printf '  "draft": true\n'
printf '}\n'
