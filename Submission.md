# PR119 — Location Filter Screen Fix Submission

## Deliverables

| Item | Status |
|---|---|
| Fixed file (`new_screen.dart`) | ✅ |
| Summary of what was broken | ✅ |
| Summary of what was changed | ✅ |
| Testing notes — iOS & Android | ✅ |
| Screen recording (real Android device) | ✅ |
| Safe onboarding plan | ✅ |

---

## What Was Fixed

Two areas, 7 bugs total. No UI redesign, no new packages, no scope creep.

### 1. Location Permission Flow

The original `useCurrentLocation()` had 5 bugs:

- No location services check — called `checkPermission` before verifying GPS was on
- Never requested permission — on `denied`, it just returned instead of calling `requestPermission()`
- `denied` and `deniedForever` treated identically — `deniedForever` requires an Open Settings dialog, not a simple message
- `isLocating` never reset on early exits — button stayed permanently stuck on "Locating..."
- No `mounted` checks after async gaps — `setState` and `showDialog` were called on potentially disposed widgets

**Fixed:** service check first → request on denied → separate deniedForever dialog with Open Settings → `isLocating` reset on every exit path → `if (!mounted) return` after every `await`.

### 2. Filter Logic

The original `filteredBusinesses` had 2 bugs:

- Verified filter fell back to the full list when empty — `verified.isNotEmpty ? verified : demoBusinesses`
- Distance filter fell back to the full list when empty — same pattern

Both fallbacks also used `demoBusinesses` (unfiltered source) instead of the already-filtered `list`, silently dropping upstream filters when combined.

**Fixed:** Both fallbacks removed entirely. Filters are now strict — zero matches returns zero results. Filters chain correctly on a fresh copy of the list.

---

## Tested On

**Real device:** Vivo V2403, Android 16 (API 36)

Scenarios verified:
- Location services off → clear message, button resets
- First-time permission prompt → OS dialog appears
- Permission denied → message shown, not stuck
- Permission denied forever → AlertDialog with Open Settings
- Permission granted → coordinates load, distance filter activates
- Services + Verified only → 0 results (correct)
- Retail + 1 mi distance → 0 results (correct)
- Restaurant + Verified + 1 mi → 1 result only (Harlem Coffee Bar)

---

## Files

- `new_screen.dart` — fixed screen (drop-in replacement)
- `Fix_Summary_and_Testing_Notes.md` — detailed bug breakdown + iOS/Android test matrix
- `PartB_Summary_and_Onboarding.md` — onboarding plan including branch process, secrets, build setup, PR process, rollback plan, and 48-hour audit checklist
- Screen recording attached separately
