# 1 — Use Case Diagram

**Purpose:** the functional scope of Roost — who (actors) can do what (use cases),
and how the use cases relate (`«include»`, `«extend»`, generalization).

## Actors

| Actor | Type | Role |
|---|---|---|
| **Student** | Primary | Uses the mobile app: sign in, browse, reserve, pay, view/cancel bookings. |
| **Admin** | Primary | Student-Affairs officer on the web dashboard: manage hostels/rooms, view reservations, allocate beds, see occupancy. |
| **Remita Payment Gateway** | Supporting (secondary, external) | Issues the RRR and confirms payment (webhook). Drawn on the **right** as an external actor. |

## Use cases

| ID | Use case | Actor | One-line meaning |
|---|---|---|---|
| U1 | Register Account | Student | Create an account (reg-no/email + password). |
| U2 | Log In | Student | Authenticate with identifier + password. |
| U3 | Unlock with Biometrics | Student | Face ID / fingerprint unlock (alternative to U2). |
| U4 | Browse Hostels | Student | See all hostels with gender, price, availability. |
| U5 | Search & Filter Hostels | Student | Search by name/funder; filter by gender/availability. |
| U6 | View Hostel Details | Student | Cover, rooms, beds, location, blurb. |
| U7 | Reserve a Bed | Student | Hold a specific bed in a room. |
| U7a | Check Bed Availability | (system) | Verify the bed is free + one-active-reservation rule. |
| U8 | Make Payment | Student | Pay the hostel fee. |
| U9 | Process Remita Payment | Remita | Generate RRR, take payment, confirm via webhook. |
| U10 | Issue Allocation & Receipt | (system) | Produce reference + e-receipt + allocation. |
| U11 | View My Bookings | Student | List reservations + history. |
| U12 | Cancel Reservation | Student | Cancel a paid booking (frees the bed). |
| U13 | View Profile | Student | Identity, current stay, appearance, sign out. |
| U14 | Sign Out | Student | End the session. |
| U15 | Admin Log In | Admin | Authenticate to the dashboard. |
| U16 | Manage Hostels | Admin | Create / update / delete hostels. |
| U17 | Manage Rooms | Admin | Create / update / delete room types. |
| U18 | View Reservations & Payments | Admin | See all bookings + payment status. |
| U19 | Allocate / Reassign Bed | Admin | Manually place or move a student's bed. |
| U19a | Apply FCFS & Priority Rules | (system) | First-come-first-serve, 100-level & final-year priority. |
| U20 | View Occupancy Dashboard | Admin | Beds filled vs free per hostel + revenue. |

## Relationships (the part that must be exact)

**Associations** (solid line, actor ↔ base use case):

- Student — U1, U2, U4, U6, U7, U8, U11, U13, U14
- Admin — U15, U16, U17, U18, U19, U20
- Remita Payment Gateway — U9

**`«include»`** (dashed arrow, **base → included**; the included behaviour is
*always* performed as part of the base):

| Base | includes | Why |
|---|---|---|
| U7 Reserve a Bed | U7a Check Bed Availability | every reservation first checks the bed + active-booking rule |
| U7 Reserve a Bed | U8 Make Payment | an allocation is only granted once paid — the app does reserve→pay as one transaction |
| U8 Make Payment | U9 Process Remita Payment | payment always runs through Remita (RRR) |
| U19 Allocate / Reassign Bed | U19a Apply FCFS & Priority Rules | allocation always applies the ordering rules |

**`«extend»`** (dashed arrow, **extension → base**; optional/conditional):

| Extension | extends base | Condition |
|---|---|---|
| U3 Unlock with Biometrics | U2 Log In | `[biometrics enrolled & previously signed in]` |
| U5 Search & Filter Hostels | U4 Browse Hostels | `[user narrows the list]` |
| U12 Cancel Reservation | U11 View My Bookings | `[booking is PAID and before deadline]` |
| U10 Issue Allocation & Receipt | U8 Make Payment | `[payment verified]` |

**Generalization** *(optional refinement, if your rubric wants it):* introduce an
abstract actor **User** and let `Student ▷ User` and `Admin ▷ User` (hollow
triangle to User), factoring a shared **Authenticate** use case. Keep the note
that Student authenticates via the student endpoint and Admin via the admin
endpoint. The main diagram below keeps them separate for clarity.

## Layout

- One **system boundary** rectangle titled *"Roost — FUTO Hostel Reservation
  System"* containing all ellipses.
- **Student** actor on the **left**; **Admin** actor on the **right**; **Remita**
  actor lower-right (external).
- Cluster Student use cases (U1–U14) toward the left half, Admin use cases
  (U15–U20) toward the right half; U9 near Remita.
- Draw `«include»`/`«extend»` as **dashed** arrows with the stereotype label; keep
  association lines solid and unlabeled.

## Renderable source (PlantUML)

```plantuml
@startuml roost-use-case
left to right direction
skinparam packageStyle rectangle
actor "Student" as ST
actor "Admin" as AD
actor "Remita Payment Gateway" as RM

rectangle "Roost — FUTO Hostel Reservation System" {
  usecase "Register Account"              as U1
  usecase "Log In"                        as U2
  usecase "Unlock with Biometrics"        as U3
  usecase "Browse Hostels"                as U4
  usecase "Search & Filter Hostels"       as U5
  usecase "View Hostel Details"           as U6
  usecase "Reserve a Bed"                 as U7
  usecase "Check Bed Availability"        as U7a
  usecase "Make Payment"                  as U8
  usecase "Process Remita Payment"        as U9
  usecase "Issue Allocation & Receipt"    as U10
  usecase "View My Bookings"              as U11
  usecase "Cancel Reservation"            as U12
  usecase "View Profile"                  as U13
  usecase "Sign Out"                      as U14
  usecase "Admin Log In"                  as U15
  usecase "Manage Hostels"                as U16
  usecase "Manage Rooms"                  as U17
  usecase "View Reservations & Payments"  as U18
  usecase "Allocate / Reassign Bed"       as U19
  usecase "Apply FCFS & Priority Rules"   as U19a
  usecase "View Occupancy Dashboard"      as U20
}

ST --> U1
ST --> U2
ST --> U4
ST --> U6
ST --> U7
ST --> U8
ST --> U11
ST --> U13
ST --> U14

AD --> U15
AD --> U16
AD --> U17
AD --> U18
AD --> U19
AD --> U20

RM --> U9

U7  ..> U7a  : <<include>>
U7  ..> U8   : <<include>>
U8  ..> U9   : <<include>>
U19 ..> U19a : <<include>>

U3  ..> U2   : <<extend>>
U5  ..> U4   : <<extend>>
U12 ..> U11  : <<extend>>
U10 ..> U8   : <<extend>>
@enduml
```

> Common-mistake guard: an `«include»` arrow points **from the base to the
> included** use case; an `«extend»` arrow points **from the extension back to the
> base**. Do **not** connect secured use cases to "Log In" with `«include»` — login
> is a *precondition*, not an included step.
