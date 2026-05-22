import 'package:odfinance/features/history/domain/models/voucher.dart';
import 'package:riverpod/riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:odfinance/core/constants/carrier_configs.dart';
import 'package:odfinance/core/services/service_providers.dart';

class HistoryNotifier extends AsyncNotifier<List<Voucher>> {
  @override
  Future<List<Voucher>> build() async {
    // 1. Fetch the raw storage service directly via Riverpod read constraints
    final storage = ref.watch(storageServiceProvider);
    final rawList = await storage.getVoucherRawList();

    // 2. Map the untyped JSON arrays back into our clean domain objects
    return rawList.map((json) => Voucher.fromJson(json)).toList()
      // Sort newest scans to the top of the history list
      ..sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
  }

  /// Adds a newly scanned serial code to history and saves to disk.
  Future<Voucher> addVoucher(String rawSerialCode) async {
    final currentVouchers = state.value ?? [];

    // Determine the carrier type automatically based on code attributes
    final detectedCarrier = CarrierConfigs.identifyCode(rawSerialCode);

    final newVoucher = Voucher(
      id: const Uuid().v4(), // Generates a unique tracking identifier locally
      serialCode: rawSerialCode,
      carrier: detectedCarrier,
      scannedAt: DateTime.now(),
    );

    // Update in-memory state smoothly
    final updatedList = [newVoucher, ...currentVouchers];
    state = AsyncData(updatedList);

    // Persist background changes asynchronously to avoid UI frame hitching
    _persistToDisk(updatedList);

    return newVoucher;
  }

  /// Toggles the voucher's status flag (e.g., marking a card as "Used").
  Future<void> toggleVoucherStatus(String id) async {
    final currentVouchers = state.value ?? [];

    final updatedList = currentVouchers.map((voucher) {
      if (voucher.id == id) {
        return voucher.copyWith(isUsed: !voucher.isUsed);
      }
      return voucher;
    }).toList();

    state = AsyncData(updatedList);
    _persistToDisk(updatedList);
  }

  // Internal helper to push changes downstream to our storage service
  Future<void> _persistToDisk(List<Voucher> vouchers) async {
    final storage = ref.read(storageServiceProvider);
    final rawJsonList = vouchers.map((v) => v.toJson()).toList();
    await storage.saveVoucherRawList(rawJsonList);
  }
}

// Global initialization of our reactive history logs state provider
final historyProvider = AsyncNotifierProvider<HistoryNotifier, List<Voucher>>(
  () {
    return HistoryNotifier();
  },
);
// class HistoryProvider extends AsyncNotifier<List<Voucher>> {
//   @override
//   Future<List<Voucher>> build() async {
//     final storage = ref.watch(storageServiceProvider);

//     final rawList = await storage.getVoucherRawList();
//     return rawList.map((json) => Voucher.fromJson(json)).toList()
//       ..sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
//   }
// }
// // Adds a newly scanned serial code to history and saves it to desk/storage

// Future<Voucher> addVoucher(String rawSerialCode) async {
//   final currentVouchers = state.valueOrNull ?? [];
//   // determine Carreir Type based on code
//   final detectedCarrier = CarrierConfigs.identifyCode(rawSerialCode);

//   final newVoucher = Voucher(
//     id: const Uuid().v4(),// unque idenytifying tracker
//     serialCode: rawSerialCode,
//     carrier: detectedCarrier,
//     scannedAt: DateTime.now(),
//   ); 
//   // Update in-memory state smoothly
//     final updatedList = [newVoucher, ...currentVouchers];
//     state = AsyncData(updatedList); 
//     _persistToDisk(updatedList);
    
//     return newVoucher; 
// }
