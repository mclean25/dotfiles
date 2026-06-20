#!/usr/bin/env python3
"""Monthly local AI token usage and API-rate pricing report.

Reads Codex and Claude local logs without modifying them. Pricing is an
estimate using the rates embedded below; verify current vendor pricing when
exact billing matters.
"""

from __future__ import annotations

import argparse
import datetime as dt
import glob
import json
import re
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any


CODEX_RATES = {
    # USD per million tokens.
    "gpt-5.5": {"input": 5.00, "cached": 0.50, "output": 30.00},
    "gpt-5.4": {"input": 2.50, "cached": 0.25, "output": 15.00},
    "gpt-5.4-mini": {"input": 0.75, "cached": 0.075, "output": 4.50},
    "gpt-5.3-codex": {"input": 1.75, "cached": 0.175, "output": 14.00},
}


CLAUDE_RATES = {
    # USD per million tokens.
    "claude-fable-5": {
        "input": 10.0,
        "cache_write_5m": 12.5,
        "cache_write_1h": 20.0,
        "cache_read": 1.0,
        "output": 50.0,
    },
    "claude-opus-4-8": {
        "input": 5.0,
        "cache_write_5m": 6.25,
        "cache_write_1h": 10.0,
        "cache_read": 0.5,
        "output": 25.0,
    },
    "claude-opus-4-7": {
        "input": 5.0,
        "cache_write_5m": 6.25,
        "cache_write_1h": 10.0,
        "cache_read": 0.5,
        "output": 25.0,
    },
    "claude-opus-4-6": {
        "input": 5.0,
        "cache_write_5m": 6.25,
        "cache_write_1h": 10.0,
        "cache_read": 0.5,
        "output": 25.0,
    },
    "claude-opus-4-5": {
        "input": 5.0,
        "cache_write_5m": 6.25,
        "cache_write_1h": 10.0,
        "cache_read": 0.5,
        "output": 25.0,
    },
    "claude-sonnet-4-5": {
        "input": 3.0,
        "cache_write_5m": 3.75,
        "cache_write_1h": 6.0,
        "cache_read": 0.3,
        "output": 15.0,
    },
    "claude-haiku-4-5": {
        "input": 1.0,
        "cache_write_5m": 1.25,
        "cache_write_1h": 2.0,
        "cache_read": 0.1,
        "output": 5.0,
    },
}


USAGE_KEYS = (
    "input_tokens",
    "cached_input_tokens",
    "output_tokens",
    "reasoning_output_tokens",
    "total_tokens",
    "uncached_input_tokens",
    "cache_read_input_tokens",
    "cache_creation_input_tokens",
    "cache_creation_5m_input_tokens",
    "cache_creation_1h_input_tokens",
    "cache_creation_unknown_input_tokens",
    "messages",
    "sessions",
    "cost",
    "cost_low",
    "cost_high",
)


def main() -> None:
    args = parse_args()
    home = Path(args.home).expanduser()
    start = parse_date(args.start)
    end = parse_date(args.end) if args.end else dt.date.today() + dt.timedelta(days=1)
    excluded = set(args.exclude_month or [])

    report = {
        "window": {"start": start.isoformat(), "end_exclusive": end.isoformat()},
        "codex": collect_codex(home, start, end, excluded),
        "claude": collect_claude(home, start, end, excluded),
    }

    if args.format == "json":
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print_markdown(report)


def parse_args() -> argparse.Namespace:
    year_start = dt.date(dt.date.today().year, 1, 1).isoformat()
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--home", default=str(Path.home()), help="home directory")
    parser.add_argument("--start", default=year_start, help="inclusive YYYY-MM-DD")
    parser.add_argument("--end", help="exclusive YYYY-MM-DD; default is tomorrow")
    parser.add_argument(
        "--exclude-month",
        action="append",
        help="month to omit, e.g. 2026-02; may be repeated",
    )
    parser.add_argument("--format", choices=("markdown", "json"), default="markdown")
    return parser.parse_args()


def parse_date(value: str) -> dt.date:
    return dt.date.fromisoformat(value)


