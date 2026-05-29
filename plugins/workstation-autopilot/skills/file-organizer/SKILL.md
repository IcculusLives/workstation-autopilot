---
name: file-organizer
description: >-
  Safely auto-sort loose files into category folders by type, with full undo.
  Use when the user asks to "tidy my Downloads", "organize my desktop", "sort my
  files", "clean up Downloads/Desktop", "file organization", or references the
  tidy.sh script or a mac-tuneup organizer manifest. Never deletes; always
  reversible. Defaults to a dry-run plan the user approves before any move.
---

# file-organizer — safe, reversible file sorting

Sort loose files in the user's target folders (default: Downloads and Desktop)
into category subfolders by file type. The guiding rule for everything below:
**never delete, always reversible, dry-run first.** The user (Casey) holds a
forensic bar and wants safe automation, not surprises.

## Two ways to run it — pick based on what's connected

**Path A — operate directly on a connected folder (preferred when available).**
If the user has connected the relevant folder (e.g. Downloads/Desktop) to Cowork
so it's mounted in the bash environment, you can do the sort yourself:
1. ALWAYS preview first. List top-level files, group by the category map below,
   and show the user exactly what would move, where. Change nothing yet.
2. Apply only after the user confirms. Move files into `<folder>/Sorted/<Category>/`.
   Never recurse into existing subfolders. Never delete. Skip hidden/system files
   (`.DS_Store`, dotfiles), folders, aliases, and files modified in the last 24h.
3. Write a manifest (original path -> new path) so the moves can be undone, and
   tell the user how to reverse them.

**Path B — guide the user to run the bundled script (offline / scheduled).**
The script at `${CLAUDE_PLUGIN_ROOT}/skills/file-organizer/scripts/tidy.sh` runs
entirely on the user's Mac and works even when Cowork is closed (e.g. via a
launchd schedule). Use this when the folder isn't connected, or when the user
wants set-and-forget automation. Tell them:
- `tidy.sh` (or `--plan`) = dry run, shows the plan, changes nothing.
- `tidy.sh --sort` = actually moves files and writes an undo manifest.
- `tidy.sh --undo` = reverses the most recent `--sort`.
- `tidy.sh --other` = also corral unknown types into an "Other" folder.
- `tidy.sh --recent-hours N` = change the "leave files newer than N hours" guard.

## Category map (keep consistent with tidy.sh)

Images, Documents, Spreadsheets, Presentations, Audio, Video, Installers,
Archives, Code, Design. Unknown extensions are LEFT IN PLACE unless `--other`/
the user opts in. If you sort directly (Path A), use these same buckets so the
script and Claude produce identical structure.

## Reporting style (match the user's preferences)

Bottom line first; scannable; concise. After a sort, summarize: how many files
moved, the per-category counts, what was left in place and why (recent/unknown),
and the one-line undo instruction. Flag anything ambiguous rather than guessing
(e.g. a file whose type is unclear) and ask before moving it.

## Safety rules — do not violate

- Never delete a file. Moving only.
- Never recurse into the user's existing folders; only loose top-level files.
- Never move files modified within the recent-window (default 24h).
- Always have a way to undo, and always tell the user what it is.
- When unsure whether a folder is the right target, confirm before acting.

## Improvement hooks

If the user repeatedly re-sorts the same kinds of files, suggest adding a launchd
schedule (mirror the mac-tuneup LaunchAgent pattern) or a Cowork scheduled task
so tidying runs automatically. If they want project/client- or date-based
filing instead of by-type, note that as a future enhancement to propose.
