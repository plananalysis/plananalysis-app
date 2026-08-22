# Plan Analysis App

Native macOS 14+ menu bar app for AI coding-plan usage. Built for [plananalysis.ai](https://plananalysis.ai).

CodexBar already covers many providers. This app is narrower and faster:

- AppKit status item, no SwiftUI, no Dock icon
- Incremental JSONL reads (byte-offset + inode cursors) instead of rescanning session trees
- Compact 30-day token delta store so window math stays correct after a partial read
- Recursive FSEvents, not a polling timer
- First-class **Export** (JSON / CSV)
- Opt-in **user ladder** upload to the plan detail page on plananalysis.ai

v0.1 reads local logs only:

| Provider | Source | What we count |
|---|---|---|
| Claude | `~/.claude/projects/**/*.jsonl` | `assistant.message.usage` |
| Codex | `~/.codex/sessions/**/*.jsonl` | `event_msg.token_count.last_token_usage` |

No browser cookies, no passwords, no prompt text leave the machine unless you tap **Upload**.

## Install

```bash
make test
make run
```

Requires Xcode / Swift 6. The binary is `dist/PlanAnalysis.app`.

## Export

Menu → **Export JSON…** or **Export CSV…**. The file is the 5h / 7d / 30d windows, not raw transcripts.

## User ladder

Menu → **Upload to Plan Analysis ladder…** sends only:

- display name
- plan id (`claude-pro`, `gpt-plus`, …)
- 5h token totals

The Worker stores one row per `(plan, display name)` and the plan page can fetch:

`GET https://plananalysis-ladder.jcyangzh.workers.dev/v1/ladder?plan=claude-pro`

Site embed is a follow-up in `codingplan-site` (`#ladder` on `/en/plans/:id.html`).

## Why this is faster than a full-provider bar

CodexBar polls many HTTP/cookie/CLI sources and can rescan large JSONL trees. The expensive path here is “new bytes since last cursor”. After the first pass, a refresh is a handful of `pread`s plus an in-memory window fold.

## Email

`hello@`, `support@`, `contact@`, and `team@plananalysis.ai` forward to the site owner via Cloudflare Email Routing.

## License

MIT
