[Español](README.es.md) · **English**

# AI Usage

A macOS desktop widget that shows your Claude subscription usage (5-hour session, weekly, and Opus/Sonnet) as rings, in the style of the Batteries widget. OpenAI support is planned for phase 2.

<p align="center">
  <img src="docs/images/widget-medium-dark.png" width="440" alt="Medium widget in dark mode: session 38%, week 71%, Opus 92%">
</p>

> The screenshots use sample data. The app's interface is in Spanish.

## What it shows

| Ring | Meaning |
|---|---|
|  **Sesión** (Session) | 5-hour window limit |
|  **Semana** (Week) | Weekly limit across all models |
|  **Opus / Sonnet** | Model-specific weekly limit (empty if your plan doesn't have one) |
|  | Reserved for OpenAI |

The color changes with usage: **green** below 60%, **yellow** up to 85%, and **red** above that. Below each ring you'll see how long until it resets.

<p align="center">
  <img src="docs/images/widget-medium-light.png" width="440" alt="Medium widget in light mode">
  <img src="docs/images/widget-small-dark.png" width="250" alt="Small widget with session and week">
</p>

There are two sizes: **medium** (4 rings) and **small** (session and week). Both adapt to light and dark mode.

### Menu bar

A small menu bar app shows the session %, refreshes the data every 5 minutes, and feeds the widget.

<p align="center">
  <img src="docs/images/menu.png" width="300" alt="Menu with usage details, Refresh, Open at login and Quit">
</p>

### Warnings

If your Claude Code session expires, or the app hasn't refreshed in more than 30 minutes, the widget keeps the last data and shows an orange warning.

<p align="center">
  <img src="docs/images/widget-expired.png" width="440" alt="Widget with the warning 'Token expirado — abre Claude Code' (Token expired — open Claude Code)">
</p>

## Requirements

- macOS 15 or later
- Full **Xcode** (App Store), not just the Command Line Tools. Open it once to accept the license.
- **XcodeGen**: `brew install xcodegen`
- An **"Apple Development" certificate**. A free Apple account works:
  Xcode → Settings → Accounts → `+` → Apple ID → select the team → *Manage Certificates…* → `+` → *Apple Development*.
- **Claude Code** installed and signed in (`claude`). The widget reads that session from the Keychain.

## Install

```sh
git clone <this repo>
cd widget-ai-usage
make install
```

This generates the project, builds it with your certificate, and installs `AIUsage.app` in `~/Applications`. Then:

1. `✳︎ N%` should appear in the menu bar. In the menu, turn on **Abrir al iniciar sesión** (Open at login).
2. Right-click the desktop → **Edit Widgets** → search for **AI Usage**.

`make check` only checks the requirements. If you have several certificates from different teams, pick one with `make install TEAM_ID=XXXXXXXXXX`.

### Reopening the app

If you quit it, the widget stops updating. To open it again: `⌘ Space` → **AI Usage**, or `open ~/Applications/AIUsage.app`.

### Uninstall

1. In the menu, turn off **Abrir al iniciar sesión** (Open at login) and click **Salir** (Quit).
2. Remove the widget from the desktop.
3. Delete the app: `rm -rf ~/Applications/AIUsage.app`

## How it works

```
Keychain (Claude Code session)
        │  every 5 min
        ▼
AIUsage.app (menu bar) ──► api.anthropic.com/api/oauth/usage
        │
        ▼  snapshot.json (only %, dates and plan)
Shared App Group
        │
        ▼
Widget (sandboxed, no network)
```

- The menu bar app reads the Claude Code session (`Claude Code-credentials` in the Keychain), fetches usage, and writes the result to an App Group shared with the widget.
- The token is kept only in memory and is sent only to `api.anthropic.com` over HTTPS. It is never written to disk or logs.
- The app **never refreshes the session** (that would sign you out of Claude Code). If it expires, it fixes itself the next time you use Claude Code.
- It's the same endpoint that `/usage` uses in Claude Code. It's undocumented and could change.
