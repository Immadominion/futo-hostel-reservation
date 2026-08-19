import '../widgets/status_pill.dart';

/// Admin-side data models. Hostel/RoomType are reused as-is from
/// `core/demo/hostel_data.dart` since `/admin/hostels` and `/admin/rooms`
/// return the exact same DTO shapes as the student-facing endpoints.

RoostStatus _statusFromReservation(String? s) => switch (s) {
      'paid' => RoostStatus.paid,
      'reserved' => RoostStatus.reserved,
      'cancelled' => RoostStatus.cancelled,
      _ => RoostStatus.pending,
    };

const List<String> _kMonths = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

class AdminUser {
  const AdminUser({required this.id, required this.name, required this.email});
  final String id, name, email;

  factory AdminUser.fromJson(Map<String, dynamic> j) => AdminUser(
        id: (j['id'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        email: (j['email'] ?? '').toString(),
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'email': email};
}

class HostelOccupancy {
  const HostelOccupancy({required this.id, required this.name, required this.occupied, required this.total});
  final String id, name;
  final int occupied, total;

  factory HostelOccupancy.fromJson(Map<String, dynamic> j) => HostelOccupancy(
        id: (j['id'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        occupied: (j['occupied'] as num?)?.toInt() ?? 0,
        total: (j['total'] as num?)?.toInt() ?? 0,
      );

  double get pct => total == 0 ? 0 : occupied / total;
}

class OccupancyStats {
  const OccupancyStats({
    required this.totalBeds,
    required this.occupied,
    required this.available,
    required this.occupancyPct,
    required this.revenue,
    required this.perHostel,
  });

  final int totalBeds, occupied, available, occupancyPct, revenue;
  final List<HostelOccupancy> perHostel;

  factory OccupancyStats.fromJson(Map<String, dynamic> j) => OccupancyStats(
        totalBeds: (j['totalBeds'] as num?)?.toInt() ?? 0,
        occupied: (j['occupied'] as num?)?.toInt() ?? 0,
        available: (j['available'] as num?)?.toInt() ?? 0,
        occupancyPct: (j['occupancyPct'] as num?)?.toInt() ?? 0,
        revenue: (j['revenue'] as num?)?.toInt() ?? 0,
        perHostel: ((j['perHostel'] as List?) ?? const [])
            .map((e) => HostelOccupancy.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  String get revenueFull =>
      '₦${revenue.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')}';
}

class AdminReservation {
  const AdminReservation({
    required this.id,
    required this.reference,
    required this.rrr,
    required this.studentId,
    required this.hostelId,
    required this.roomId,
    required this.roomIndex,
    required this.bed,
    required this.fee,
    required this.status,
    required this.createdAtIso,
    this.studentName,
    this.studentRegNo,
    this.studentLevel,
  });

  final String id, reference, rrr, studentId, hostelId, roomId, createdAtIso;
  final int roomIndex, bed, fee;
  final RoostStatus status;
  final String? studentName, studentRegNo, studentLevel;

  factory AdminReservation.fromJson(Map<String, dynamic> j) => AdminReservation(
        id: (j['id'] ?? '').toString(),
        reference: (j['reference'] ?? '').toString(),
        rrr: (j['rrr'] ?? '').toString(),
        studentId: (j['studentId'] ?? '').toString(),
        hostelId: (j['hostelId'] ?? '').toString(),
        roomId: (j['roomId'] ?? '').toString(),
        roomIndex: (j['roomIndex'] as num?)?.toInt() ?? 0,
        bed: (j['bed'] as num?)?.toInt() ?? 0,
        fee: (j['fee'] as num?)?.toInt() ?? 0,
        status: _statusFromReservation(j['status']?.toString()),
        createdAtIso: (j['createdAt'] ?? '').toString(),
        studentName: j['studentName']?.toString(),
        studentRegNo: j['studentRegNo']?.toString(),
        studentLevel: j['studentLevel']?.toString(),
      );

  String get feeFull =>
      '₦${fee.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')}';

  String get studentDisplay =>
      (studentName != null && studentName!.trim().isNotEmpty) ? studentName! : (studentRegNo ?? '—');

  bool get isPending => status == RoostStatus.pending || status == RoostStatus.reserved;

  bool get isPriority => studentLevel != null && (RegExp(r'100\s*level', caseSensitive: false).hasMatch(studentLevel!) ||
      RegExp(r'final\s*year', caseSensitive: false).hasMatch(studentLevel!));

  String get dateDisplay {
    final d = DateTime.tryParse(createdAtIso);
    if (d == null) return createdAtIso;
    final local = d.toLocal();
    return '${_kMonths[local.month - 1]} ${local.day}, ${local.year}';
  }
}
