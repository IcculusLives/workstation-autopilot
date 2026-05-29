# Workstation Autopilot

Keep your Mac fast and your files tidy — with **safe, reversible** automation you
control. Two modules today, built to grow into a full workstation toolkit.

| Module | What it does | Safety model |
|---|---|---|
| **mac-tuneup** | Reports what's actually using CPU/RAM (and real memory pressure), and can auto-quit a list of helpers you approve. | Kills only your allowlist, only your own processes, never system-critical ones. Dry by default. |
| **file-organizer** | Auto-sorts loose files in Downloads & Desktop into category folders by type. | Never deletes. Dry-run first. Every move is reversible with `--undo`. |

> **Design principle:** automation should never surprise you. Everything defaults
> to "show me first," nothing is destructive, and everything is reversible.

---

## Module 1 — mac-tuneup

### The 60-second mental model
- **Low "free RAM %" is normal.** macOS caches aggressively; empty RAM is wasted RAM.
- **The real warning sign is SWAP USED.** Sustained swap above ~1–2 GB = genuine pressure.
- **Idle background apps ≈ 0% CPU.** Killing them rarely helps; we target the few that misbehave.

### Install
```bash
mkdir -p ~/bin ~/mac-tuneup/snapshots
cp skills/mac-tuneup/scripts/mac-tuneup.sh ~/bin/
chmod +x ~/bin/mac-tuneup.sh
~/bin/mac-tuneup.sh            # first run: see your baseline
```

### Run it
| Command | Effect |
|---|---|
| `mac-tuneup.sh` | Report only (safe). Kills nothing. |
| `mac-tuneup.sh --clean` | Politely quit (SIGTERM) anything on your ALLOWLIST. |
| `mac-tuneup.sh --clean --force` | Force-kill (SIGKILL) instead. |
| `mac-tuneup.sh --auto` | Report + clean, quiet (used by the scheduler). |

### Run it automatically (launchd)
```bash
sed -i '' "s#REPLACE_WITH_HOME#$HOME#g" skills/mac-tuneup/scripts/com.afters.mactuneup.plist
cp skills/mac-tuneup/scripts/com.afters.mactuneup.plist ~/Library/LaunchAgents/
launchctl unload ~/Library/LaunchAgents/com.afters.mactuneup.plist 2>/dev/null
launchctl load   ~/Library/LaunchAgents/com.afters.mactuneup.plist
```
Runs a **report** every 2 hours by default (kills nothing). To enable autonomous
cleaning: add patterns to the `ALLOWLIST` in `mac-tuneup.sh`, then change the
plist argument from `report` to `auto` and reload.

### Let Claude analyze it
Connect your `~/mac-tuneup` folder to Cowork and say **"check my system."** Claude
reads the latest snapshot and tells you what's safe to close.

---

## Module 2 — file-organizer

### Install
```bash
cp skills/file-organizer/scripts/tidy.sh ~/bin/
chmod +x ~/bin/tidy.sh
~/bin/tidy.sh                 # DRY RUN: shows the plan, changes nothing
```

### Run it
| Command | Effect |
|---|---|
| `tidy.sh` | Dry run — shows what would move. Safe. |
| `tidy.sh --sort` | Actually move files (writes an undo manifest). |
| `tidy.sh --undo` | Reverse the most recent `--sort`. |
| `tidy.sh --other` | Also corral unknown types into an "Other" folder. |
| `tidy.sh --recent-hours N` | Change the "leave files newer than N hours" guard. |

Files sort into a single `Sorted/<Category>` folder inside each target. It only
touches loose top-level files older than 24h, never recurses into your existing
folders, skips hidden/system files, and never deletes.

### Let Claude do it
Connect your Downloads/Desktop folder to Cowork and say **"tidy my Downloads."**
Claude previews the plan, you confirm, and it sorts — with the same safety rules.

### Run it automatically (launchd)
Set-and-forget tidying that runs on your Mac even when Cowork is closed. Default:
**every day at 4:00 AM, sorting only files older than 48 hours** (so anything you
touched recently stays put). Each run writes its own undo manifest.
```bash
cp skills/file-organizer/scripts/tidy.sh ~/bin/ && chmod +x ~/bin/tidy.sh
sed -i '' "s#REPLACE_WITH_HOME#$HOME#g" skills/file-organizer/scripts/com.afters.tidy.plist
cp skills/file-organizer/scripts/com.afters.tidy.plist ~/Library/LaunchAgents/
launchctl unload ~/Library/LaunchAgents/com.afters.tidy.plist 2>/dev/null
launchctl load   ~/Library/LaunchAgents/com.afters.tidy.plist
```
Change the Hour/Minute in the plist to reschedule, or the `48` to a different
recent-file guard. Stop it with `launchctl unload ~/Library/LaunchAgents/com.afters.tidy.plist`.

---

## End-of-Session BMP (habit)
When wrapping a coding or long session: save & commit; run `mac-tuneup.sh` and
glance at the top hogs; Cmd-Q the heavy hitters (IDE, simulators, Docker/VMs,
extra browsers); stop dev servers/watchers; if swap is high, log out/restart;
optional `mac-tuneup.sh --clean`. Trigger phrase: **"run our end-of-session BMP."**

---

## Roadmap (where this grows)
- Scheduled file-organizer (launchd or Cowork task) for set-and-forget tidying.
- Filing by **project/client** and by **date**, not just type.
- Duplicate finder (report + safe quarantine, never auto-delete).
- A weekly "workstation health" digest combining both modules.
- Package additional modules and group plugins into a **marketplace**.

## Uninstall
```bash
launchctl unload ~/Library/LaunchAgents/com.afters.mactuneup.plist 2>/dev/null
rm -f ~/Library/LaunchAgents/com.afters.mactuneup.plist ~/bin/mac-tuneup.sh ~/bin/tidy.sh
# data/logs (optional): rm -rf ~/mac-tuneup
```

---
*v0.1.0 — safe-by-default workstation automation.*
