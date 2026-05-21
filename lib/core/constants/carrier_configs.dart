import 'package:odfinance/features/history/domain/models/voucher.dart';

class CarrierConfigs {
  static CarrierType identifyCode(String code) {
    if (code.length == 14) return CarrierType.libyana;
    if (code.length == 13) return CarrierType.almadar;
    if (code.length == 15) return CarrierType.ltt;
    return CarrierType.unknown;
  }

  static String generateCode(CarrierType carreier, String code) {
    switch (carreier) {
      case CarrierType.almadar:
        return '*121*$code#';
      case CarrierType.libyana:
        return '*112*$code#';
      case CarrierType.ltt:
        return '*116*$code#';

      case CarrierType.unknown:
        return code;
    }
  }
}
