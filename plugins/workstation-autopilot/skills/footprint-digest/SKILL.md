---
name: footprint-digest
description: >-
  Re-run the footprint-audit on a cadence and report ONLY the change — what came
  back, what's newly exposed, and what's now clear — so you can tell whether your
  removals are sticking. Read-only; performs no removals. Use when the user asks
  to "run my footprint digest", "re-scan my footprint", "what came back",
  "did my removals stick", "recheck the data brokers", "quarterly footprint
  check", or wants to schedule a recurring exposure re-scan. Pairs with (and runs)
  footprint-audit; defaults to a quarterly cadence. NOT for the first/baseline
  scan (use footprint-audit) and never touches legal/custody material.
---

# footprint-digest — scheduled re-scan, change-only report

You answer one question on a cadence: **"What changed in my online exposure since
last time?"** Data brokers re-list within 3–6 months of any opt-out, so a footprint
is maintained, not cleaned once. This module re-runs the audit and reports the
*delta* — with re-listings front and center. Same ethos as `mac-tuneup`'s digest:
**read-only, report-first, never acts.**

## Hard guardrails (inherit footprint-audit's)

- **Read-only, always.** No opt-outs, no logins, no account creation.
- **Confidence honesty** (confirmed vs. possible). **Legal wall — absolute**: use
  only the user's `~/footprint/config/config.md`; never read connected folders for
  personal data or reference legal/custody material.
- **Personal ≠ professional**: honor the config's protect/keep split.

## Step 1 — Preconditions

1. Require `~/footprint/config/config.md`. If missing, run the footprint-audit
   setup first (`footprint-setup.sh`) and ask the user to fill it.
2. Require at least one prior report in `~/footprint/reports/` (a
   `footprint-audit_*.md` baseline, or an earlier `footprint-digest_*.md`). If
   there is none, there's nothing to diff — run **footprint-audit** for the
   baseline instead and say so.

## Step 2 — Run a fresh scan

Run the same three passes as `footprint-audit` (people-search/broker listings,
search-index hits, breach paste-check), using the bundled seed list at
`${CLAUDE_PLUGIN_ROOT}/skills/footprint-audit/data/people-search-sites.tsv`.
Verify opt-out URLs live; don't trust stale ones.

## Step 3 — Diff against the most recent prior report

Load the newest prior report in `~/footprint/reports/` and compare exposures
(match on site + what's exposed). Classify every finding into exactly one bucket:

- **⚠️ Came back (re-listed)** — was absent/removed in the prior report, present
  now. This is the headline; brokers re-scrape public records. List these first.
- **Still exposed** — present then and now (no movement).
- **🔴 Newly exposed** — never seen before (a new broker, a new breach, a new
  public-record surfacing).
- **✅ Now clear** — present before, gone now (a removal that's holding — or a
  listing that simply rotated out).

## Step 4 — Write the digest

Write `~/footprint/reports/footprint-digest_<YYYY-MM-DD>.md`, bottom-line first:

1. **Headline** — e.g. "3 listings came back, 1 newly exposed, 2 now clear since
   2026-02-14." Name the prior report it's comparing against.
2. **Came back / Newly exposed (act on these)** — table: site · what's exposed ·
   listing URL · opt-out URL · confidence. These go to the removal service.
3. **Now clear (good news)** — what's holding, so the user sees the wins.
4. **Still exposed** — the steady-state list, condensed.
5. **Next actions** — hand re-listings to the removal service; re-file
   source-level suppression if a public record re-surfaced; re-run next quarter.

End with the footprint-audit closing line verbatim: *"This tool measured your
exposure; it did not act. Hand the opt-out URLs to your removal service, or file
them yourself."* Then give a tight chat summary + the saved path.

## Scheduling — make it recurring

This module is built to run on a schedule (the operational layer). It does NOT use
a launchd plist — the scan needs Claude's web tools, so the right mechanism is a
**Cowork scheduled task** that invokes this skill, mirroring the existing
`mac-tuneup-evening-digest` task.

- **Default cadence: quarterly** — matches the 3–6-month broker re-listing floor;
  low-noise. Suggested cron: `0 9 1 1,4,7,10 *` (9 AM on Jan/Apr/Jul/Oct 1).
- **Monthly** if the user is actively suppressing and wants a tighter loop.
- Only create the schedule **after** the config is filled and a baseline
  footprint-audit exists — otherwise the first run has nothing to scan or diff.
  Offer to set it up; don't create it prematurely.

## Sets up removal-verifier

The next module, `removal-verifier`, is this diff pointed at a paid service's
*reported* removals: ingest what the service claims it removed, run a fresh scan,
and flag anything it missed or that re-appeared. Trust-but-verify.
