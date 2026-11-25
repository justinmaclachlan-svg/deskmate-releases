# Deskmate

**AI teammates that work on your Windows PC, with a phone app to message them from anywhere.**

A native Windows app in Rust and a React Native companion app. Message a Bot from
your phone, or from Telegram, Discord, Slack, Signal, WhatsApp or email ("clean up my
Downloads and send me a screenshot"). It does the work on your PC, asks you before
anything risky, reports back, and learns from the work so the next time is faster. Each
Bot runs on its own model: any local model, Claude Code, Codex, Pi, Gemini CLI, Cursor,
Grok Build, or any AG-UI agent, and can switch brains mid-chat. Bots work
together in teams, split big jobs across parallel subagents, and can each work on their
own machine (a Docker container, your server, a cloud server, or a Hyper-V VM) that
several Bots can share for a long joint task. A `dm` command line for Windows and Linux
runs Deskmate headless or talks to it, and lets other AI agents such as Grok Bot message
your whole team.

Based on the ideas in [SuperBot](https://github.com/davidondrej/superbot), with parts of
its code (MIT). SuperBot runs Bots on a Linux VPS with a web app. Deskmate runs them
on your own Windows PC and adds phone pairing, approvals, local models and plugins.
The learning loop, skills, subagents and messaging gateway follow the design of
[Hermes Agent](https://github.com/NousResearch/hermes-agent) by Nous Research (MIT).
Channels, the activity feed, policy rules, a browser per Bot, smart routing and AG-UI
agents follow the design of [OpenBot](https://github.com/CopilotKit) by CopilotKit.

## What you get

| | |
| --- | --- |
| **A team of Bots** | Named teammates, each with one job, its own chat, its own model, and memory that grows (plain Markdown files). A primary Bot coordinates the rest. |
| **Learning loop** | After a task with many steps, the Bot looks back and saves a reusable **skill** (or fixes one that was wrong) and lasting facts to memory. Every Bot sees every skill and loads one when it fits. Skills use the [agentskills.io](https://agentskills.io) layout. |
| **Chat search** | Full-text search over every past conversation, for you (PC and phone) and for the Bots (`search_chats`). |
| **Persona** | A shared `SOUL.md` sets how Bots talk and work; any Bot can have its own. Local models also read `AGENTS.md` from the working folder. |
| **Teams and subagents** | Save a team: a lead and members, each on its own model. The lead hands out work with `delegate` and members run it at the same time. Any Bot can also start up to 8 temporary subagents, each on a harness and model it picks. |
| **Machines** | Bots can work on a Docker container, your own server over SSH, a cloud server Deskmate creates (Hetzner or DigitalOcean), or a Hyper-V VM, instead of your PC. Several Bots share one machine and its files for joint work; a team can have its own. Idle machines stop by themselves. |
| **`dm` CLI** | Windows and Linux. `dm serve` runs Deskmate without a window (e.g. on a VPS). `dm send`, `dm chat`, `dm team` talk to Bots from a terminal. `dm pair --agent` and `dm mcp` let another AI agent (like Grok Bot) message your team, without letting it approve anything. |
| **Messaging gateway** | Talk to your Bots from Telegram, Discord, Slack, Signal, WhatsApp or email. Strangers need your OK (a pairing code). Approvals are asked in the chat too (reply YES or NO). Routines can deliver their results there, and Bots can text you with `notify_user`. |
| **Your PC as their computer** | PowerShell, files, opening apps and URLs, screenshots, mouse and keyboard, clipboard, web fetches. |
| **Phone app** | Same features as the desktop: chats with live streaming, approval cards, routines, plugins, models, settings, quick screenshot and lock. |
| **Approvals** | Bots pause before risky actions. *Allow once*, *Always allow*, or *Deny* on the PC or phone. Plain rules like `run_powershell: git status*` or `*send*`. |
| **Any local model** | Ollama, LM Studio, llama.cpp, vLLM, Jan, LocalAI, or any OpenAI-compatible endpoint. Deskmate brings its own agent loop and tools. |
| **Coding-agent harnesses** | Claude Code, Codex and Pi through one small adapter each. Claude Code's permission prompts become Deskmate approval cards. |
| **Plugins** | Any MCP server, local command or remote URL, plugged into every Bot. Secrets come from a local vault the model never sees. |
| **Routines** | Cron schedules. Bots create their own ("every weekday at 8…"). Results can also go to a chat app. |
| **Bot to Bot, handoff** | Bots ask each other for help, and hand you a step at the PC (a login, 2FA, a CAPTCHA) with a *Done* button. |
| **Push notifications** | Optional. Approvals, handoffs and routine results reach your phone while the app is closed. Approvals have **Allow once** and **Deny** right on the notification. |
| **Remote desktop** | See and control the whole PC screen from the phone, at up to 30 fps, without turning on RDP. A pop-up trackpad with a one-finger scroll strip. An optional helper service covers the UAC prompt, the lock screen and Ctrl+Alt+Del. |
| **Channels** | Shared rooms where you and several Bots talk. `@mention` a Bot, or let smart routing pick who answers. Bots hand off to each other in the room. |
| **Activity and policy** | A feed of every tool call any Bot made or tried. Policy rules (deny before allow) by Bot, tool, host, command, path, who started it and machine, with a *what if* tester. |
| **A browser per Bot** | Each Bot gets its own headless Edge/Chrome profile (or a container). Watch it live on the PC or phone, **take the wheel**, hand it back, or teach it a flow. |
| **Task map** | Beside the chat (PC) or from the map icon (phone): a live network picture of the Bot working, then every step of the current task as it happens, with how long it took and whether it failed. 8 themes that match the model provider. Spending and the slowest steps of the week are in Settings → Usage. |
| **Live** | One tab with every Bot's live task map. Stuck Bots (one step running over 90 seconds, or nothing new for 2 minutes) and Bots waiting for you come first. Each card shows the Bot's skills and memory; tap either to edit. |
| **Work graph** | Live → Work graph: every Bot and everything it touches (files, folders, sites, commands, tools, skills, memory files) as one connected picture. The busiest things are labelled, things two or more Bots share get a ring, and what's in use right now pulses. Tap anything for who uses it and what it connects to. |
| **Memory you can edit** | Open a Bot's memory from the chat, a Live card or the graph and edit its MEMORY.md, its NOTES.md archive, or the shared USER.md about you. |
| **Context keeper** | When a chat's context passes 80%, the Bot tells you and offers a new chat with everything carried over: the full transcript is saved to a file, and the new chat starts with a recap, what was used, and a pointer to the transcript, so no earlier context is lost. You can also pick *New chat, carry everything over* any time. |
| **Security review** | Every skill and plugin is scanned when it's added or changed, and daily: Deskmate's own rules plus any scanner installed (NVIDIA SkillSpector, Cisco skill-scanner, ClamAV, Bandit, gitleaks, OSV-Scanner, ShellCheck). A Bot can't load a skill and a plugin can't start until that exact content passed. Settings → Security shows findings and lets you allow a blocked item. |
| **Deskmate OS** | Debian 13 with Deskmate as the desktop, for a Hyper-V VM. Each person's Bots run in a separate locked-down account (never root), with a sandbox for untrusted code, a hot corner to the normal Linux desktop, themes, and a tie-in to Deskmate on the host PC. See [os/README.md](os/README.md). |
| **Chats** | Each Bot keeps separate chats, each with its own context. Start a new one (with any Bot) when a chat gets long or muddled; reopen old ones from the chat list. Memory carries over. |
| **Brains and context** | Switch a Bot's harness mid-chat; it carries a recap. A context meter shows how full the window is. Per-Bot skills and notes. |
| **Usage meter and fallback** | Spend and tokens per harness per month, budgets, and an automatic switch to a fallback harness when a subscription hits its limit. |
| **Undo a task** | Files a Bot changes are copied first; undo a whole task in one tap. |
| **Voice** | Hold the mic in the phone app; the PC transcribes locally with whisper.cpp. Replies can be read aloud. |
| **Encrypted backup** | Nightly, to a folder (e.g. Google Drive for desktop) or straight to Google Drive. Argon2id + XSalsa20-Poly1305. |
| **Phone extras** | Wake-on-LAN, send files from any app's Share menu, clipboard sync, a daily brief, and an Android home-screen widget. |
| **Dedicated phone** | Turn an old Android phone into a Deskmate-only remote: kiosk mode, and a WireGuard tunnel that only reaches your laptop. |

## How it fits together

```
 Phone app (React Native)                Windows PC
 ┌──────────────────────┐   E2E-encrypted   ┌──────────────────────────────────────────┐
 │ Chats · Approvals    │◄── WebSocket ────►│ deskmate.exe (Rust)                      │
 │ Routines · My PC     │   (NaCl box)      │  ├ egui window + tray (same API as phone)│
 └──────────────────────┘                   │  ├ Bots: queue, memory, routines         │
                                            │  ├ Harnesses                             │
                                            │  │   local: Ollama / LM Studio / …       │
                                            │  │   claude · codex · pi · gemini ·      │
                                            │  │   cursor · grok (CLIs) · AG-UI agents │
                                            │  ├ Tools: PowerShell, files, screen…     │
                                            │  ├ Approvals + rules                     │
                                            │  ├ Plugins: MCP servers (stdio / HTTP)   │
                                            │  ├ Policy, activity, browsers, channels  │
                                            │  └ Remote desktop, voice, backup         │
                                            │ deskctl.exe: tools + approvals for CLIs  │
                                            │ deskmate-helper.exe: optional service    │
                                            └──────────────────────────────────────────┘
```

- `crates/deskmate-core`: everything that matters. One API (`api.rs`) that both apps call.
- `crates/deskmate-app`: the Windows window and tray icon, `deskmate.exe`.
- `crates/deskctl`: a tiny CLI and MCP server the coding-agent CLIs use to reach Deskmate.
- `crates/deskmate-cli`: `dm`, the Windows and Linux command line (headless host, client, MCP for agents).
- `crates/deskmate-helper`: the optional Windows service for the secure desktop (UAC, lock screen).
- `mobile/`: the Expo / React Native phone app.
- Protocol: [docs/protocol.md](docs/protocol.md).

## Install on Windows

Download **DeskmateSetup** from the latest run of the **deskmate** workflow on GitHub Actions
(Artifacts → `deskmate-installer`) and run it. It needs an administrator once and installs
Deskmate for **every user on the PC**:

- Program files go to `C:\Program Files\Deskmate`, with a Start menu shortcut for everyone.
- Each Windows user gets their own Bots, chats, memory, settings and paired phones in their own
  `%APPDATA%\Deskmate`, and their own `Deskmate` work folder.
- Several users can have Deskmate open at once (fast user switching): each one takes its own
  network port the first time (7878, then 7879, …) and keeps it. Each user pairs their own phone.
- Options: start Deskmate when each user signs in (each user can turn it off), a desktop
  shortcut, `dm` on everyone's PATH, and the remote desktop helper service.
- The installer adds a Windows Firewall rule (private networks only), so no one sees the
  firewall prompt.
- The helper service is shared: it serves whichever user is at the screen and keyboard,
  and never a user signed in in the background.
- Silent install: `DeskmateSetup-0.1.0.exe /VERYSILENT /SUPPRESSMSGBOXES /TASKS="autostart,path"`.
- Uninstall from Settings → Apps. Everyone's data in `%APPDATA%\Deskmate` is kept.

The installer isn't code-signed yet, so Windows SmartScreen will warn the first time
(More info → Run anyway).

## Build it on Windows

You need [Rust](https://rustup.rs) (stable, MSVC toolchain) and, for local models, [Ollama](https://ollama.com) or LM Studio.

```powershell
git clone <this repo>; cd deskmate
cargo build --release
.\target\release\deskmate.exe
```

Keep `deskctl.exe` (and `deskmate-helper.exe`, if you want the helper) next to `deskmate.exe`. To build the installer, install [Inno Setup 6](https://jrsoftware.org/isinfo.php) and run `iscc installer\deskmate.iss`. Or take both from the **build** workflow's
artifact on GitHub Actions.

1. **A model.** `ollama pull qwen3` (or any model with tool support). Deskmate finds
   Ollama on `localhost:11434` and LM Studio on `localhost:1234`. Add others under **Models**.
2. **Say hi** to the primary Bot under **Chat**.
3. **Optional:** install `claude`, `codex`, `pi`, `gemini`, `cursor-agent` or `grok` and sign in, as your Windows user. They
   show up as harnesses. Prefer the native installers (`.exe`), not npm's `.cmd` shims.

Windows asks to allow network access the first time. Allow **Private networks** so your phone can connect.

Data lives in `%APPDATA%\Deskmate`: the database, each Bot's `MEMORY.md`, `USER.md`,
plugins, skills, secrets and the PC key. Bots work in `%USERPROFILE%\Deskmate` by default.

## Run the phone app

```bash
cd mobile
npm install
npx expo install --fix        # align versions with your Expo SDK
npx expo run:android          # or: npx expo run:ios
```

Then on the PC open **Phones → Pair a phone** and scan the code. For a store-ready build use
[EAS Build](https://docs.expo.dev/build/introduction/) (`eas build`).
For push notifications, run `eas init` to set `extra.eas.projectId` in `app.json`.
Expo Go can't receive pushes; a development build can.

**Away from home:** put the PC and phone on [Tailscale](https://tailscale.com) (or any VPN), and set
**Settings → Phone address** to the PC's Tailscale name, e.g. `my-pc.tailnet.ts.net:7878`. Pair again.
The link is end-to-end encrypted either way. Don't port-forward 7878 to the internet.

## Machines

By default a Bot works on your PC, as you. Under **Machines** (or when a Bot asks) you can give
Bots other computers to work on:

| Kind | What it is | Approval | Memory on your PC |
| --- | --- | --- | --- |
| Docker container | A Linux container (Docker Desktop or Docker in WSL2). Its `/work` is a folder on your PC. | None: it can't touch your PC | About 0.5 to 2 GB each |
| Your server (SSH) | A VPS or home server you already have, with Deskmate's SSH key | Commands ask, like on the PC | None |
| Cloud server | Deskmate creates one at Hetzner or DigitalOcean (token in Secrets), and deletes it with the machine | Creating and deleting ask; it costs money until deleted | None |
| Hyper-V VM | A fresh copy of a template VM (Windows Pro, Hyper-V Administrators group), or an existing VM | Creating asks | 4 GB or more each |

- **Sharing.** A machine lists which Bots may use it, or "every Bot". Several Bots can work on it at
  the same time, in the same files. Give a team a machine under **Teams** and the lead's delegated
  work runs there. Subagents share their Bot's machine unless told otherwise; `machine: "new"` gives
  a job its own fresh container that goes away when the job ends.
- **Keeping.** *Stop when idle* (default, after 30 minutes; it starts again on the next command),
  *always on*, or *for one task*. Idle cloud servers aren't stopped (a stopped server still costs
  money); you get a notification instead.
- **Limits.** At most 3 containers and 1 VM run at once by default (**Settings**), so a 16 GB laptop
  stays usable next to a local model. Raise them if you have more memory.
- **Where commands go.** Local-model Bots get `run_shell` and the file tools on their machine. Claude
  Code, Codex and Pi keep their own shell on the PC and use `machine_exec` / `machine_copy`
  (or `deskctl machine exec`) to work on the machine.

## The `dm` command line

`dm` is part of the same build (`dm.exe` on Windows, `dm` on Linux). Run `dm help` for everything.

```bash
dm serve --pair                 # Linux server or VPS: run Deskmate headless and show a pairing code
dm status                       # on the same computer as Deskmate: works right away
dm send Assistant "free up disk space and tell me what you removed"
dm team "Research team" "compare the three cheapest 4K monitors"
dm chat Developer
dm pair "deskmate://pair?..."   # another computer: pair with the link from Phones → Pair a phone or CLI
```

**Other AI agents (Grok Bot and others).** On the agent's computer, install `dm` and pair it as an agent:

```bash
dm pair "deskmate://pair?..." --agent --name "Grok Bot"
dm team "Research team" "..."   # from its terminal, or:
dm mcp                          # as an MCP server: tools deskmate_message, deskmate_list_bots, ...
```

An agent pairing can message Bots and teams, read chats, skills and search, and see approvals, but it
can't answer approval cards, change settings, touch secrets or plugins, or pair devices. Bots are told
its messages come from another AI, not from you, and anything risky still waits for your OK. The agent
must be able to reach your PC: put both on Tailscale, or run `dm serve` on a VPS. Remove it any time
under **Phones and CLIs**.

## Teams and subagents

Make a Bot for each role (**+ New** in Chat), pick each one's model, and tell it its job.
Then under **Teams**, pick a lead and members. Message the lead: for work that splits into
parts it calls `delegate`, members work at the same time on their own models, and the lead
combines the results. Team routines are the lead's routines.

Without a team, any Bot can `delegate` to new **subagents**: hidden, temporary Bots that do
one task and are removed. A subagent runs on the harness and model the Bot picks for it,
or the default under **Settings → Subagents run on**. Up to 4 run at once per Bot (you can
change that). Subagents can't delegate further, schedule routines, or message other Bots.
Their approval cards show up like any other.

## Skills and the learning loop

After a task with at least 5 tool calls (**Settings → Learning loop**), the Bot gets a quiet
"learning check": save a reusable procedure as a skill, improve a skill that was wrong, save a
lasting fact with `remember`, or do nothing. You see a small note when it learns something.
Skills live in `%APPDATA%\Deskmate\skills\<name>\SKILL.md`; replaced versions go to
`skills\.history`, deleted ones to `skills\.archive`. Edit or write skills under **Skills**.

Bots' skill tools: `skill_list`, `skill_view`, `skill_save`. CLI harnesses get them through
`deskctl` too (`deskctl skills`, `deskctl skill view <name>`).

## Messaging

Under **Messaging**, add a channel, pick the Bot that answers (for a team, its lead), and fill in
the platform's options. Put tokens and passwords in **Plugins → Secrets** and write
`${secret:NAME}` in the options.

| Platform | How it connects | Options |
| --- | --- | --- |
| Telegram | Bot API long polling | `token` from @BotFather |
| Discord | REST, checks listed channels every 3 s | `token`, `channels` (ids). Turn on the Message Content intent. |
| Slack | Web API, checks listed conversations every 4 s | `token` (xoxb-), `channels` (ids) |
| Signal | [signal-cli-rest-api](https://github.com/bbernhard/signal-cli-rest-api) | `url`, `number` |
| WhatsApp | Cloud API webhook (needs a public HTTPS address, e.g. Tailscale Funnel) | `token`, `phoneNumberId`, `verifyToken` |
| Email | IMAP + SMTP over TLS, checks every 45 s | `imapHost`, `smtpHost`, ports, `username`, `password`, `address` |

- **Who can talk:** by default a stranger gets a code and waits until you tap **Allow** on the PC
  or phone. *Only people I allow* ignores strangers (the default for email). *Anyone* can only be
  set at the PC.
- The first person you allow becomes the **home chat**: routines set to *Also send to* that channel,
  and the Bots' `notify_user` tool, message it.
- In the chat: reply **YES**, **ALWAYS** or **NO** to an approval, a number to a choice card,
  `/new` for a new conversation, `/stop` to stop the Bot.
- Email skips bulk mail, auto-replies and no-reply senders, and never answers strangers.

## Plugins

A plugin is a folder in `%APPDATA%\Deskmate\plugins\<id>\` with a `plugin.json`. Add them
under **Plugins** on either app. See [examples/plugins](examples/plugins).

```json
{
  "id": "github",
  "name": "GitHub",
  "url": "https://api.githubcopilot.com/mcp/",
  "headers": { "Authorization": "Bearer ${secret:GITHUB_TOKEN}" },
  "safeTools": ["search_repositories", "get_issue"]
}
```

- `command` + `args` + `env` starts a local MCP server. `url` + `headers` connects to a remote one.
- `${secret:NAME}` is filled from the vault (**Plugins → Secrets**), `${env:NAME}` from the environment.
- `safeTools` only read. They skip approval cards in the default mode. Every other plugin tool asks first.
- A `skills/` folder of Markdown files teaches Bots how to use it. Shared skills go in
  `%APPDATA%\Deskmate\skills\` ([example](examples/skills/weekly-cleanup.md)).

Local models call plugin tools as `<plugin>__<tool>`. Claude Code and Codex get the same servers as MCP config.

## Remote desktop

Settings → **Remote desktop** → turn it on (it's off by default). Then on the phone: **My PC →
Remote desktop**, or the widget's button.

- No RDP and no open ports. Frames go over the same end-to-end encrypted phone link as chats.
- Captures at up to 30 fps (Settings: fps, quality, max width). Only the parts of the screen that
  changed are sent, as JPEG tiles, and the PC sends at most two frames ahead of what the phone has
  shown, so a slow network lowers quality instead of adding lag.
- Pinch to zoom, drag to pan. **Trackpad** pops up under the screen and hides again: move with one
  finger, tap = click, hold = right-click, and a narrow strip on the right scrolls up and down with
  one finger (or tap ▲ ▼). Keys: Esc, Tab, Win, Alt+Tab, Ctrl+C/V/Z, a keyboard, clipboard both ways.
- While a phone is watching, the PC shows a red always-on-top banner with **Stop** and **View only**.
  Sessions end after a timeout (default 60 minutes), and the PC can lock when the phone disconnects.
- **View only** is a setting too. A phone can turn remote desktop off or to view only, but never on.

**Helper service (optional).** Windows doesn't let normal apps see or click the UAC prompt, the lock
screen or the sign-in screen. Settings → Remote desktop → **Install helper** (one UAC prompt) installs
`DeskmateHelper`, a SYSTEM service listening on `127.0.0.1:7870` only, with a key file only SYSTEM,
admins and you can read. Deskmate uses it only while the secure desktop is in front, and for
Ctrl+Alt+Del. **Uninstall helper** removes it.

## Channels, activity and policy

- **Channels** are rooms with several Bots and you. Post with `@Name` to pick who answers; otherwise
  smart routing (a small local model, then keywords, then the room's lead) picks. Bots can post to the
  room and hand off (`channel_handoff`). Who may ask whom is set by *ask pairs* in Settings.
- **Activity** lists every tool call: who, what, the policy verdict and the result. Secrets are redacted.
- **Policy rules** refuse or allow by Bot, tool, host, command, path, initiator (you, a routine, a
  channel, another Bot, an agent) and machine. Deny rules win. Cloud metadata addresses are always
  blocked. **What if** shows which rule would match. Phones can add deny rules but not allow rules.
- **Routine guardrails:** at least 15 minutes between runs, at most 20 routines, and a routine turns
  itself off after 10 failures in a row.
- **Tool narrowing:** with many tools (over 24), local models get a core set plus `find_tools`.

## A browser per Bot

Each Bot has its own browser profile (headless Edge or Chrome, or the `zenika/alpine-chrome`
container: Settings → Browser). Bots read pages as numbered elements and click, type and scroll.
Password fields are refused; a Bot asks you with **request_help** instead. On the PC or phone you can
watch it live, **Take the wheel** (it waits), **Hand back**, or **Teach**: do the steps yourself
while it records them as a skill. Idle browsers close after 20 minutes.

## Usage, undo and backup

- **Usage** tab: tokens and spend per harness this month, with budgets. At the warning percentage
  (default 70%) you get a note; at 100% that harness pauses until next month. When a subscription
  reports a usage limit, the harness pauses for an hour and the task reruns on the **fallback
  harness** with a recap.
- **Undo:** before a Bot writes or deletes a file (and before Claude Code's Write/Edit), Deskmate keeps
  a copy (up to 50 MB per task). **Undo** restores them and moves new files aside. Shell commands
  aren't covered.
- **Backup:** Settings → Backup. Pick a folder (Google Drive for desktop's folder works) or connect
  Google Drive directly (needs your own OAuth client id, *Desktop app* type, `drive.file` scope).
  Set a passphrase; it is never stored in the backup. Nightly at 2am by default, keeping the last 10.
  Secrets are left out unless you choose otherwise. **Restore** takes effect at the next start.

## Voice

Settings → Voice → **Set up** downloads whisper.cpp, ffmpeg and a model (`base` by default) into the
data folder. Then hold the mic button in any phone chat. Audio is transcribed on the PC; nothing goes
to a cloud service. Turn on read-aloud in a chat to hear replies.

## Phone extras

- **Wake PC** on the offline banner sends a Wake-on-LAN packet (enable WoL in the BIOS and the network
  adapter's settings). The phone learns the PC's MAC addresses when it connects.
- **Share** a file or link from any app to Deskmate: it lands in `Deskmate\Inbox` on the PC, optionally
  as a message to a Bot. Use 📎 in a chat to attach from the phone.
- **Clipboard:** send the phone's clipboard to the PC and back from the remote desktop screen.
- **Daily brief:** Settings → Daily brief, an hour and a Bot. A summary of yesterday's work, waiting
  approvals and usage.
- **Widget:** long-press the Android home screen → Widgets → Deskmate.

## Dedicated phone

Turn a spare Android phone (Android 7+; tested target: Oyster Labs UBS1, Android 14) into a
Deskmate-only remote that can reach nothing but your laptop. PC: **Phones → Dedicated phone**, then
follow the steps:

1. Factory reset the phone, skip adding a Google account, turn on USB debugging, plug it in.
2. **Get adb** (downloads Google's platform tools) and **Check**.
3. **Install app**: the dedicated build (`npm run build:dedicated`, or the CI's `deskmate-android-dedicated` APK).
4. **Install WireGuard** on the phone (APK from wireguard.com) and **Set up WireGuard** on the PC (one UAC
   prompt: installs WireGuard for Windows, a tunnel `10.77.0.1` ↔ `10.77.0.2` on UDP 51820, and
   firewall rules so the phone can reach only Deskmate). Import the tunnel on the phone by QR.
5. **Make device owner** (`dpm set-device-owner`). This only works with no accounts on the phone.
6. **Pair** over the tunnel, then **Kiosk**, **Lock network** (always-on VPN with lockdown: no traffic
   outside the tunnel) and **Hide other apps**.
7. Set a PIN to leave kiosk mode on the phone.

With the network locked, internet push can't reach the phone, so it shows local notifications
while the app is open. To undo everything: leave kiosk with the PIN, **Release device owner**, or
factory reset.

## Approvals and safety

Bots act **as you** on a real computer. Deskmate's guard rails:

- **Approval modes:** *Ask before actions that change things* (default), *Ask before everything*,
  or *Off*. Only the PC can turn approvals off.
- **Rules:** *Ask first* and *Allow* globs over `tool: summary`. Ask wins. *Always allow* on a card
  saves an exact-match rule.
- Cards wait on the PC and every phone. Cards from routines expire after 30 minutes. A new
  message to a Bot closes its open cards.
- Deletes go to the Recycle Bin.
- Bots are told that web pages, files and tool output are information, not instructions.
  That lowers prompt-injection risk; it doesn't remove it. Keep risky tools behind approvals.
- Secrets stay in `secrets.json` on the PC and never reach a model. Phones can set secrets but not read them.
- **Harness differences:** local models and Claude Code ask through Deskmate, and policy rules
  apply before every call. Codex has no permission hook, so with approvals on it runs in its own
  `--full-auto` sandbox instead. Gemini runs with `auto_edit` when approvals are on. Cursor and Grok
  reach Deskmate's tools through `deskctl`. Their own built-in tools are logged in Activity but
  can't be stopped beforehand. Pi runs without prompts.
- **Remote desktop** is off until you turn it on, always shows a banner on the PC, and the helper
  service only answers loopback clients with its key.

## Status

Early, and not yet compiled or run end to end. It was written in an environment that couldn't
download Rust crates or npm packages. It passes a Rust syntax check and a TypeScript syntax check.
The first CI run will show what needs fixing. Expect a few rounds of compile fixes, mostly from
crate API versions (egui, tray-icon).

Not built yet: running Claude Code or Codex inside a machine (they work on it through
`machine_exec`), screens and mouse control inside machines, and model-based "auto review" of
actions. On Linux, `dm serve` has no screenshots, mouse and keyboard control, or remote desktop.
The remote-desktop banner may not show while Deskmate's main window is closed to the tray.
A Deskmate Lite web client for very old tablets (Android 4.x) is planned. The messaging gateway reads text
only, and Discord and Slack poll the conversations you list rather than using a live socket.

## License

MIT. Includes code adapted from SuperBot (MIT); see [LICENSE](LICENSE).
