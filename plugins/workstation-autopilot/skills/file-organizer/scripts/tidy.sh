#!/bin/bash
# =============================================================================
#  tidy.sh  —  safe, reversible file auto-sorter for macOS
# -----------------------------------------------------------------------------
#  WHAT IT DOES
#    Sorts loose files in your target folders (default: Downloads + Desktop)
#    into category subfolders by file TYPE (Images, Documents, Audio, ...).
#
#  SAFETY (this is the whole point)
#    - NEVER deletes. It only MOVES files. Worst case is a file in the wrong
#      category folder, which --undo reverses.
#    - DRY-RUN BY DEFAULT: plain `./tidy.sh` only shows what it WOULD do.
#    - Only touches loose files at the TOP LEVEL of each target (no recursion),
#      so it never digs into your existing folders.
#    - Skips files modified in the last RECENT_HOURS (default 24h) so it won't
#      grab something you just downloaded and are actively using.
#    - Skips hidden/system files (.DS_Store etc.), folders, and aliases.
#    - Unknown file types are LEFT IN PLACE unless you pass --other.
#    - Every move is written to a manifest so `--undo` can put everything back.
#
#  USAGE
#    ./tidy.sh                 # DRY RUN: show the plan, change nothing
#    ./tidy.sh --plan          # same as above, explicit
#    ./tidy.sh --sort          # actually move files (writes an undo manifest)
#    ./tidy.sh --undo          # reverse the most recent --sort run
#    ./tidy.sh --other         # also corral unknown types into an "Other" folder
#    ./tidy.sh --recent-hours 6  # only move files older than 6 hours
#    ./tidy.sh --target ~/Downloads   # restrict to one folder (repeatable)
#    ./tidy.sh --help
# =============================================================================

set -u

# -----------------------------------------------------------------------------
#  CONFIG  —  edit to taste
# -----------------------------------------------------------------------------
# Folders to tidy. Add more lines if you like.
TARGETS=(
  "$HOME/Downloads"
  "$HOME/Desktop"
)

# Name of the single tidy folder created inside each target. Keeping everything
# under one folder means your Desktop/Downloads gain ONE folder, not ten.
SORTED="${TIDY_SORTED_DIRNAME:-Sorted}"

# Don't touch files newer than this many hours (protects active downloads).
RECENT_HOURS="${TIDY_RECENT_HOURS:-24}"

# Where undo manifests + logs are kept.
ORG_DIR="${TIDY_LOG_DIR:-$HOME/mac-tuneup/organizer}"

# -----------------------------------------------------------------------------
#  Argument parsing
# -----------------------------------------------------------------------------
MODE="plan"          # plan | sort | undo
INCLUDE_OTHER=0
CLI_TARGETS=()

while [ $# -gt 0 ]; do
  case "$1" in
    --plan)         MODE="plan" ;;
    --sort)         MODE="sort" ;;
    --undo)         MODE="undo" ;;
    --other)        INCLUDE_OTHER=1 ;;
    --recent-hours) shift; RECENT_HOURS="${1:-24}" ;;
    --target)       shift; [ -n "${1:-}" ] && CLI_TARGETS+=("$1") ;;
    -h|--help)      sed -n '2,40p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Unknown option: $1  (try --help)" >&2; exit 2 ;;
  esac
  shift
done

# If the user passed one or more --target, those override the config list.
[ "${#CLI_TARGETS[@]}" -gt 0 ] && TARGETS=("${CLI_TARGETS[@]}")

RECENT_MIN=$(( RECENT_HOURS * 60 ))
mkdir -p "$ORG_DIR" 2>/dev/null
TS="$(date '+%Y-%m-%d_%H%M%S')"
MANIFEST="$ORG_DIR/moves_$TS.tsv"
LATEST_MANIFEST="$ORG_DIR/moves_latest.tsv"
PLAN_FILE="$ORG_DIR/plan_$TS.txt"

# -----------------------------------------------------------------------------
#  Helpers
# -----------------------------------------------------------------------------
say() { printf '%s\n' "$*"; }

# categorize EXTENSION -> prints a category name, or "" for unknown.
categorize() {
  case "$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')" in
    jpg|jpeg|png|gif|heic|heif|webp|tiff|tif|bmp|svg|raw|cr2|nef|dng)  echo "Images" ;;
    pdf|doc|docx|txt|rtf|md|pages|odt|tex|epub|srt|htm)            echo "Documents" ;;
    xls|xlsx|csv|tsv|numbers)                                      echo "Spreadsheets" ;;
    ppt|pptx|key)                                                  echo "Presentations" ;;
    mp3|wav|aif|aiff|m4a|flac|aac|ogg|wma)                         echo "Audio" ;;
    mp4|mov|m4v|avi|mkv|webm|wmv|flv)                              echo "Video" ;;
    dmg|pkg)                                                       echo "Installers" ;;
    zip|tar|gz|tgz|bz2|xz|rar|7z)                                  echo "Archives" ;;
    js|ts|jsx|tsx|py|sh|rb|go|rs|c|h|cpp|hpp|java|json|html|css|php|swift|sql) echo "Code" ;;
    psd|ai|sketch|fig|xd|indd|eps)                                echo "Design" ;;
    *)                                                            echo "" ;;
  esac
}

