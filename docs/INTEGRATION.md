# Roost — Client ↔ Backend Integration

How the Flutter app and the web admin talk to the deployed backend, and how to
run/verify each mode.

- **Live API:** `https://futo-hostel-reservation-backend.onrender.com/api/v1`
- **Swagger UI:** `https://futo-hostel-reservation-backend.onrender.com/api/docs`
- **Contract / shapes / rules:** [`BACKEND-README.md`](./BACKEND-README.md) and
  [`BACKEND-API.md`](./BACKEND-API.md)

---

## Two run modes (single switch)

The app has one flag, `AppConfig.useDemoData` ([app/lib/core/config/app_config.dart](../app/lib/core/config/app_config.dart)):

| Mode | Flag | Behaviour |
|---|---|---|
| **Live** (default) | `false` | Signs in against the API, loads hostels/rooms/reservations from the backend, real reserve → pay → cancel. |
| **Demo** | `true` | Fully offline on the static data in `app/lib/core/demo/hostel_data.dart`. No network at all. |

```bash
cd app
flutter pub get                                   # pulls http + flutter_secure_storage
flutter run                                        # LIVE (default)
flutter run --dart-define=USE_DEMO_DATA=true       # OFFLINE demo
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:4000/api/v1   # local backend (Android emulator)
```

> Demo mode exists so a graded demo never hangs on a cold/asleep backend. Widget
> tests force it on, so `flutter test` runs offline.

---

## How the app is wired

The design keeps the screens simple: on sign-in the app **bootstraps** — it pulls
everything into the same in-memory structures the UI already read, so browse /
detail / bookings stay synchronous. Only auth, pay, cancel and profile do I/O.

```
core/config/app_config.dart      base URL + USE_DEMO_DATA flag
core/api/roost_api.dart          RoostApi (typed endpoint calls), ApiException, TokenStore, providers
core/session/session_controller.dart   login / register / biometric-restore / logout + bootstrap
core/demo/hostel_data.dart       models (+ fromJson), mutable HostelData, reservations Notifier
```

Flow:

1. **Sign in / register** → `POST /auth/login | /auth/register` → JWT saved to
   secure storage (Keychain / EncryptedSharedPreferences).
2. **Bootstrap** → `GET /hostels` + `GET /hostels/:id` (rooms, occupied beds) →
   `HostelData.replaceHostels(...)`; `GET /reservations` → reservations list.
3. **Reserve + pay** → `POST /reservations` (hold bed) → `POST /payments/:rrr/simulate`
   (confirm without a real Remita webhook) → `GET /reservations/:id` (paid receipt).
4. **Cancel** → `POST /reservations/:id/cancel`. **Sign out** → `POST /auth/logout`
   + clears the token. **Biometric** restores via `GET /auth/me`.

Every bootstrap network step is **non-fatal**: if the backend is slow/unreachable
the app falls back to the built-in static hostels rather than failing to sign in.

---

## Admin dashboard

`admin/` is static HTML/JS. [`admin/api.js`](../admin/api.js) adds an admin sign-in
(`POST /auth/admin/login`), fetches occupancy / reservations / hostels+rooms, maps
them into the shapes `app.js` already renders, and repaints. On any failure it
shows a banner and keeps the sample data.

- Open `admin/index.html` → sign in with an admin account.
- Append **`?demo=1`** (or `localStorage.roost_admin_demo = '1'`) to run offline.
- Requires an admin account to exist on the backend (seeded server-side).

---

## Verify checklist

**Live (backend must be reachable — first hit may cold-start ~50s):**

- [ ] `flutter pub get` resolves `http` + `flutter_secure_storage`.
- [ ] Register a new account → lands on Browse with hostels from the server.
- [ ] Open a hostel → the bed grid greys out the server's occupied beds.
- [ ] Reserve → pay → receipt shows a server reference/RRR; booking appears under Bookings.
- [ ] Cancel a paid booking → status flips to Cancelled.
- [ ] Kill & reopen → **Face ID / fingerprint** restores the session.
- [ ] `admin/index.html` → admin sign-in → live occupancy + reservations.

**Demo:** `flutter run --dart-define=USE_DEMO_DATA=true` → the whole journey works
with no network; `flutter test` passes offline.
