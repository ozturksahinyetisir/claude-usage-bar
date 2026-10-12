# Claude Usage Bar

A tiny macOS menu bar app that keeps your **Claude 5-hour** and **weekly** usage visible at all times,
so you don't have to click the usage circle in the Claude app.

```
5s %60 · Hf %11
```

Turkish version: [README.tr.md](README.tr.md)

> Unofficial community project. Not affiliated with or endorsed by Anthropic.

## No keys needed

This project **does not ask for, store, or read any API key, token or password.**
Nothing is sent over the network. Everything stays on your Mac.
Each user runs it with their **own** Claude account; there is nothing to configure in the code.
If you fork it, never commit credentials (`.gitignore` already excludes `.env`, `*.key`, `*.pem`).

## Two modes

| Mode | Shows | Needs |
|---|---|---|
| **Estimate** (default) | `~5s %42 · ~Gün %18`, computed from your local Claude Code logs | Nothing. Works right after install |
| **Official** | `5s %60 · Hf %11`, the exact numbers Claude shows you | The Claude desktop app + a scheduled task (below) |

If official data is missing or older than 20 minutes the app falls back to the estimate and marks it with `~`.

## Install

Requirements: macOS 13+, Xcode Command Line Tools (`xcode-select --install`).

```bash
git clone https://github.com/ozturksahinyetisir/claude-usage-bar.git
cd claude-usage-bar
./build.sh
open ClaudeUsageBar.app
```

Optionally move `ClaudeUsageBar.app` to `/Applications`. On first launch macOS may warn about an unidentified
developer (the app is ad-hoc signed): right-click → **Open**.

### Estimate mode

Open the menu → **Limitleri ayarla…** and enter roughly how many tokens your plan allows per 5 hours / per day.
Anthropic does not publish these, so percentages in this mode are approximate.

### Official mode (exact percentages)

The official numbers are only readable from inside the Claude desktop app, so a small scheduled task copies them to a file the menu bar app reads:

1. In the Claude desktop app, open **Scheduled** and create a task running every 5 minutes (`*/5 * * * *`).
2. Install `scripts/write-usage.sh` and paste the prompt from [docs/refresh-task-prompt.md](docs/refresh-task-prompt.md).
3. Click **Run now** once and choose **"Always allow"** for the `write.sh` command. If a run ever hangs waiting for approval, later runs will not start.

The task writes `~/.claude-usage-bar/usage.json`. The Claude app must be open for it to run.
Each run is a very short session, so it costs a negligible amount of your own usage. 5 minutes is a good balance;
going much lower makes the measurement itself eat your quota.

## Menu

Click the menu bar text to see token counts, time until the 5-hour window resets, and options:
**Yenile** (refresh), **Limitleri ayarla…** (set limits), **Girişte başlat** (launch at login), **Çık** (quit).

## How it works

- Estimate: parses `~/.claude/projects/**/*.jsonl`, groups usage into 5-hour blocks and a daily total.
- Official: reads `~/.claude-usage-bar/usage.json` written by the scheduled task.
- Everything is one file: [Sources/main.swift](Sources/main.swift).

## Privacy

Reads local files only. No network access, no analytics, no credentials. `usage.json` contains only percentages and reset times.

## License

MIT
