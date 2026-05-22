// lib/features/history/domain/models/voucher.dart

enum CarrierType { libyana, almadar, ltt, unknown }

class Voucher {
  final String id;
  final String serialCode;
  final CarrierType carrier;
  final DateTime scannedAt;
  final bool isUsed;

  const Voucher({
    required this.id,
    required this.serialCode,
    required this.carrier,
    required this.scannedAt,
    this.isUsed = false,
  });

  Voucher copyWith({bool? isUsed}) {
    return Voucher(
      id: id,
      serialCode: serialCode,
      carrier: carrier,
      scannedAt: scannedAt,
      isUsed: isUsed ?? this.isUsed,
    );
  }

  // Convert JSON Map from local storage back into a type-safe Voucher object
  factory Voucher.fromJson(Map<String, dynamic> json) {
    return Voucher(
      id: json['id'] as String,
      serialCode: json['serial_code'] as String,
      carrier: CarrierType.values.firstWhere(
        (e) => e.toString() == json['carrier'],
        orElse: () => CarrierType.unknown,
      ),
      scannedAt: DateTime.parse(json['scanned_at'] as String),
      isUsed: json['is_used'] as bool? ?? false,
    );
  }

  // Convert Voucher object into a JSON Map ready for storage I/O
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serial_code': serialCode,
      'carrier': carrier.toString(),
      'scanned_at': scannedAt.toIso8601String(),
      'is_used': isUsed,
    };
  }
}
