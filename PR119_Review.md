# PR #119 Code Review — GoShopBlack
**Feature:** Ownership badges on business cards + detail screen + filter UI  
**Reviewer decision:** ⚠️ REQUEST CHANGES — do not merge until blockers and highs are resolved.

---

## Summary

The PR adds a well-scoped feature: a new `badgeLevel` field on the `Business` model, an `OwnershipBadge` widget, filter UI chips in `FilterScreen`, and propagation of `ownershipFilter` through the repository layer to the API. The structure is clean, the new `OwnershipBadge` widget is defensive (handles nulls and unknown values with `SizedBox.shrink()`), and the filter screen refactor is a net improvement.

However, there is a real filter-logic defect that silently misleads users, an unverified client/server data contract, a product logic bug in the "51%+" filter, zero tests, and a large unrelated reformat bundled into the same commit. None of these is safe for a production release of a trust/verification feature.

All findings are based only on what is visible in the PR diff. Where the diff alone is insufficient to confirm something, it is flagged as a pre-merge question rather than a hard finding.

---

## Prioritized Issue List

### 🔴 BLOCKER

#### Issue #1 — Ownership filter silently falls back to unfiltered results
**File:** `lib/views/business_list_screen.dart` (lines ~395–399 in diff)

**Observed code:**
```dart
if (widget.filter.ownershipFilter != null) {
  final filtered = list.where(
    (b) => b.badgeLevel == _ownershipBadgeForFilter(widget.filter.ownershipFilter!)
  ).toList();
  if (filtered.isNotEmpty) list = filtered; // ← BUG: silently no-ops when empty
}
```

**Risk:** When the ownership filter matches zero businesses, `filtered` is empty, the `if` is skipped, and `list` stays as the full unfiltered set. The user selects "100% Black-Owned," sees a screen full of businesses, and reasonably assumes they are all 100% Black-Owned. For a feature whose entire purpose is ownership verification, this is a trust-breaking correctness bug, not a cosmetic one.

**Expected behavior:** Zero matches should render an empty state, not fall back to everything.

**Fix:**
```dart
if (widget.filter.ownershipFilter != null) {
  list = list.where(
    (b) => b.badgeLevel == _ownershipBadgeForFilter(widget.filter.ownershipFilter!)
  ).toList();
  // No fallback. Zero results is correct and honest.
}
```
Also ensure the list view has a proper empty state widget.

---

### 🟠 HIGH

#### Issue #2 — "51%+" filter excludes 100%-owned businesses
**File:** `lib/views/business_list_screen.dart` — `_ownershipBadgeForFilter()`

**Observed code:**
```dart
case 'majority_51': return 'majority_badge';
case 'full_100':    return 'full_badge';
```

The local filter uses exact equality — `b.badgeLevel == _ownershipBadgeForFilter(...)`. This means a business with `full_badge` (100% Black-Owned) will NOT appear when the user selects "51%+ Black-Owned," even though 100% ownership logically satisfies a 51%+ threshold.

**Risk:** The label "51%+" strongly implies inclusivity. The code enforces mutual exclusivity. A user filtering for "51%+" expects to see all Black-owned businesses at or above that threshold — including 100% owned ones. The current logic hides them.

**Expected behavior:** "51%+" should match both `majority_badge` and `full_badge`. "100%" should match only `full_badge`.

**Fix:**
```dart
bool _matchesOwnership(Business b, String filter) {
  switch (filter) {
    case 'majority_51':
      return b.badgeLevel == 'majority_badge' || b.badgeLevel == 'full_badge';
    case 'full_100':
      return b.badgeLevel == 'full_badge';
    default:
      return true;
  }
}
```
If the product intends exclusive buckets, confirm this — but the current label strongly implies the inclusive reading.

#### Issue #3 — Unverified two-vocabulary data contract
**Files:** `api_res.dart`, `business_list_screen.dart`, `ownership_badge.dart`, `categories_model.dart`

Two different string vocabularies are in play and the whole feature depends on the server bridging them correctly:
- Filter → server param values: `majority_51`, `full_100`
- Badge rendering + local filter match: `majority_badge`, `full_badge` (from API `badge_level`)