def parse_timestamp(value: Any) -> dt.datetime | None:
    if not isinstance(value, str) or not value:
        return None
    if value.endswith("Z"):
        value = f"{value[:-1]}+00:00"
    try:
        parsed = dt.datetime.fromisoformat(value)
    except ValueError:
        return None
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=dt.timezone.utc)
    return parsed.astimezone(dt.timezone.utc)


def in_window(ts: dt.datetime | None, start: dt.date, end: dt.date) -> bool:
    if ts is None:
        return True
    day = ts.date()
    return start <= day < end


def month_of(ts: dt.datetime | None, fallback_path: str) -> str:
    if ts is not None:
        return ts.strftime("%Y-%m")
    match = re.search(r"(\d{4}-\d{2})", fallback_path)
    return match.group(1) if match else "unknown"


def safe_int(value: Any) -> int:
    try:
        return int(value or 0)
    except (TypeError, ValueError):
        return 0


def add_numbers(target: dict[str, float], source: dict[str, float]) -> None:
    for key in USAGE_KEYS:
        target[key] += source.get(key, 0)


def collect_codex(
    home: Path, start: dt.date, end: dt.date, excluded: set[str]
) -> dict[str, Any]:
    paths = [
        *glob.glob(str(home / ".codex" / "archived_sessions" / "*.jsonl")),
        *glob.glob(str(home / ".codex" / "sessions" / "**" / "*.jsonl"), recursive=True),
    ]
    months: dict[str, Any] = defaultdict(month_bucket)
    model_months: dict[str, Any] = defaultdict(lambda: defaultdict(month_bucket))
    files_with_usage = 0

    for path in paths:
        last_usage: dict[str, int] | None = None
        last_ts: dt.datetime | None = None
        first_ts: dt.datetime | None = None
        model_counts: Counter[str] = Counter()
        token_events = 0

        for obj, raw_line in read_jsonl(path):
            if '"model"' in raw_line or "model=" in raw_line:
                model_counts.update(re.findall(r'"model"\s*:\s*"([^"]+)"', raw_line))
                model_counts.update(re.findall(r'model(?:\.id)?="([^"]+)"', raw_line))

            ts = parse_timestamp(obj.get("timestamp"))
            if not in_window(ts, start, end):
                continue

            payload = obj.get("payload")
            if not (
                obj.get("type") == "event_msg"
                and isinstance(payload, dict)
                and payload.get("type") == "token_count"
            ):
                continue

            info = payload.get("info") if isinstance(payload.get("info"), dict) else {}
            usage = (
                info.get("total_token_usage")
                if isinstance(info.get("total_token_usage"), dict)
                else {}
            )
            current = {
                "input_tokens": safe_int(usage.get("input_tokens")),
                "cached_input_tokens": safe_int(usage.get("cached_input_tokens")),
                "output_tokens": safe_int(usage.get("output_tokens")),
                "reasoning_output_tokens": safe_int(
                    usage.get("reasoning_output_tokens")
                ),
                "total_tokens": safe_int(usage.get("total_tokens")),
            }
            if ts is None or last_ts is None or ts >= last_ts:
                last_usage = current
                last_ts = ts
            first_ts = ts if first_ts is None or (ts and ts < first_ts) else first_ts
            token_events += 1

        if last_usage is None:
            continue

        month = month_of(last_ts or first_ts, path)
        if month in excluded:
            continue
        files_with_usage += 1
        model = model_counts.most_common(1)[0][0] if model_counts else "unknown"
        rec = dict(last_usage)
        rec["sessions"] = 1
        rec["uncached_input_tokens"] = max(
            rec["input_tokens"] - rec["cached_input_tokens"], 0
        )
        rec["cost"] = codex_cost(rec, model)
        rec["token_events"] = token_events

        add_numbers(months[month], rec)
        months[month]["models"][model] += 1
        months[month]["files"] += 1
        add_numbers(model_months[month][model], rec)

    return {
        "source": "codex local session token_count events",
        "files_scanned": len(paths),
        "files_with_usage": files_with_usage,
        "months": normalize_months(months),
        "model_months": normalize_nested_months(model_months),
    }


