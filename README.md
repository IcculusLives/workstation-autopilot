# Afters Tools — a Claude plugin marketplace

Safe, reversible Mac automation by **Afters DJs**. This repo is a Claude plugin
marketplace; right now it ships one plugin, **Workstation Autopilot**, with more
to come.

> **The promise:** automation that never surprises you. Nothing destructive,
> everything undoable, and you stay in control of every rule.

## Install (in Claude Code or Cowork)

> Replace `YOUR_GH_USERNAME` with your GitHub username after you publish this repo.

```text
/plugin marketplace add YOUR_GH_USERNAME/workstation-autopilot
/plugin install workstation-autopilot@afters-tools
```

`afters-tools` is the marketplace name; `workstation-autopilot` is the plugin.

## What's inside Workstation Autopilot

| Module | What it does | Safety model |
|---|---|---|
| **mac-tuneup** | Reports what's actually using CPU/RAM and real memory pressure; can auto-quit a list of helpers **you** approve. | Kills only your allowlist, only your own processes, never system-critical ones. Reports by default. |
| **file-organizer** | Auto-sorts loose files in Downloads & Desktop into category folders by type. | Never deletes. Dry-run first. Every move reversible with `--undo`. |

Full setup, the launchd schedulers, and the End-of-Session BMP live in the
plugin's own README: [`plugins/workstation-autopilot/README.md`](plugins/workstation-autopilot/README.md).

## Repo layout

```
.
├── .claude-plugin/
│   └── marketplace.json          # the marketplace catalog
└── plugins/
    └── workstation-autopilot/    # the plugin (skills + scripts)
```

## Releasing updates

Version is pinned in `plugins/workstation-autopilot/.claude-plugin/plugin.json`.
**Bump that `version` on every release** — users only receive updates when it
changes. Then commit and push; Claude refreshes with `/plugin marketplace update`.

## License

MIT — see [LICENSE](LICENSE).
