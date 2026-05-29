---
name: footprint-audit
description: >-
  Read-only "where am I exposed online" audit. Produces a scannable report of
  people-search / data-broker listings, search-engine hits, and breach exposure
  for a person — with opt-out links — and performs NO removals and NO logins.
  Use when the user asks to "audit my footprint", "where am I exposed online",
  "check data brokers", "am I on Whitepages/Spokeo/BeenVerified", "scan my online
  exposure", "people-search audit", "what's leaking my address/phone", or wants a
  baseline before (or to verify) a paid removal service like Optery/DeleteMe.
  Complements a removal service; does not replace it. Reports only — never acts.
  NOT for local Mac cleanup (use mac-tuneup) or file sorting (use file-organizer),
  and never touches the user's legal/custody material.
---

# footprint-audit — read-only online-exposure report

You produce a forensic, scannable report of where a person's personal data is
exposed online: data-broker / people-search listings, search-engine results, and
known credential breaches. The guiding rule for everything below, mirroring
`mac-tuneup`'s stance: **you measure and report; you never act.** No opt-out is
submitted, no account is created, nothing is logged into. The report hands the
user (and/or their removal service) the links to act on themselves.

The user (Casey) holds a forensic bar: cite every exposure with the URL you found
it at, tag confidence honestly (confirmed vs. possible match), and flag
uncertainty instead of papering over it.

## Hard guardrails — do not violate

- **Read-only, always.** Never submit an opt-out, fill a removal form, create an
  account, or log in. If viewing a listing requires a login, record
  "login-gated, not checked" — do not authenticate.
- **No scraping of paywalled/gated detail pages** beyond what's publicly visible.
- **Confidence honesty.** Common-name false positives get a "possible match" tag,
  never "confirmed." Say when you're unsure.
- **Legal wall — absolute.** Use ONLY the inputs the user types into their
  config. Never read the user's connected folders for personal data, and never
  reference any legal / custody / financial material. If a request would pull
  from those, stop and ask.
- **Personal ≠ professional.** Honor the config's "protect" vs. "keep" split —
  don't flag wanted business visibility (Afters DJs, the YouTube channel) as a
  problem.

## Step 0 — Make sure setup exists

The audit needs a small local config and a home for reports. Both live in
`~/footprint/` (mirrors the `~/mac-tuneup/` pattern; git-ignored, never in any
repo).

1. If `~/footprint/config/config.md` does not exist, run the bundled setup:
   `bash "${CLAUDE_PLUGIN_ROOT}/skills/footprint-audit/scripts/footprint-setup.sh"`
   It creates `~/footprint/{reports,config}` and a `config.example.md` template,
   then copies it to `config.md` for the user to fill. It is safe and idempotent.
2. Ask the user to fill `~/footprint/config/config.md` (names/aliases, city+state,
   emails, phones, and the **protect** vs. **keep** identity split). Read it back
   and confirm before scanning. Infer nothing the user didn't provide.

## Step 1 — Run the three passes

Use your own web/search tools (and Chrome tools when a page needs rendering).
Work from the bundled seed list at
`${CLAUDE_PLUGIN_ROOT}/skills/footprint-audit/data/people-search-sites.tsv` —
but treat it as a *starting point*: opt-out URLs drift, so verify the current
opt-out URL by a quick search at run time rather than trusting the seed blindly.

**Pass 1 — People-search / broker listings.** For each site on the seed list,
look for a listing matching the config's name + city. Record: site, the listing
URL, which protected fields are exposed (address? phone? relatives? age?), the
current opt-out URL, and a confirmed/possible confidence tag. Skip login-gated
sites with a note.

**Pass 2 — Search-index hits.** Run name+city, and name+phone, through web search.
Capture the top results that expose protected fields, and cross-reference: note
when a broker listing from Pass 1 is *also* surfacing in Google/Bing (that's the
"the link lingers even after opt-out" case). Always point the user to
**goo.gle/resultsaboutyou** for direct search-index removal requests.

**Pass 3 — Breach exposure (free, paste-based).** Do NOT attempt automated
email-breach lookups (HIBP's by-email API is paid/gated). Instead, instruct the
user to check each email at **haveibeenpwned.com** (safe; checking is free and the
password flow is k-anonymous) and paste the results back. Then summarize which
emails appear in which breaches and what data class leaked. Recommend turning on
HIBP's free breach alerts.

## Step 2 — Write the report

Write `~/footprint/reports/footprint-audit_<YYYY-MM-DD>.md`, structured for an
ADHD-aware skim:

1. **Summary line / exposure score** — e.g. "Protected data found on 11 of 18
   sites checked; home address exposed on 6; 2 breached emails."
2. **Protected-data hits (act on these)** — table: site · what's exposed ·
   listing URL · opt-out URL · confidence.
3. **Search-index hits** — the Google/Bing results surfacing protected data, with
   the goo.gle/resultsaboutyou pointer.
4. **Breach hits** — which emails, which breaches, what leaked.
5. **Kept / expected (no action)** — business listings that are *supposed* to be
   findable, listed separately so they aren't mistaken for problems.
6. **Next actions** — concrete, ordered: Google Results-about-you, source-level
   suppression, hand opt-out URLs to the removal service or file them yourself.

End the report with this line verbatim: *"This tool measured your exposure; it did
not act. Hand the opt-out URLs to your removal service, or file them yourself."*

Then give the user a tight chat summary (bottom line first) and the path to the
saved report. Do not perform any removal.

## How this feeds the next modules

- **footprint-digest** = this audit on a schedule (reuse the `mac-tuneup`
  evening-digest / launchd plumbing). Default cadence **quarterly** (the 3–6-month
  broker re-listing floor); monthly if the user is actively suppressing. It flags
  *what came back*.
- **removal-verifier** = diff a paid service's reported removals against a fresh
  audit; flag listings the service missed or that re-appeared. Trust-but-verify.

## Reference

- Seed site list: `scripts/../data/people-search-sites.tsv` (site · domain ·
  opt-out URL · typical exposed fields). Verify URLs live; expand over time.
- Setup helper: `scripts/footprint-setup.sh` (creates `~/footprint/`, scaffolds
  config). Background and the BMP rationale live in the user's project docs
  (`WEBFOOT_Online-Footprint-BMP-Brief.md`).
- Not legal advice. Eligibility-gated tools (e.g. Michigan ACP) are flagged for
  the user to confirm with an advocate, never assumed.