def codex_cost(usage: dict[str, float], model: str) -> float:
    rate = CODEX_RATES.get(model)
    if rate is None:
        return 0.0
    uncached = max(usage.get("input_tokens", 0) - usage.get("cached_input_tokens", 0), 0)
    cached = usage.get("cached_input_tokens", 0)
    output = usage.get("output_tokens", 0)
    return (
        uncached * rate["input"] + cached * rate["cached"] + output * rate["output"]
    ) / 1_000_000


def collect_claude(
    home: Path, start: dt.date, end: dt.date, excluded: set[str]
) -> dict[str, Any]:
    months: dict[str, Any] = defaultdict(month_bucket)
    model_months: dict[str, Any] = defaultdict(lambda: defaultdict(month_bucket))
    stats_last_day = collect_claude_stats_cache(home, start, end, excluded, months, model_months)
    raw_messages = collect_claude_raw_sessions(
        home, start, end, excluded, stats_last_day, months, model_months
    )

    return {
        "source": "claude stats cache plus raw project sessions",
        "stats_cache_last_day": stats_last_day.isoformat() if stats_last_day else None,
        "raw_messages": raw_messages,
        "months": normalize_months(months),
        "model_months": normalize_nested_months(model_months),
    }


def collect_claude_stats_cache(
    home: Path,
    start: dt.date,
    end: dt.date,
    excluded: set[str],
    months: dict[str, Any],
    model_months: dict[str, Any],
) -> dt.date | None:
    path = home / ".claude" / "stats-cache.json"
    if not path.exists():
        return None

    with path.open(encoding="utf-8", errors="replace") as handle:
        stats = json.load(handle)

    daily = stats.get("dailyModelTokens") if isinstance(stats, dict) else []
    weights: dict[str, dict[str, int]] = defaultdict(lambda: defaultdict(int))
    all_weights: dict[str, int] = defaultdict(int)
    last_day: dt.date | None = None

    for row in daily if isinstance(daily, list) else []:
        try:
            day = dt.date.fromisoformat(row.get("date"))
        except (TypeError, ValueError):
            continue
        last_day = day if last_day is None or day > last_day else last_day
        month = day.strftime("%Y-%m")
        tokens_by_model = row.get("tokensByModel", {})
        if not isinstance(tokens_by_model, dict):
            continue
        for model, tokens in tokens_by_model.items():
            token_count = safe_int(tokens)
            all_weights[model] += token_count
            if start <= day < end and month not in excluded:
                weights[model][month] += token_count

    model_usage = stats.get("modelUsage", {}) if isinstance(stats, dict) else {}
    if not isinstance(model_usage, dict):
        return last_day

    for model, usage in model_usage.items():
        if not isinstance(usage, dict) or all_weights.get(model, 0) == 0:
            continue
        denominator = all_weights[model]
        for month, month_weight in weights[model].items():
            fraction = month_weight / denominator
            rec = {
                "input_tokens": round(safe_int(usage.get("inputTokens")) * fraction),
                "output_tokens": round(safe_int(usage.get("outputTokens")) * fraction),
                "cache_read_input_tokens": round(
                    safe_int(usage.get("cacheReadInputTokens")) * fraction
                ),
                "cache_creation_input_tokens": round(
                    safe_int(usage.get("cacheCreationInputTokens")) * fraction
                ),
                "cache_creation_unknown_input_tokens": round(
                    safe_int(usage.get("cacheCreationInputTokens")) * fraction
                ),
                "source_stats_cache": 1,
            }
            rec["total_tokens"] = claude_total_tokens(rec)
            low, high = claude_cost_range(rec, model)
            rec["cost_low"] = low
            rec["cost_high"] = high
            add_numbers(months[month], rec)
            months[month]["models"][model] += 1
            months[month]["stats_cache_models"] += 1
            add_numbers(model_months[month][model], rec)

    return last_day


