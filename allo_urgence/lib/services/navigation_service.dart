import 'package:url_launcher/url_launcher.dart';

class NavigationService {
  /// Open Google Maps or Apple Maps with directions to hospital
  static Future<void> openMapsNavigation({
    required double latitude,
    required double longitude,
    required String hospitalName,
  }) async {
    // Try Google Maps first (works on both iOS and Android)
    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&destination_place_id=$hospitalName',
    );

    // Apple Maps URL (iOS only)
    final appleMapsUrl = Uri.parse(
      'https://maps.apple.com/?daddr=$latitude,$longitude&q=$hospitalName',
    );

    // Try to launch Google Maps
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(
        googleMapsUrl,
        mode: LaunchMode.externalApplication,
      );
    }
    // Fallback to Apple Maps on iOS
    else if (await canLaunchUrl(appleMapsUrl)) {
      await launchUrl(
        appleMapsUrl,
        mode: LaunchMode.externalApplication,
      );
    }
    // Fallback to browser
    else {
      final browserUrl = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
      );
      await launchUrl(browserUrl);
    }
  }

  /// Open phone dialer
  static Future<void> openPhoneDialer(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw Exception('Could not launch phone dialer');
    }
  }

  /// Open email client
  static Future<void> openEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw Exception('Could not launch email client');
    }
  }
}
