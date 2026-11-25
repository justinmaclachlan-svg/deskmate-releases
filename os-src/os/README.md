# Deskmate OS

Debian 13 with Deskmate as the desktop, made to run in a Hyper-V VM.

## Get it

On the Windows PC, in PowerShell as Administrator:

```powershell
irm https://github.com/justinmaclachlan-svg/deskmate-releases/raw/os/New-DeskmateVM.ps1 -OutFile New-DeskmateVM.ps1
.\New-DeskmateVM.ps1
```

It downloads the disk, asks for your login name and two passwords (yours and
root's), makes a generation 2 VM, takes a "Fresh install" checkpoint, and adds
the VM to Deskmate's Machines on the PC when Deskmate is installed there.

## What comes over from your PC

When the script makes the VM it clones Deskmate from the PC: every Bot (name,
look, model, persona, memory), skills, plugins, teams, routines and policy
rules. It never copies sign-ins, saved secrets, browser logins, paired phones,
messaging channels or chat history; plugin settings that look like a key or
token are blanked. In the VM, sign in for the Bots' account:

```sh
deskmate-os login claude
deskmate-os login codex
deskmate-os login gemini
```

Every cloned skill and plugin gets a security review in the VM before a Bot
can use it. `-NoClone` starts with a fresh Deskmate. Later copies:
`dm clone export file.bin` on one side, `dm clone import file.bin` on the other.

## What you see

- **Deskmate fills the screen.** The top bar has **Terminal** and **Linux desktop**.
- **Top-right corner** (or Super+D): switch to the normal Linux desktop, and
  back. The Linux desktop has a taskbar, a launcher, files, a browser, a terminal.
- **Super+Alt+Space**: the Deskmate OS menu. **Super+K**: every hotkey.

## Accounts

| Account | What it's for |
|---|---|
| you (an admin) and any other people | Log in, use Deskmate and the desktop. Admins can use `sudo`. |
| `<name>-bots`, one per person | Everything that person's Bots run: AI coding tools, models, commands, browsers, plugins. No password, no sudo, can't read the person's home. |
| `root` | The terminal only (`su -` or `sudo -i`). Can't log in to the desktop or over SSH. Bots never run as root, and Deskmate refuses to start them as root. |

`sudo deskmate-os users` adds and removes people. Bots work in `~/Bots` (the
same folder they see as their workspace); share another folder with
`deskmate-os share <folder>`.

## Security

- **Review before use.** Every skill and plugin is scanned when it's added or
  changed and again daily. A Bot can't load a skill, and a plugin can't start,
  until that exact content passed. Blocked items wait under Settings →
  Security until you allow them.
- **Scanners.** Deskmate's own rules always run. Installed alongside: NVIDIA
  SkillSpector, Cisco skill-scanner, ClamAV, Bandit, OSV-Scanner, ShellCheck,
  and gitleaks where Debian carries it. Settings → Security shows which are present.
- **Sandbox.** `sandbox_run` (or `deskctl sandbox "<command>"`) works on a copy
  of a folder in a box with no network, a read-only system and an empty home,
  for reviewing, building, running and taking apart untrusted code.
- **Daily sweep.** Rescans skills and plugins, checks projects' dependencies
  against known vulnerabilities (OSV.dev) and the system's packages against
  Debian's list. Security updates install themselves daily.
- **Stops.** Super+Esc ends everything your Bots are running.
  `sudo deskmate-os net off` cuts the network for every Bots' account.
- **Firewall.** Nothing in except SSH (keys only, never root) and the phone link.

A scan lowers risk; it can't prove something is safe. The accounts, the
sandbox, policy and approvals are there for what a scan misses.

## Other agents

- **Deskmate on the host PC** uses the VM as a machine over SSH, as your
  Bots' account. `sudo deskmate-os host-key "<key>"` adds the host's key by hand.
- **Grok Bot (or any agent app) on the laptop** reaches the VM over the
  laptop's own Hyper-V network, with nothing exposed to the internet:
  1. In the VM: Super+Alt+Space → *Agents: pair one* (or `dm pair-code` in a
     terminal). It shows a one-time link.
  2. On the laptop, in PowerShell: `dm pair "<link>" --agent --name "Grok Bot"`
     (`dm` comes with Deskmate for Windows).
  3. In Grok Bot, add an MCP server that runs `dm --host <the VM's name> mcp`.
- **Paired agents** (`dm pair "<link>" --agent`, then `dm mcp`) get
  `deskmate_screen`, `deskmate_input`, `deskmate_desktop` and `deskmate_shell`
  as MCP tools while "Let paired AI agents…" is on in Settings (on by default
  on Deskmate OS).

## Build it yourself

```sh
cargo build --release -p deskmate-app -p deskmate-cli -p deskctl
mkdir bin && cp target/release/{deskmate,dm,deskctl} bin/
sudo os/build.sh bin out        # out/DeskmateOS.vhdx
sudo os/test.sh out/deskmate-os.raw results   # boots it and checks it
```
