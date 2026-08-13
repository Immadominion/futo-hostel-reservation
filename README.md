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
flutter pub get                                  # pulls http + flutter_secure_storage
flutter run                                       # LIVE: talks to the deployed backend (default)
flutter run --dart-define=USE_DEMO_DATA=true      # OFFLINE: built-in demo data, no network
# or, in a browser:
flutter run -d chrome
```
- **Live mode (default):** the app signs in against the API, then loads hostels,
  rooms and your reservations from the backend, and does a real reserve → pay →
  allocation. The first request can take ~50s if the free-tier server is asleep.
- **Demo mode** (`USE_DEMO_DATA=true`): runs entirely offline on the static data
  in `app/lib/core/demo/hostel_data.dart` — use it for a guaranteed demo.
- **Login:** register or sign in with a reg number like `20211234567` (or a school
  email `name.surname.regno@futo.edu.ng`) + a password that is **8+ chars with a
  letter and a number** (e.g. `futo2026`). After the first sign-in, **Face ID /
  fingerprint** unlocks the saved session.

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

## Live backend

- **API base:** `https://futo-hostel-reservation-backend.onrender.com/api/v1`
- **API docs (Swagger):** `https://futo-hostel-reservation-backend.onrender.com/api/docs`
- The Flutter app **and** the web admin talk to this by default. How the client is
  wired (and how to point at a different backend) is in
  [`docs/INTEGRATION.md`](docs/INTEGRATION.md).
- **Admin dashboard:** open `admin/index.html`, sign in with an admin account, and
  it shows live occupancy, reservations and hostels. Append `?demo=1` to the URL to
  run it fully offline on sample data.
- Heads-up: the backend is on Render's free tier — after ~15 min idle it sleeps and
  the next request cold-starts (~50s). Use demo mode for a guaranteed-instant demo.

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
