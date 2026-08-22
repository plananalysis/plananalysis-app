# Plan Analysis App

Native macOS 14+ menu bar app for AI coding-plan usage. Built for [plananalysis.ai](https://plananalysis.ai).

CodexBar already covers many providers. This app is narrower and faster:

- AppKit status item, no SwiftUI, no Dock icon
- Incremental JSONL reads (byte-offset + inode cursors) instead of rescanning session trees
- Compact 30-day token delta store so window math stays correct after a partial read
- Recursive FSEvents, not a polling timer
- First-class **Export** (JSON / CSV)
- Opt-in **user ladder** upload to the plan detail page on plananalysis.ai

v0.2 **scans subscriptions** the way CodexBar does, then prices local tokens into Equiv. API $. You do not pick a plan.

| Provider | Subscription | Spend |
|---|---|---|
| Claude | Keychain `Claude Code-credentials` → OAuth usage | JSONL × list price |
| Codex | `~/.codex/auth.json` JWT `chatgpt_plan_type` | JSONL × list price |
| Cursor | Cursor.app `state.vscdb` `stripeMembershipType` | plan scanned; token spend later |

Upload sends only scanned plans. Guessed / missing logins stay local.

## Install

```bash
make test
make run
```

Requires Xcode / Swift 6. The binary is `dist/PlanAnalysis.app`.

## Export

Menu → **Export JSON…** or **Export CSV…**. The file is the 5h / 7d / 30d windows, not raw transcripts.

## User ladder

Menu → **Upload scanned samples…** sends:

- display name
- scanned plan id (`cursor-ultra`, `gpt-pro-20x`, …)
- 30d tokens + Equiv. $

The Worker keeps the latest row per `(plan, name)` and appends a sample. Fetch:

`GET https://plananalysis-ladder.jcyangzh.workers.dev/v1/ladder?plan=cursor-ultra`

Site embed is a follow-up in `codingplan-site` (`#ladder` on `/en/plans/:id.html`).

## Why this is faster than a full-provider bar

CodexBar polls many HTTP/cookie/CLI sources and can rescan large JSONL trees. The expensive path here is “new bytes since last cursor”. After the first pass, a refresh is a handful of `pread`s plus an in-memory window fold.

## Email

`hello@`, `support@`, `contact@`, and `team@plananalysis.ai` forward to the site owner via Cloudflare Email Routing.

## License

MIT