`OwnershipBadge` only renders for `majority_badge`/`full_badge`, and the local filter only matches those. If the backend returns `badge_level` in the filter vocabulary (`majority_51`/`full_100`) or anything else, badges silently don't render and the local filter matches nothing — which then triggers Issue #1.

Nothing in this diff confirms what `badge_level` actually contains. See Pre-Merge Question #1.

**Fix:** Confirm the exact `badge_level` strings the API returns and align all switch/match logic to them. Centralize as an enum or constants so badge rendering and filtering cannot drift independently.

#### Issue #4 — Redundant client-side filtering on top of server-side filtering
**Files:** `api_res.dart` (sends `ownership_filter`), `business_list_screen.dart` (filters again locally)

The ownership filter is sent to the backend as a query param AND re-applied locally on the results that come back. This creates two sources of truth. On a paginated list this is especially fragile — local filtering only sees the currently loaded page, so result counts and "load more" behavior can disagree with what the server returned. Combined with Issue #1, the local pass can also silently override a correct server response.

**Fix:** Decide where filtering lives. If the server is authoritative (recommended for pagination), remove the local filter. If the client is authoritative, stop sending the param. Do not do both.

---

### 🟡 MEDIUM

#### Issue #5 — `badgeLevel` not added to `Business.toJson()`
**File:** `lib/models/categories/categories_model.dart`

`badgeLevel` is added to the field, constructor, and `fromJson` — but the visible `toJson()` was not updated to include `"badge_level": badgeLevel`. If `Business` is serialized anywhere (local cache, shared preferences), the badge level is lost on round-trip and badge display disappears after reload.

The diff shows only 3 added lines for this file, confirming `toJson()` was not touched. Confirm whether `Business.toJson()` is used for local caching — if so, add `"badge_level": badgeLevel`.

#### Issue #6 — Large unrelated reformat bundled with the feature
**File:** `lib/views/filter_screen.dart` (+287 / −424, single commit)

The majority of this file's diff is whitespace reformatting and deletion of large commented-out blocks, not the ownership feature itself. Mixing a ~700-line reshuffle with the feature in one commit makes the actual feature change very hard to review and raises regression risk. The Distance and Open Now widgets were moved under `if (_localBusiness) ...[]` which appears behavior-preserving, but verifying every moved widget by eye is error-prone.

**Recommendation:** Split the cleanup into its own PR.

#### Issue #7 — `ownershipFilter` cannot be cleared via `SearchFilter.copyWith`
**File:** `lib/models/search_filter/search_filter.dart`

```dart
ownershipFilter: ownershipFilter ?? this.ownershipFilter,
```

Calling `filter.copyWith(ownershipFilter: null)` will silently retain the existing value due to the `??` operator. The current `_clearAll` flow avoids this by building a fresh `SearchFilter()`, so it is not broken today — but any future code path that tries to reset via `copyWith` will silently fail.

**Fix:**
```dart
bool clearOwnershipFilter = false,
...
ownershipFilter: clearOwnershipFilter ? null : (ownershipFilter ?? this.ownershipFilter),
```

#### Issue #8 — `_ownershipBadgeForFilter` is misplaced
**File:** `lib/views/business_list_screen.dart`

This function defines what badge level strings mean, but `OwnershipBadge` independently defines the same mapping in its own switch statement. Two separate places define the same contract. If a new badge type is added, both files must be updated in sync with no compiler enforcement.

**Fix:** Move the mapping to `OwnershipBadge` as a static method or to a shared constants file.

#### Issue #9 — No tests
The PR adds non-trivial filter logic, a product logic mapping function, and a new model field with zero unit tests or widget tests. The export shows Checks 0, Reviews 0. At minimum, `_ownershipBadgeForFilter`, the filter combination logic, and `OwnershipBadge` rendering should have tests — exactly the logic that is wrong in Issues #1 and #2.

---

### 🔵 LOW

#### Issue #10 — `// AFTER` comment left in production code
**File:** `lib/views/business_details_screen.dart`

```dart
// AFTER
Text(
  overflow: TextOverflow.ellipsis,
```

Leftover dev note. Clean up before merge.

