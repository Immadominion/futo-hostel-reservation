import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/status_pill.dart';

/// Static demo data + the one piece of mutable app state (reservations).
/// Everything reads from here directly — no backend, no async, kept simple.
/// Values are representative for the FUTO demo (see REQUIREMENTS.md §4/§9).

enum Gender { male, female, mixed, postgrad }

extension GenderLabel on Gender {
  String get label => switch (this) {
        Gender.male => 'Male',
        Gender.female => 'Female',
        Gender.mixed => 'Mixed',
        Gender.postgrad => 'Postgraduate',
      };
}

/// A room *type* within a hostel. [bedsAvailable] is mutable so reserving a bed
/// decrements live availability (FR7) for the rest of the session.
class RoomType {
  RoomType(this.name, this.capacity, this.bedsAvailable, this.bedsTotal);
  final String name;
  final int capacity;
  int bedsAvailable;
  final int bedsTotal;
}

class Hostel {
  Hostel({
    required this.id,
    required this.name,
    required this.code,
    required this.funder,
    required this.gender,
    required this.price,
    required this.roomSize,
    required this.blurb,
    required this.lat,
    required this.lng,
    required this.coverA,
    required this.coverB,
    required this.rooms,
  });

  final String id, name, code, funder, roomSize, blurb;
  final Gender gender;
  final int price;
  final double lat, lng;
  final int coverA, coverB; // cover gradient (ARGB)
  final List<RoomType> rooms;

  int get bedsAvailable => rooms.fold(0, (s, r) => s + r.bedsAvailable);
  int get bedsTotal => rooms.fold(0, (s, r) => s + r.bedsTotal);

  RoostStatus get status => bedsAvailable == 0
      ? RoostStatus.full
      : bedsAvailable <= 6
          ? RoostStatus.limited
          : RoostStatus.available;

  String get priceLabel => '₦${(price / 1000).toStringAsFixed(price % 1000 == 0 ? 0 : 1)}k';
  String get priceFull => '₦${price.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')}';
}

class Reservation {
  Reservation({
    required this.reference,
    required this.rrr,
    required this.hostelId,
    required this.roomName,
    required this.bed,
    required this.fee,
    required this.status,
    required this.date,
  });

  final String reference, rrr, hostelId, roomName, date;
  final int bed, fee;
  final RoostStatus status;

  Reservation copyWith({RoostStatus? status}) => Reservation(
        reference: reference, rrr: rrr, hostelId: hostelId, roomName: roomName,
        bed: bed, fee: fee, status: status ?? this.status, date: date,
      );

  String get feeFull => '₦${fee.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')}';
}

class HostelData {
  HostelData._();

  // ---- signed-in student (demo) ----
  static const String studentName = 'Chidi Okeke';
  static const String studentRegNo = '20211234567';
  static const String studentEmail = 'okeke.chidi.20211234567@futo.edu.ng';
  static const String studentDept = 'Software Engineering';
  static const String studentLevel = '400 Level';