def collect_claude_raw_sessions(
    home: Path,
    start: dt.date,
    end: dt.date,
    excluded: set[str],
    skip_through_day: dt.date | None,
    months: dict[str, Any],
    model_months: dict[str, Any],
) -> int:
    paths = glob.glob(str(home / ".claude" / "projects" / "**" / "*.jsonl"), recursive=True)
    seen: set[str] = set()

    for path in paths:
        for obj, _raw_line in read_jsonl(path):
            if obj.get("type") != "assistant":
                continue
            message = obj.get("message")
            if not isinstance(message, dict) or not isinstance(message.get("usage"), dict):
                continue
            ts = parse_timestamp(obj.get("timestamp"))
            if not in_window(ts, start, end):
                continue
            if ts is None:
                continue
            day = ts.date()
            if skip_through_day is not None and day <= skip_through_day:
                continue
            month = ts.strftime("%Y-%m")
            if month in excluded:
                continue

            key = obj.get("requestId") or message.get("id") or obj.get("uuid")
            if not key or key in seen:
                continue
            seen.add(str(key))

            usage = message["usage"]
            model = message.get("model") or obj.get("model") or "unknown"
            cache_creation = usage.get("cache_creation")
            cache_creation = cache_creation if isinstance(cache_creation, dict) else {}
            cache_total = safe_int(usage.get("cache_creation_input_tokens"))
            cache_5m = safe_int(cache_creation.get("ephemeral_5m_input_tokens"))
            cache_1h = safe_int(cache_creation.get("ephemeral_1h_input_tokens"))
            cache_unknown = max(cache_total - cache_5m - cache_1h, 0)

            rec = {
                "input_tokens": safe_int(usage.get("input_tokens")),
                "output_tokens": safe_int(usage.get("output_tokens")),
                "cache_read_input_tokens": safe_int(usage.get("cache_read_input_tokens")),
                "cache_creation_input_tokens": cache_total,
                "cache_creation_5m_input_tokens": cache_5m,
                "cache_creation_1h_input_tokens": cache_1h,
                "cache_creation_unknown_input_tokens": cache_unknown,
                "messages": 1,
                "source_raw_sessions": 1,
            }
            rec["total_tokens"] = claude_total_tokens(rec)
            low, high = claude_cost_range(rec, model)
            rec["cost_low"] = low
            rec["cost_high"] = high

            add_numbers(months[month], rec)
            months[month]["models"][model] += 1
            months[month]["raw_messages"] += 1
            add_numbers(model_months[month][model], rec)

    return len(seen)


def claude_total_tokens(usage: dict[str, float]) -> int:
    return int(
        usage.get("input_tokens", 0)
        + usage.get("output_tokens", 0)
        + usage.get("cache_read_input_tokens", 0)
        + usage.get("cache_creation_input_tokens", 0)
    )


def claude_cost_range(usage: dict[str, float], model: str) -> tuple[float, float]:
    return (
        claude_cost(usage, model, unknown_as_1h=False),
        claude_cost(usage, model, unknown_as_1h=True),
    )


def claude_cost(usage: dict[str, float], model: str, unknown_as_1h: bool) -> float:
    rate = claude_rate_for(model)
    if rate is None:
        return 0.0
    unknown = usage.get("cache_creation_unknown_input_tokens", 0)
    cache_5m = usage.get("cache_creation_5m_input_tokens", 0)
    cache_1h = usage.get("cache_creation_1h_input_tokens", 0)
    if unknown_as_1h:
        cache_1h += unknown
    else:
        cache_5m += unknown
    return (
        usage.get("input_tokens", 0) * rate["input"]
        + cache_5m * rate["cache_write_5m"]
        + cache_1h * rate["cache_write_1h"]
        + usage.get("cache_read_input_tokens", 0) * rate["cache_read"]
        + usage.get("output_tokens", 0) * rate["output"]
    ) / 1_000_000


def claude_rate_for(model: str) -> dict[str, float] | None:
    normalized = model.lower()
    if "fable-5" in normalized:
        return CLAUDE_RATES["claude-fable-5"]
    if "opus-4-8" in normalized:
        return CLAUDE_RATES["claude-opus-4-8"]
    if "opus-4-7" in normalized:
        return CLAUDE_RATES["claude-opus-4-7"]
    if "opus-4-6" in normalized:
        return CLAUDE_RATES["claude-opus-4-6"]
    if "opus-4-5" in normalized:
        return CLAUDE_RATES["claude-opus-4-5"]
    if "sonnet-4-5" in normalized:
        return CLAUDE_RATES["claude-sonnet-4-5"]
    if "haiku-4-5" in normalized:
        return CLAUDE_RATES["claude-haiku-4-5"]
    return None


