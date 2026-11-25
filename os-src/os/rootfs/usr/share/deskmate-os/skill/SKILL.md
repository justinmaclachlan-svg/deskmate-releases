---
name: deskmate-os
description: Change how this Deskmate OS computer looks and behaves for the user - theme, colours, background, fonts, keys, the bar, display scale, default apps, hooks, web apps, system software and plugins. Use when the user asks to customize, restyle, rebind, install or set something up on the computer itself.
---

# Customizing Deskmate OS

You run in a locked-down account, so you can't change the user's desktop from
your shell. Use these tools instead; Deskmate applies the change for the user
straight away.

## os_customize: look and behaviour

Call `os_customize` with `what` and `args` (a list of words). See what is set
now with `what: "status"` before changing things.

| The user wants | what | args |
|---|---|---|
| A different theme | theme | `["set", "nord"]` (names: `["list"]`) |
| Their own colours | theme | `["new", "sunset", "from", "nord", "ACCENT=ff7755", "BG=201a1a"]` then `["set", "sunset"]` |
| A theme from the internet | theme | `["install", "https://github.com/someone/some-theme"]` (the folder needs a `theme` file of KEY=hex lines) |
| A background picture | background | `["set", "/home/<you>/work/picture.png"]`, `["next"]`, `["none"]` |
| A different font or size | font | `["set", "JetBrains Mono", "12"]`, `["mono", "Fira Code"]`, `["size", "13"]`, `["list"]` |
| The bar moved or hidden | bar | `["top"]`, `["bottom"]`, `["hide"]`, `["show"]` |
| Bigger or smaller screen | display | `["scale", "1.5"]`, `["resolution", "1920x1080"]`, `["list"]` |
| A different default app | default | `["browser", "firefox-esr"]` (also terminal, files, editor) |
| Night light, idle lock | toggle | `["nightlight"]`, `["idle"]` |
| A website as an app | webapp | `["add", "Mail", "https://mail.example.com"]`, `["remove", "Mail"]` |
| Keys changed | keys | `["set", "W-g", "featherpad"]`, `["unbind", "W-q"]`, `["remove", "W-g"]`, `["list"]` |
| Something to run on an event | hooks | `["set", "theme-set", "notify-send Theme changed"]` (events: theme-set, font-set, background-set, login) |
| Everything back to normal | refresh | `["theme"]`, `["fonts"]`, `["keys"]`, `["bar"]`, `["all"]` |

Theme colours are: BG, BG2 (panels), LINE (borders), FG (text), DIM (quiet
text), ACCENT, RED, GREEN, YELLOW, BLUE, each six hex digits, plus
MODE=dark or MODE=light. Pick colours with enough contrast between BG and FG.

Keys are written W-g, C-A-t, W-S-Return: W is Super, A is Alt, C is Ctrl, S is
Shift. A key or hook runs its command as the user, so the user is always asked
to approve the exact command first. Keep it to one plain program and its
arguments.

For a background you made or downloaded, save the picture in your working
folder first, then pass that path.

## os_package: system software

`os_package` with `action: "install"` or `"remove"` and `names`. It installs
from Debian's own signed software only, and the user approves each request.
Look names up first with `apt-cache search <word>` in your shell. Things you
only need for your own work (a Python or Node library) go in your own account
with pip or npm instead; they need no approval.

## plugin_propose: new tools for Bots

`plugin_propose` with an id, a name, and either a `command` with `args` or a
`url`. Deskmate scans it, shows the user what it found, and turns it on only
if they approve. Put keys as `${secret:NAME}` in `env`; the user enters the
value themselves. Never put a real key in the request.

## Good manners

- Say what you changed and how to undo it (`refresh`, or the old value).
- Change one thing at a time when the user is deciding on a look, and offer a
  screenshot with desktop_screenshot after switching to the Linux desktop.
- If a tool says a name isn't known, list what exists and pick from that.