  // ---- the eight FUTO hostels (representative demo values) ----
  static final List<Hostel> hostels = [
    Hostel(
      id: 'A', name: 'Hostel A', code: 'A', funder: 'School', gender: Gender.male,
      price: 42000, roomSize: '8–10 per room', lat: 5.3869, lng: 7.0341,
      coverA: 0xFF1E3A8A, coverB: 0xFF2563EB,
      blurb: 'A male school block close to the lecture halls. Dense, lively, and the cheapest way to stay on campus.',
      rooms: [RoomType('8-bed room', 8, 9, 48), RoomType('10-bed room', 10, 3, 40)],
    ),
    Hostel(
      id: 'B', name: 'Hostel B', code: 'B', funder: 'School', gender: Gender.male,
      price: 42000, roomSize: '8–10 per room', lat: 5.3872, lng: 7.0347,
      coverA: 0xFF312E81, coverB: 0xFF4F46E5,
      blurb: 'Male school block beside Hostel A. Filling fast for the session.',
      rooms: [RoomType('8-bed room', 8, 0, 48), RoomType('10-bed room', 10, 5, 50)],
    ),
    Hostel(
      id: 'C', name: 'Hostel C', code: 'C', funder: 'School', gender: Gender.female,
      price: 45000, roomSize: '6–8 per room', lat: 5.3858, lng: 7.0359,
      coverA: 0xFF0F766E, coverB: 0xFF0EA5A4,
      blurb: 'A female block near TETFund. Calmer rooms with a little more space.',
      rooms: [RoomType('6-bed room', 6, 7, 36), RoomType('8-bed room', 8, 6, 48)],
    ),
    Hostel(
      id: 'D', name: 'Hostel D', code: 'D', funder: 'School', gender: Gender.female,
      price: 45000, roomSize: '6–8 per room', lat: 5.3855, lng: 7.0364,
      coverA: 0xFF155E75, coverB: 0xFF0891B2,
      blurb: 'Female school block. Only a few beds remain this session.',
      rooms: [RoomType('6-bed room', 6, 2, 36), RoomType('8-bed room', 8, 0, 32)],
    ),
    Hostel(
      id: 'E', name: 'Hostel E', code: 'E', funder: 'School', gender: Gender.male,
      price: 42000, roomSize: '8–10 per room', lat: 5.3877, lng: 7.0338,
      coverA: 0xFF1E293B, coverB: 0xFF334155,
      blurb: 'Male school block on the far side. Fully booked for now — check back later.',
      rooms: [RoomType('8-bed room', 8, 0, 64)],
    ),
    Hostel(
      id: 'TETFUND', name: 'TETFund Hostel', code: 'TF', funder: 'TETFund', gender: Gender.mixed,
      price: 90000, roomSize: '4 per room (en-suite)', lat: 5.3851, lng: 7.0366,
      coverA: 0xFF1D4ED8, coverB: 0xFF3B82F6,
      blurb: 'The newest, most comfortable block — four to a room, en-suite, mixed and floor-segregated.',
      rooms: [RoomType('4-bed room (en-suite)', 4, 8, 80)],
    ),
    Hostel(
      id: 'NDDC', name: 'NDDC Hostel', code: 'ND', funder: 'NDDC', gender: Gender.mixed,
      price: 62500, roomSize: '3–4 per room', lat: 5.3848, lng: 7.0371,
      coverA: 0xFF134E4A, coverB: 0xFF0D9488,
      blurb: 'Lower-density, two-storey block housing both genders by floor. Premium comfort for the price.',
      rooms: [RoomType('4-bed room', 4, 6, 64), RoomType('3-bed room', 3, 4, 36)],
    ),
    Hostel(
      id: 'PG', name: 'PG Hostel', code: 'PG', funder: 'Postgraduate', gender: Gender.postgrad,
      price: 75000, roomSize: '1–2 per room', lat: 5.3845, lng: 7.0331,
      coverA: 0xFF4C1D95, coverB: 0xFF6D28D9,
      blurb: 'Quiet quarters for postgraduate students — one or two to a room for focused study.',
      rooms: [RoomType('2-bed room', 2, 5, 40), RoomType('1-bed studio', 1, 2, 12)],
    ),
  ];

  static Hostel byId(String id) => hostels.firstWhere((h) => h.id == id);
}

// ---- reservations: the only mutable app state, via a Riverpod Notifier ----

class ReservationsController extends Notifier<List<Reservation>> {
  @override
  List<Reservation> build() => [
        // one past (cancelled) booking so history isn't empty
        Reservation(
          reference: 'RST-7F3A21', rrr: '270054118832', hostelId: 'NDDC',
          roomName: '4-bed room', bed: 2, fee: 62500,
          status: RoostStatus.cancelled, date: 'Sep 14, 2025',
        ),
      ];

  bool get hasActive => state.any((r) => r.status == RoostStatus.paid || r.status == RoostStatus.reserved);

  /// Reserve + pay a bed. Decrements live availability and records the booking.
  Reservation reserve({required Hostel hostel, required RoomType room, required int bed, required int fee}) {
    if (room.bedsAvailable > 0) room.bedsAvailable -= 1;
    final stamp = DateTime.now();
    final res = Reservation(
      reference: 'RST-${stamp.millisecondsSinceEpoch.toRadixString(16).substring(4).toUpperCase()}',
      rrr: (stamp.millisecondsSinceEpoch % 1000000000000).toString().padLeft(12, '0'),
      hostelId: hostel.id, roomName: room.name, bed: bed, fee: fee,
      status: RoostStatus.paid, date: _fmt(stamp),
    );
    state = [res, ...state];
    return res;
  }

  void cancel(String reference) {
    state = [
      for (final r in state)
        if (r.reference == reference) r.copyWith(status: RoostStatus.cancelled) else r,
    ];
  }

  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  static String _fmt(DateTime d) => '${_months[d.month - 1]} ${d.day}, ${d.year}';
}

final reservationsProvider =
    NotifierProvider<ReservationsController, List<Reservation>>(ReservationsController.new);