def read_jsonl(path: str) -> list[tuple[dict[str, Any], str]]:
    rows = []
    with open(path, encoding="utf-8", errors="replace") as handle:
        for line in handle:
            stripped = line.strip()
            if not stripped:
                continue
            try:
                obj = json.loads(stripped)
            except json.JSONDecodeError:
                continue
            if isinstance(obj, dict):
                rows.append((obj, stripped))
    return rows


def month_bucket() -> defaultdict[str, Any]:
    bucket: defaultdict[str, Any] = defaultdict(float)
    bucket["models"] = Counter()
    return bucket


def normalize_months(months: dict[str, Any]) -> dict[str, Any]:
    result = {}
    for month in sorted(months):
        bucket = dict(months[month])
        models = bucket.pop("models", Counter())
        bucket["models"] = dict(models.most_common())
        result[month] = bucket
    return result


def normalize_nested_months(months: dict[str, Any]) -> dict[str, Any]:
    result = {}
    for month in sorted(months):
        result[month] = {}
        for model in sorted(months[month]):
            bucket = dict(months[month][model])
            bucket.pop("models", None)
            result[month][model] = bucket
    return result


def print_markdown(report: dict[str, Any]) -> None:
    window = report["window"]
    print(f"# AI Usage Pricing Report ({window['start']} to {window['end_exclusive']} exclusive)")
    print()
    print("API-rate equivalent only. Verify current vendor pricing for exact billing.")
    print()
    print_codex_markdown(report["codex"])
    print()
    print_claude_markdown(report["claude"])


def print_codex_markdown(codex: dict[str, Any]) -> None:
    print("## Codex")
    print()
    print(
        f"Source: {codex['source']}. Files scanned: {codex['files_scanned']}; "
        f"files with usage: {codex['files_with_usage']}."
    )
    print()
    print("| Month | Model mix | Total tokens | Cached input | Uncached input | Output | Est. API cost |")
    print("|---|---|---:|---:|---:|---:|---:|")
    for month, row in codex["months"].items():
        print(
            f"| {month} | {model_mix(row)} | {fmt_int(row.get('total_tokens'))} | "
            f"{fmt_int(row.get('cached_input_tokens'))} | "
            f"{fmt_int(row.get('uncached_input_tokens'))} | "
            f"{fmt_int(row.get('output_tokens'))} | {fmt_money(row.get('cost'))} |"
        )


def print_claude_markdown(claude: dict[str, Any]) -> None:
    print("## Claude")
    print()
    stats_day = claude.get("stats_cache_last_day") or "not found"
    print(
        f"Source: {claude['source']}. Stats cache last day: {stats_day}; "
        f"raw messages: {claude['raw_messages']}."
    )
    print()
    print("| Month | Model mix | Total tokens | Cache read | Cache write | Output | Est. API cost |")
    print("|---|---|---:|---:|---:|---:|---:|")
    for month, row in claude["months"].items():
        print(
            f"| {month} | {model_mix(row)} | {fmt_int(row.get('total_tokens'))} | "
            f"{fmt_int(row.get('cache_read_input_tokens'))} | "
            f"{fmt_int(row.get('cache_creation_input_tokens'))} | "
            f"{fmt_int(row.get('output_tokens'))} | "
            f"{fmt_money_range(row.get('cost_low'), row.get('cost_high'))} |"
        )


def model_mix(row: dict[str, Any]) -> str:
    models = row.get("models") or {}
    if not models:
        return "-"
    return ", ".join(models.keys())


def fmt_int(value: Any) -> str:
    return f"{int(round(float(value or 0))):,}"


def fmt_money(value: Any) -> str:
    return f"${float(value or 0):,.2f}"


def fmt_money_range(low: Any, high: Any) -> str:
    low_f = float(low or 0)
    high_f = float(high or 0)
    if abs(low_f - high_f) < 0.005:
        return fmt_money(low_f)
    return f"{fmt_money(low_f)}-{fmt_money(high_f)}"


if __name__ == "__main__":
    main()
