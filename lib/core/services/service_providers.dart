import 'package:riverpod/riverpod.dart';
import 'dialer_service.dart';
import 'storage_service.dart';

final dialerServiceProvider = Provider<DialerService>((ref) {
  return DialerService();
});

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});