# unique_dest DIR BASENAME -> prints a non-colliding full path (adds -1, -2, ...)
unique_dest() {
  local d="$1" b="$2" name ext cand n
  cand="$d/$b"
  [ ! -e "$cand" ] && { printf '%s' "$cand"; return; }
  case "$b" in
    *.*) name="${b%.*}"; ext=".${b##*.}" ;;
    *)   name="$b"; ext="" ;;
  esac
  n=1
  while :; do
    cand="$d/${name}-$n${ext}"
    [ ! -e "$cand" ] && { printf '%s' "$cand"; return; }
    n=$((n+1))
  done
}

# -----------------------------------------------------------------------------
#  UNDO  —  reverse the most recent --sort
# -----------------------------------------------------------------------------
if [ "$MODE" = "undo" ]; then
  if [ ! -f "$LATEST_MANIFEST" ]; then
    say "Nothing to undo: no manifest at $LATEST_MANIFEST"
    exit 1
  fi
  say "Undoing moves from: $LATEST_MANIFEST"
  restored=0; skipped=0
  # Each line is:  ORIGINAL_PATH <TAB> NEW_PATH
  while IFS="$(printf '\t')" read -r src dest; do
    [ -z "${src:-}" ] && continue
    if [ -e "$dest" ] && [ ! -e "$src" ]; then
      mkdir -p "$(dirname "$src")" 2>/dev/null
      if mv "$dest" "$src" 2>/dev/null; then
        say "restored: $(basename "$src")"
        restored=$((restored+1))
      else
        say "could not restore: $dest"
        skipped=$((skipped+1))
      fi
    else
      say "skip (source exists or moved file gone): $(basename "$dest")"
      skipped=$((skipped+1))
    fi
  done < "$LATEST_MANIFEST"
  say ""
  say "Undo complete. Restored: $restored  Skipped: $skipped"
  exit 0
fi

# -----------------------------------------------------------------------------
#  PLAN / SORT
# -----------------------------------------------------------------------------
if [ "$MODE" = "sort" ]; then
  : > "$MANIFEST"
  say "=== TIDY: SORTING (real moves)  $TS ==="
else
  : > "$PLAN_FILE"
  say "=== TIDY: DRY RUN (no changes)  $TS ==="
  say "    (run with --sort to actually move these files)"
fi
say "Targets: ${TARGETS[*]}"
say "Rule: leave files newer than ${RECENT_HOURS}h; never delete; one '$SORTED' folder per target."
say ""

moved=0; planned=0; left=0

for target in "${TARGETS[@]}"; do
  if [ ! -d "$target" ]; then
    say "skip (not found): $target"
    continue
  fi
  say "------ $target ------"
  # Top-level regular files only, older than the recent-window, NUL-delimited.
  while IFS= read -r -d '' f; do
    base="$(basename "$f")"
    case "$base" in .*) continue ;; esac          # skip hidden/system files
    # Determine extension (handle "no extension" cleanly).
    if [ "$base" = "${base##*.}" ]; then ext=""; else ext="${base##*.}"; fi
    cat="$(categorize "$ext")"
    if [ -z "$cat" ]; then
      if [ "$INCLUDE_OTHER" -eq 1 ] && [ -n "$ext" ]; then
        cat="Other"
      else
        say "leave  (unknown type): $base"
        left=$((left+1))
        continue
      fi
    fi
    destdir="$target/$SORTED/$cat"
    if [ "$MODE" = "sort" ]; then
      mkdir -p "$destdir" 2>/dev/null
      dest="$(unique_dest "$destdir" "$base")"
      if mv "$f" "$dest" 2>/dev/null; then
        printf '%s\t%s\n' "$f" "$dest" >> "$MANIFEST"
        say "move   $base  ->  $SORTED/$cat/"
        moved=$((moved+1))
      else
        say "FAILED to move: $base"
      fi
    else
      say "would move  $base  ->  $SORTED/$cat/"
      printf '%s\t%s/%s\n' "$f" "$SORTED/$cat" "$base" >> "$PLAN_FILE"
      planned=$((planned+1))
    fi
  done < <(find "$target" -maxdepth 1 -type f -mmin +"$RECENT_MIN" -print0 2>/dev/null)
  say ""
done

# -----------------------------------------------------------------------------
#  Summary
# -----------------------------------------------------------------------------
if [ "$MODE" = "sort" ]; then
  cp -f "$MANIFEST" "$LATEST_MANIFEST" 2>/dev/null
  say "Done. Moved: $moved   Left in place (unknown type): $left"
  say "Undo this run any time with:   $0 --undo"
  say "Manifest: $MANIFEST"
else
  say "Plan only. Would move: $planned   Would leave: $left"
  say "Nothing was changed. Re-run with --sort to apply."
  say "Plan saved: $PLAN_FILE"
fi
exit 0
