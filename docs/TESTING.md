# Roost — Device Test Plan

An exhaustive checklist for testing the Flutter app on a real Android phone (built
and verified on a **Solana Seeker, Android 16 / API 36**). Work top to bottom.

Tags: **[Live]** needs the backend · **[Demo]** offline · **[Device]** hardware/OS
behaviour · **[Edge]** failure/edge case.

> **Two modes.** The app ships **live by default** (talks to the deployed API).
> For a guaranteed-instant, offline run use demo mode:
> ```bash
> flutter run -d <deviceId>                                 # LIVE
> flutter run -d <deviceId> --dart-define=USE_DEMO_DATA=true # DEMO (offline)
> ```
> **Warm the backend first** for live tests — the free tier sleeps and the first
> request cold-starts ~60–90s. Open
> `https://futo-hostel-reservation-backend.onrender.com/api/docs` in a browser and
> wait for it to load before your first login, or the sign-in spinner will sit for
> up to ~90s (that is expected, not a hang).

---

## 0. Build & launch

- [ ] `flutter devices` lists the phone.
- [ ] App installs and launches with **no white screen / crash** on cold start.
- [ ] App icon + name look right in the launcher.
- [ ] Portrait orientation is **locked** (rotating the phone doesn't rotate the UI).
- [ ] Status bar + system nav bar are tinted correctly in **light** (default).

## 1. Onboarding & auth — FR1–FR3

**Validation (both modes):**
- [ ] Empty / malformed identifier → inline error, no navigation.
- [ ] Bad reg number (not 11 digits) and bad email format → error.
- [ ] Password < 8 chars, or missing a letter, or missing a number → error.
- [ ] Sign-up sheet: mismatched confirm password → error.

**[Live] Register:**
- [ ] Create a **new** account (e.g. `20219999999` / `futo2026`) → lands on Browse.
- [ ] Kill & reopen the app → still need to sign in (no auto-login) — expected.

**[Live] Sign in:**
- [ ] Sign in with the account you just created → Browse.
- [ ] Sign-in button shows a **spinner** while it works (esp. during cold start).
- [ ] [Edge] Wrong password → friendly error ("Wrong credentials…"), no crash.
- [ ] [Edge] Airplane mode on → sign in → "Could not reach the server…" message.

**[Device] Biometric — FR3:**
- [ ] Fresh install, tap **Use Face ID / Fingerprint** before any sign-in → message
      telling you to sign in with a password once first.
- [ ] After a successful password sign-in, kill the app, reopen, tap biometric →
      fingerprint prompt → unlocks straight to Browse (session restored).
- [ ] [Edge] Cancel/fail the fingerprint prompt → stays on onboarding, no crash.
- [ ] [Device] Phone with **no fingerprint enrolled** → biometric path degrades
      gracefully (no crash).

**[Demo]:**
- [ ] Any format-valid reg/email + valid password signs in **instantly**, offline.

## 2. Browse — FR4–FR5

- [ ] All **8 hostels** render (A–E, TETFund, NDDC, PG) with cover, gender, price,
      availability pill. **[Live]** from the server, **[Demo]** from static data.
- [ ] Search by **name** (`NDDC`, `TET`, `PG`, `Hostel A`) filters live as you type.
- [ ] Search by **funder** (`School`, `TETFund`, `NDDC`) works.
- [ ] Filter chips: **All / Male / Female / Mixed / Available** each filter correctly.
- [ ] A search with no matches shows the **empty state**.
- [ ] Cards are tappable → open detail.
- [ ] [Live] Availability numbers match what the backend returns.

## 3. Hostel detail — FR6

- [ ] Cover gradient + status pill, name, `gender · roomSize`, price, blurb.
- [ ] **View on map** opens Google Maps at the hostel's coordinates.
- [ ] Availability hero shows `X of Y beds open` + progress bar.
- [ ] Rooms list: each room shows capacity + beds open + status pill.
- [ ] **CTA logic:**
  - [ ] A **full** hostel (e.g. Hostel E in demo) → **"Fully booked"** (disabled).
  - [ ] With **no** active booking → **"Reserve a bed"**.
  - [ ] After you have an active booking → **"View my booking"** (jumps to Bookings).

## 4. Reserve + pay — FR7–FR9

- [ ] Step 1: pick a room; rooms with **0 beds are disabled**.
- [ ] Step 2: bed grid shows `capacity` beds; **taken beds are greyed** and
      untappable. **[Live]** taken beds come from the server (`occupiedBeds`).
- [ ] Fee summary shows hostel / room / bed and **Total = hostel price**.
- [ ] **Pay** → button shows "Processing…" → **receipt sheet** with hostel, room,
      `Bed N`, **reference**, **Remita RRR**, **amount paid**.
- [ ] **Done** → lands on the **Bookings** tab with the new booking on top.
- [ ] [Live] Reference + RRR are **server-generated** (not the demo epoch values).
- [ ] Availability **decrements**: go back to Browse/detail → one fewer bed.
- [ ] **One active reservation:** open any hostel now → CTA is **"View my booking"**.
- [ ] [Edge] [Live] Two devices reserve the same bed → the loser gets a **snackbar**
      ("That bed is no longer available."), not a crash.
- [ ] [Edge] Turn off network mid-pay → snackbar error, button resets (no double-charge).

## 5. Bookings / reservations — FR10

- [ ] New booking appears **newest-first**.
- [ ] Header stats: **Active** count and **Paid this session** total look right.
- [ ] Tap a booking → allocation-slip sheet (room, bed, reference, RRR, amount, date, status).
- [ ] **Cancel** a paid booking → status flips to **Cancelled**; the bed is freed
      (re-open that hostel → availability went back up). **[Live]** persists on the server.
- [ ] Empty state (a brand-new live account) offers **"Browse hostels"**.
- [ ] [Demo] The seeded past **cancelled** booking is present so history isn't empty.

## 6. Profile

- [ ] Identity card: name, reg number, department, level, school email.
  - [ ] [Live] Values come from the signed-in account. A freshly registered account
        with no name yet shows the reg/email and `—` for missing fields (no blanks/crash).
  - [ ] [Demo] Shows the placeholder student (Chidi Okeke).
- [ ] **Your stay**: shows your active paid booking, or an empty-state prompt.
- [ ] Settings sheet → **Light/Dark** toggle re-themes the **whole** app instantly
      (check every tab + a pushed detail screen in dark).
- [ ] **Sign out** → returns to onboarding. **[Live]** token cleared: biometric no
      longer restores until you sign in with a password again.
- [ ] Static menu items (Help, About, Terms) don't crash.

## 7. Device & OS behaviour — [Device]

- [ ] Android **back gesture/button**: pops detail → reserve correctly; on the Browse
      tab it doesn't drop you out unexpectedly mid-flow.
- [ ] **Background & resume**: background the app during a flow, reopen → state intact.
- [ ] **Rotation** stays locked to portrait everywhere.
- [ ] **Dark mode** end-to-end: no unreadable text, no white flashes on transitions.
- [ ] **Small text / large font** (Android display size XL) → no overflow on the
      360px-critical rows (login card, hostel availability row, reserve total).
- [ ] **Keyboard**: on login/search the keyboard doesn't cover the field; "next/done"
      actions work.
- [ ] **Deep-link safety**: reserve after only visiting Browse→detail works (rooms
      loaded); no partial-state crash.

## 8. Admin dashboard (web, separate) — FR11–FR13

- [ ] Open `admin/index.html` in a browser → **admin sign-in** prompt.
- [ ] [Live] Sign in with an admin account → live occupancy, reservations, hostels.
      *(Needs an admin account seeded on the backend — confirm with the backend dev.)*
- [ ] Reservations filter chips (All/Paid/Pending/Cancelled) work.
- [ ] Occupancy bars + revenue reflect live data.
- [ ] Append **`?demo=1`** to the URL → dashboard runs fully offline on sample data.
- [ ] [Edge] Wrong admin password → error in the login modal, not a blank page.
- [ ] [Edge] Backend unreachable → banner "Live data unavailable — showing sample data".

## 9. Regression / stability

- [ ] No red error screens or logged exceptions during the entire journey.
- [ ] `flutter analyze` → **No issues found**.
- [ ] `flutter test` → all pass (offline demo journey).
- [ ] A second full pass in the **opposite** theme (dark) — everything still lays out.

---

## Known limitations (expected, not bugs)

- **Cold start:** the first live request after idle takes ~60–90s (Render free tier
  waking). The UI shows a spinner; it is not frozen. Warm it first (open `/api/docs`).
- **No pull-to-refresh:** live data loads on sign-in (bootstrap). To re-pull, sign
  out and back in. (Fine for the demo; a refresh gesture is a future nicety.)
- **Add-hostel (admin):** the "+ Add hostel" form adds a row visually but is not yet
  POSTed to the backend (the create DTO needs more fields than the form collects).
- **Biometric restore needs a prior password sign-in** on that install (there's no
  stored token before the first login).
