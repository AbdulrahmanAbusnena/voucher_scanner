import 'package:url_launcher/url_launcher.dart';

class DialerService {
  Future<bool> launchUssd(String ussdCode) async {
    final String encodedCode = ussdCode.replaceAll('#', '%23');
    final Uri tellUri = Uri.parse('tel:$encodedCode');

    try {
      if (await canLaunchUrl(tellUri)) {
        return await launchUrl(tellUri);
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
