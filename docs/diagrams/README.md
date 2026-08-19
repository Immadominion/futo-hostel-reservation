# Roost — System Diagrams (SOE-510)

Convention-correct specifications for the five diagrams required for the FUTO
Hostel Reservation (Roost) project. Each file describes **exactly what to draw**
— every element, every relationship (with multiplicities and stereotypes), the
layout, and a **renderable source** you can paste into a tool to generate the real
picture.

| # | Diagram | File | Best renderer |
|---|---|---|---|
| 1 | Use case | [1-use-case.md](1-use-case.md) | PlantUML |
| 2 | Activity (swim lanes) | [2-activity-swimlane.md](2-activity-swimlane.md) | PlantUML (true lanes) / Mermaid |
| 3 | Sequence | [3-sequence.md](3-sequence.md) | Mermaid or PlantUML |
| 4 | ER / data model | [4-er-data-model.md](4-er-data-model.md) | Mermaid (`erDiagram`) |
| 5 | Class | [5-class.md](5-class.md) | Mermaid (`classDiagram`) / PlantUML |

**How to render:** Mermaid blocks render directly on GitHub, in VS Code (Markdown
Preview Mermaid Support), and at <https://mermaid.live>. PlantUML blocks render at
<https://www.plantuml.com/plantuml> or with the VS Code PlantUML extension. Paste
the fenced source, export PNG/SVG, drop into your report.

> Everything below is derived from the real system: the Flutter app models
> (`app/lib/core/demo/hostel_data.dart`), the API contract (`docs/BACKEND-README.md`,
> `docs/BACKEND-API.md`) and the deployed OpenAPI spec. Keep these names identical
> across all five diagrams — consistency is half of "no mistakes".

---

## Canonical domain model (single source of truth)

All five diagrams use **these exact names, attributes and enums.** Do not rename
between diagrams.

### Enumerations

| Enum | Values |
|---|---|
| `Gender` | `MALE`, `FEMALE`, `MIXED`, `POSTGRAD` |
| `HostelStatus` | `AVAILABLE`, `LIMITED`, `FULL` |
| `ReservationStatus` | `PENDING`, `RESERVED`, `PAID`, `CANCELLED` |
| `PaymentStatus` | `PENDING`, `PAID`, `FAILED` |
| `Funder` | `SCHOOL`, `TETFUND`, `NDDC`, `POSTGRADUATE` |

### Entities / classes

| Entity | Key attributes (type) | Notes |
|---|---|---|
| **Student** | `id` (PK), `name`, `regNo` (unique, 11 digits), `email` (unique), `dept`, `level`, `passwordHash` | The mobile-app user |
| **Admin** | `id` (PK), `name`, `email` (unique), `passwordHash` | Student-Affairs / hostel officer (web) |
| **Hostel** | `id` (PK), `name`, `code`, `funder: Funder`, `gender: Gender`, `price` (₦ int), `roomSize`, `blurb`, `lat`, `lng`, `coverA`, `coverB`; **/derived** `bedsAvailable`, `bedsTotal`, `status: HostelStatus` | A block (A–E, TETFund, NDDC, PG) |
| **Room** | `id` (PK), `hostelId` (FK), `name`, `capacity`, `bedsTotal`, `bedsAvailable`; **/derived** `status: HostelStatus`, `occupiedBeds: int[]` | A **room type** within a hostel (e.g. "8-bed room") |
| **Reservation** | `id` (PK), `reference` (unique), `rrr` (unique), `studentId` (FK), `hostelId` (FK), `roomId` (FK), `roomName`, `bed` (int), `fee` (₦ int), `status: ReservationStatus`, `createdAt` | One booking of one bed |
| **Payment** | `rrr` (PK), `reservationId` (FK, unique), `amount` (₦ int), `status: PaymentStatus`, `transactionId?`, `createdAt` | Remita RRR payment for a reservation |

### The relationships (identical everywhere)

| From | To | Meaning | Multiplicity | Kind |
|---|---|---|---|---|
| Hostel | Room | a hostel **is made of** room types | `1` → `1..*` | **composition** (rooms die with the hostel) |
| Student | Reservation | a student **makes** bookings | `1` → `0..*` | association (rule: ≤ 1 *active*) |
| Room | Reservation | a booking is **for** one room+bed | `1` → `0..*` | association |
| Hostel | Reservation | denormalized hostel of a booking | `1` → `0..*` | association *(derivable via Room; stored for convenience)* |
| Reservation | Payment | a booking **is paid by** one payment | `1` → `1` | **composition** (payment created with the reservation) |
| Admin | Reservation | an admin **allocates/reassigns** | `0..1` → `0..*` | association (optional) |
| User → Student, Admin | — | shared identity/login | — | **generalization** *(class diagram only; ER keeps separate tables)* |

### Actors (for use case / activity / sequence)

- **Student** — primary actor (mobile app).
- **Admin** — primary actor (web dashboard).
- **Remita Payment Gateway** — supporting/secondary actor (external system that
  issues the RRR and confirms payment via webhook).

### Key business rules (must be visible in the diagrams)

1. **One active reservation per student** (`PENDING`/`RESERVED`/`PAID`).
2. **First-come-first-serve**, with **priority for 100-level and final-year** students.
3. **Availability decrements on reserve**, restored on **cancel** or **payment failure/timeout**.
4. **Allocation is confirmed only after payment is verified** (Remita webhook).
5. **Own-data-only** — a student can read/modify only their own reservations.

---

## Notation legend (what the symbols mean)

**Use case** — actor = stick figure; use case = ellipse; system boundary =
rectangle; association = solid line; `«include»` = dashed arrow *base → included*
(mandatory sub-behaviour); `«extend»` = dashed arrow *extension → base* (optional/
conditional); generalization = solid line with hollow triangle.

**Activity** — `●` initial node; rounded rectangle = action; `◇` diamond =
decision/merge (branches carry `[guards]`); solid bar = fork/join; vertical
columns = **swim-lane partitions** (each action sits in its owner's lane); `◉`
activity-final; ⊗ flow-final.

**Sequence** — actor/object at top; dashed vertical = lifeline; thin rectangle =
activation (execution occurrence); solid arrow + filled head = synchronous call;
dashed arrow + open head = reply; open head = asynchronous; `alt`/`opt`/`loop` =
combined fragments with `[guards]`.

**ER (crow's foot)** — rectangle = entity; PK underlined/first; FK marked; a
relationship line's ends read: `||` exactly one, `|o` zero-or-one, `}|`
one-or-many, `}o` zero-or-many.

**Class** — three-compartment box (name / attributes / operations); visibility
`+` public, `-` private, `#` protected; association = solid line with
multiplicities + role names; aggregation = hollow diamond; **composition = filled
diamond**; generalization = hollow triangle; dependency = dashed arrow;
`«enumeration»` for enums.
