---
name: ai-usage-pricing
description: Recompute local Codex and Claude/Claude Code monthly token usage and API-rate pricing from ~/.codex and ~/.claude logs. Use when the user asks for AI usage, token totals, monthly pricing tables, Codex usage, Claude Code usage, Claude inference usage, or a rerun of prior usage/cost reports.
---

# AI Usage Pricing

Use the bundled script to generate repeatable monthly token and pricing reports
from local logs:

```bash
python3 ~/dev/dotfiles/skills/ai-usage-pricing/scripts/ai_usage_report.py
```

Common options:

```bash
# YTD, excluding a known partial month
python3 ~/dev/dotfiles/skills/ai-usage-pricing/scripts/ai_usage_report.py --exclude-month 2026-02

# Explicit date window. End is exclusive.
python3 ~/dev/dotfiles/skills/ai-usage-pricing/scripts/ai_usage_report.py --start 2026-01-01 --end 2026-07-01

# JSON for downstream processing
python3 ~/dev/dotfiles/skills/ai-usage-pricing/scripts/ai_usage_report.py --format json
```

## Workflow

1. Run the script first. Do not manually reimplement the aggregation unless the
   script is missing or broken.
2. If the user needs exact current billing, verify current vendor pricing before
   relying on the embedded rates. The script prints API-rate equivalents, not
   necessarily subscription-plan billing.
3. Preserve caveats in the answer:
   - Codex local logs may not include all devices or dates before logging began.
   - Claude `stats-cache.json` is aggregate and may lack cache-write duration,
     so those months can show a low/high cost range.
   - Claude raw session logs are deduped by request/message id when present.
4. Report missing months as missing local token-bearing logs, not as zero usage,
   unless the script explicitly shows token records with zero totals.

## Data Sources

Codex:
- `~/.codex/sessions/**/*.jsonl`
- `~/.codex/archived_sessions/*.jsonl`

Claude:
- `~/.claude/stats-cache.json`
- `~/.claude/projects/**/*.jsonl`

