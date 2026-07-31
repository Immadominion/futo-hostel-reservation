# Roost — FUTO Hostel Reservation

**SOE‑510 Mobile App Development · Group 2**

A mobile‑first hostel reservation app for FUTO students, with a marketing landing
page and a web admin for the Hostel / Student Affairs office. It digitises the
real FUTO flow — *sign in → browse → reserve a bed → pay (Remita) → get your
allocation* — into a clean, modern app.

> "Roost" is a working brand name (the wordmark is `Roost.` with a blue dot).
> To rename, change the wordmark in `landing/index.html`, the title in
> `app/lib/app.dart`, and the login wordmark in `app/lib/features/onboarding/`.

---

## What's inside

```
futo-hostel-reservation/
├── REQUIREMENTS.md     Lean, accurate requirements (replaces the 40-point draft)
├── app/                Flutter mobile app  (the graded deliverable)
├── landing/            Marketing landing page  (static HTML/CSS/JS)
├── admin/              Web admin dashboard  (static HTML/CSS/JS)
└── README.md
```

All three share **one design language**: white surfaces + **FUTO royal blue**
(`#2563EB`) accent, Montserrat, squircle corners. The Flutter design system is
ported from our in-house Flutter design system; the web pages mirror its tokens in plain CSS.

---

## Run it

### 📱 Mobile app (Flutter)
```bash
cd app
flutter pub get
flutter run                      # on a connected device / emulator
# or, in a browser:
flutter run -d chrome
```
- **Login:** any reg number like `20211234567` (or a school email
  `name.surname.regno@futo.edu.ng`) + any password that is **8+ chars with a
  letter and a number** (e.g. `futo2026`). Or tap **Use Face ID / Fingerprint**.
- Demo data is static (`app/lib/core/demo/hostel_data.dart`) — no backend.

### 🌐 Landing page & admin (no build step)
Open `landing/index.html` and `admin/index.html` directly, **or** serve the folder:
```bash
python3 -m http.server 8765      # from this directory
# landing → http://localhost:8765/landing/
# admin   → http://localhost:8765/admin/
```

### 🎬 Wire up the landing CTAs
Edit the `CONFIG` block at the top of `landing/script.js`:
- `appetizeUrl` — paste your **Appetize.io** public link (powers **View live**).
- `videoEmbedUrl` — paste a YouTube/Loom **embed** URL (powers **Watch video**).
- Until set, **View live** opens the local web build and **Watch video** shows a
  placeholder.

---

## Maps & imagery
- The landing embeds a **live Google Map** of FUTO and every hostel card links to
  its location on Google Maps; the app's hostel detail has a **View on map**
  button that opens Google Maps at the hostel's coordinates.
- Hostel covers are on‑brand gradient cards (distinct per block). To use a real
  photo instead, drop `app/assets/hostels/<id>.jpg` (and set a `background-image`
  on `.hcard-cover` in the landing) — the layout already accommodates it.

## The hostels (demo)
Hostels **A–E**, **TETFund**, **NDDC**, **PG** — real blocks. Gender / room size /
fee are representative demo values (FUTO doesn't publish an authoritative table,
and the few published fees conflict). See **REQUIREMENTS.md §4 & §9** for the
sourcing and corrections (e.g. NDDC is mixed‑gender; "PG" = postgraduate).

## Requirement → where it lives
| FR | Implemented in |
|---|---|
| FR1–3 Auth + biometric | `app/lib/features/onboarding/` |
| FR4–6 Browse / search / detail | `app/lib/features/browse`, `hostel_detail` |
| FR7 Reserve a bed (live availability) | `app/lib/features/reserve`, `core/demo/hostel_data.dart` |
| FR8–9 Pay (mock Remita) + receipt/RRR | `app/lib/features/reserve` |
| FR10 View / cancel / history | `app/lib/features/reservations` |
| FR11–13 Manage hostels, reservations, allocation, occupancy | `admin/` |
