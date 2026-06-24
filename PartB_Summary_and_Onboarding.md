# Part B — Summary, Testing Notes & Onboarding Plan

---

## What Was Broken

The sample had 7 documented bugs across two functions:

**Location permission flow (`useCurrentLocation`):**

1. **No location-services check** — the app went straight to `checkPermission` without first calling `isLocationServiceEnabled()`. On a device with GPS off, this would attempt to get position and either hang or throw.
2. **`denied` permission not re-requested** — the code treated `denied` and `deniedForever` identically and returned immediately. The correct flow on `denied` is to call `requestPermission()` to show the native OS prompt.
3. **`denied` and `deniedForever` treated the same** — `deniedForever` requires sending the user to app settings; `denied` just needs a permission request. Collapsing both into one branch makes the correct UX impossible.
4. **`isLocating` not reset on early return paths** — every early return (no service, denied, deniedForever) left `isLocating = true`, permanently disabling the button and keeping the label stuck on "Locating...".
5. **No `mounted` checks after async gaps** — `setState`, `showDialog`, and navigation calls were made after `await` without checking `if (!mounted) return`, risking "setState called on dead widget" crashes after the widget is disposed mid-async.

**Filter logic (`filteredBusinesses`):**

6. **Verified filter fell back to the full demo list** — `list = verified.isNotEmpty ? verified : demoBusinesses`. If no businesses matched the verified flag, it showed all 5 businesses instead of 0. A user filtering for "Verified only" with zero matches should see an empty state.
7. **Distance filter fell back to the full demo list** — same pattern. `list = nearby.isNotEmpty ? nearby : demoBusinesses`. Zero-nearby-match should show 0 results, not everything.

Additionally, both filter fallbacks used `demoBusinesses` (the full unfiltered source) instead of `list` (the already-filtered subset), meaning combining multiple active filters would silently drop upstream filters.

---

## What I Changed

**`useCurrentLocation`:**
- Added `Geolocator.isLocationServiceEnabled()` check at the top; shows a clear message and resets `isLocating` if disabled.
- On `denied`: call `Geolocator.requestPermission()` to trigger the native OS prompt. If still `denied` after, reset `isLocating` and show a message.
- On `deniedForever`: reset `isLocating`, then show an `AlertDialog` with a "Open Settings" button that calls `Geolocator.openAppSettings()`.
- Added `if (!mounted) return` after every `await` before any `setState`, `showDialog`, or navigation call.
- Every early return path now resets `isLocating = false`, so the button is never permanently disabled.

**`filteredBusinesses`:**
- Start from `List<Business>.from(demoBusinesses)` at the top so filters compose correctly.
- Removed both fallbacks entirely. Filters are now strict: `list = list.where(...).toList()` with no `isNotEmpty` guard.
- The result: combining category + verified + distance yields only businesses that satisfy all three conditions. Zero results shows zero results.

No packages were added. No UI was redesigned. The `build` method and widget structure are unchanged.

---

## Testing Notes

**iOS:**
- Run on a real device (simulator has limited location behavior).
- Test with location services **off** in Settings → Privacy → Location Services: should show "Location services are disabled" message immediately, button re-enabled.
- Test with app permission **not yet granted**: tap button, native iOS prompt appears, deny it → message shown, not stuck. Grant it → location loads.
- Test after denying twice (iOS moves to "denied forever"): tap button → AlertDialog with "Open Settings" appears → tap it → iOS Settings opens to app permissions page.
- Test all filter combinations from `filter_logic_notes.md` cases 1–8.

**Android:**
- Run on a real device or emulator with Google Play Services.
- Test with GPS **off** in Settings → Location: should show "Location services are disabled" message.
- Test "Deny" on first permission prompt → message shown, not stuck.
- Test "Deny & don't ask again" (Android's deniedForever): AlertDialog with "Open Settings" appears.
- Test `minSdkVersion` compatibility — `Geolocator.openAppSettings()` requires Android 5.0+ which matches typical Flutter targets.
- On Android 12+ check that the permission dialog shows correctly (coarse vs. fine location).

**Filter test matrix (both platforms):**

| Category | Verified | Location | Expected result |
|----------|----------|----------|----------------|
| All | off | off | All 5 businesses |
| Restaurant | off | off | Harlem Coffee Bar, Bronx Vegan Kitchen |
| Services | verified | off | 0 results (Queens Fitness is not verified) |
| Retail | verified | off | Brooklyn Books only |
| Restaurant | verified | 1 mi | Harlem Coffee Bar only |
| Restaurant | verified | 1 mi (no match data) | 0 results, not all businesses |

---

## Safe Onboarding Plan for Production Repo

### Branch Process
- Never commit directly to `main`. Work on `feat/`, `fix/`, or `chore/` branches cut from `main`.
- PR into `main` only — no long-lived feature branches that diverge for weeks.
- Branch naming: `feat/TICKET-description`, e.g. `feat/GSB-42-maps-integration`.
- Require at least one approval from the repo owner before merge.

### Secrets / Environment Variables
- On first access, ask for a `.env.example` or equivalent — never request actual secrets.
- Store secrets in `.env` files locally (already in `.gitignore`) and in the CI/CD secrets vault (GitHub Actions Secrets or equivalent).
- Do not hardcode API keys, Supabase URLs, or map API keys in any committed file.
- Confirm which flavor/scheme is used for dev vs. production before touching any build config.

### Build Setup
- Clone repo, run `flutter pub get`, confirm the app builds with `flutter run` before touching any code.
- Identify if there are multiple flavors (dev/staging/prod) — use the right one for testing.
- Do not modify `android/app/build.gradle`, `ios/Runner.xcodeproj`, or Podfile without explicit discussion.
- Confirm minimum SDK versions and target SDK for both platforms.

### iOS / Android Testing
- All PRs are tested on a real device (not just simulator/emulator) for any feature that touches camera, location, permissions, or push notifications.
- Before submitting a PR, run a release-mode build (`flutter build apk --release`, `flutter build ios --release`) to catch any tree-shaking or obfuscation issues.
- Screen-record the feature on both platforms and include the recording in the PR description.

### PR Process
- PR description includes: what changed, why, how to test, and screenshots or recordings.
- No demo/debug code, `print()` statements, commented-out dead code, or TODO comments in PRs.
- Keep PRs focused — one feature or one bug fix per PR.
- Self-review the diff before requesting review.

### Rollback Plan
- Every PR that changes backend-integrated behavior is feature-flagged or behind a backend toggle where possible.
- If a bad build reaches production, revert the PR via `git revert` and create a hotfix PR — do not force-push to `main`.
- Keep release tags on `main` so any previous version can be rebuilt and resubmitted.

### First 48-Hour Audit Checklist
- [ ] Build runs cleanly on iOS and Android in debug and release mode.
- [ ] Confirm `.env` setup and all required keys are documented (but not shared publicly).
- [ ] Read all open PRs and issues to understand what's in flight.
- [ ] Confirm Supabase schema: review tables, RLS policies, and any migrations before writing queries.
- [ ] Review `pubspec.yaml` — identify any outdated or conflicting packages.
- [ ] Confirm branch protection rules are in place on `main`.
- [ ] Run the app end-to-end: signup → browse → filter → business detail — note any existing crashes or broken flows.
- [ ] Review any TODO/FIXME comments in the codebase — understand known debt before touching adjacent code.
- [ ] Confirm CI (GitHub Actions or equivalent) runs and passes on the current `main`.
- [ ] Ask what the current launch blockers are — prioritize those before anything else.