#### Issue #11 — 4px spacer renders even when badge value is unrecognized
**File:** `lib/views/business_details_screen.dart`

```dart
if (widget.business.badgeLevel != null) ...[
  const SizedBox(height: 4),
  OwnershipBadge(badgeLevel: widget.business.badgeLevel),
],
```

If `badgeLevel` is non-null but unrecognized, `OwnershipBadge` returns `SizedBox.shrink()` correctly — but the 4px `SizedBox` above it still renders, leaving an invisible gap. Cosmetic only.

#### Issue #12 — `ownership_filter` value not URL-encoded
**File:** `api_res.dart`

```dart
final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
```

Pre-existing pattern not introduced by this PR. The new values are fixed enums (`majority_51`, `full_100`) so it is safe in practice, but the param inherits the existing no-encoding behavior. Worth noting for future params that may contain special characters.

#### Issue #13 — Trailing whitespace in `marketplace_small_card.dart`
Line 26 in the diff has a trailing space after `favoriteIcon;`. Minor, but combined with the `// AFTER` comment suggests the diff was not self-reviewed before submission.

#### Issue #14 — `OwnershipBadge` uses hardcoded hex colors
**File:** `lib/widgets/ownership_badge.dart`

```dart
const Color(0xFF1B5E20)  // majority badge
const Color(0xFF4A148C)  // full badge
```

Hardcoded colors will not adapt to dark mode or theme changes. Low priority if dark mode is not yet in scope, but worth tracking.

#### Issue #15 — Filename typo in repository file
`categories_reposiory.dart` is missing the `t` in "repository." Pre-existing and not introduced by this PR, but easy to fix while here.

---

## Test Plan

Before approving this PR, verify the following on a real build (both iOS and Android). Include a screen recording of each filter combination:

**Ownership badge display:**
1. Open a business list with businesses that have `badge_level` set — confirm the correct badge (`51%+` or `100%`) appears overlaid on the card image at top-left.
2. Open a business with no `badge_level` — confirm no badge and no extra spacing renders.
3. Open the business detail screen for a badged business — confirm the badge renders below the business name with correct text and color.
4. Test dark mode — confirm badge colors are readable.

**Ownership filter:**
1. Select "51%+ Black-Owned" → confirm both `majority_badge` AND `full_badge` businesses appear (inclusive filter).
2. Select "100% Black-Owned" → confirm only `full_badge` businesses appear.
3. Select an ownership tier where zero results exist → confirm the list shows zero results and an empty state — not all businesses.
4. Select "Any" → confirm all businesses appear regardless of badge.
5. Combine ownership filter + category filter → confirm both filters apply strictly (AND logic, not OR).
6. Apply ownership filter → tap "Clear All" → confirm filter resets and all businesses are shown.
7. Navigate away and back — confirm filter state persists correctly via `SearchFilter`.
8. Enable pagination / scroll to load more → confirm ownership filter applies consistently across pages, not just the first page.

---

## Pre-Merge Questions

1. **What values does the backend API return for `badge_level`?** Does it return `"majority_badge"` / `"full_badge"`, or `"majority_51"` / `"full_100"`, or something else? The local filter and `OwnershipBadge` rendering depend on this being `majority_badge`/`full_badge` — if the API returns anything else, badges silently don't render and the local filter matches nothing.

2. **Does the backend `ownership_filter` query param currently work in production?** The PR wires it up but there is no evidence the API supports it yet. If not supported, the local filter is the only mechanism — which makes Issues #1, #2, and #3 even more critical.

3. **What is `all` initialized to in the distance filter block?** In the existing code `list = distanceFiltered.isNotEmpty ? distanceFiltered : all` — is `all` the completely unfiltered business list, or is it already a filtered subset? This determines whether the distance fallback is a separate bug or an acceptable behavior. If `all` is the full unfiltered list, the fallback should be removed.

4. **Is "51%+" intended to be inclusive of 100%-owned businesses?** The current code treats the two ownership tiers as mutually exclusive buckets. The label implies inclusivity. Confirm the intended product behavior before fixing Issue #2.

5. **Is `Business.toJson()` used for local caching anywhere?** If yes, `badge_level` must be added to `toJson()` to prevent badge data loss on round-trip.
