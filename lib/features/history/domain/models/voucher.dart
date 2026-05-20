enum CarrierType { almadar, libyana, ltt, unkown }

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
}
