[Español](README.es.md) · **English**

# AI Usage

A macOS desktop widget that shows your Claude subscription usage (5-hour session and weekly) as rings, in the style of the Batteries widget. Each widget shows one provider, picked in the widget's settings. OpenAI support is planned for phase 2.

<p align="center">
  <img src="docs/images/widget-medium-dark.png" width="440" alt="Medium widget in dark mode: session 38%, week 71%">
</p>

> The screenshots use sample data. The app's interface is in Spanish.

## What it shows

| Ring | Meaning |
|---|---|
|  **Sesión** (Session) | 5-hour window limit |
|  **Semana** (Week) | Weekly limit across all models |

The color changes with usage: **green** below 60%, **yellow** up to 85%, and **red** above that. The icon inside each ring tells you which limit it is; the exact reset times are in the menu bar app.

<p align="center">
  <img src="docs/images/widget-medium-light.png" width="440" alt="Medium widget in light mode">
  <img src="docs/images/widget-small-dark.png" width="250" alt="Small widget with session and week">
</p>

There are two sizes, **small** and **medium**, both showing session and week. Medium leaves two empty rings, like the Batteries widget. Both adapt to light and dark mode.

### Choosing a provider

To change the provider, right-click the widget → **Edit "AI Usage"** → **Proveedor** (Provider). To watch more than one provider, add one widget per provider.

| Provider | Status |
|---|---|
| Claude | Available |
| OpenAI | Coming soon (the widget shows empty rings and "Próximamente") |

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

- macOS 15 Sequoia or later
- **Claude Code** installed and signed in (`claude`). The widget reads that session from the Keychain.

## Install

1. Download `AIUsage-<version>.zip` from the [latest release](https://github.com/AlexiMarin/widget-ai-usage/releases/latest).
2. Unzip it and drag **AIUsage.app** to **Applications**.
3. Open it. `✳︎ N%` should appear in the menu bar. In the menu, turn on **Abrir al iniciar sesión** (Open at login).
4. Right-click the desktop → **Edit Widgets** → search for **AI Usage**.
5. Optional: right-click the widget → **Edit "AI Usage"** to pick the provider (Claude by default).

### Widget doesn't match the menu bar

macOS decides when widgets redraw and limits how often they can update, so the widget can lag the menu bar by a few minutes. After updating the app, remove the widget and add it again so macOS picks up the new version.

### Reopening the app

If you quit it, the widget stops updating. To open it again: `⌘ Space` → **AI Usage**, or `open -a AIUsage`.

### Uninstall

1. In the menu, turn off **Abrir al iniciar sesión** (Open at login) and click **Salir** (Quit).
2. Remove the widget from the desktop.
3. Move **AIUsage.app** to the Trash (it is in Applications, or in `~/Applications` if you built it yourself).

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

## Building from source

Only if you want to modify the app. You'll also need:

- Full **Xcode** (App Store), not just the Command Line Tools. Open it once to accept the license.
- **XcodeGen**: `brew install xcodegen`
- An **"Apple Development" certificate**. A free Apple account works:
  Xcode → Settings → Accounts → `+` → Apple ID → select the team → *Manage Certificates…* → `+` → *Apple Development*.

```sh
git clone https://github.com/AlexiMarin/widget-ai-usage.git
cd widget-ai-usage
make install
```

This generates the project, builds it with your certificate, and installs `AIUsage.app` in `~/Applications`. `make check` only checks the requirements. If you have several certificates from different teams, pick one with `make install TEAM_ID=XXXXXXXXXX`.

`make release` builds the Developer ID–signed, notarized zip for publishing a release (one-time setup is described at the top of `scripts/release.sh`).
