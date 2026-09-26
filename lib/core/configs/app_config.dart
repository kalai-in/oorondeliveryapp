import 'package:deliveryboy/commons/models/countries_model.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central configuration file for buyers to customise.
///
/// ─── HOW TO CONFIGURE ───────────────────────────────────────────────────────
///   1. Pick the active environment by editing [environment] below.
///      Available environments live as JSON files in `env/`:
///        env/demo.json
///   2. Edit the URLs in the matching `env/<name>.json` file.
///   3. Run:  dart run tool/apply_config.dart
///      The script reads the selected env JSON and rewrites the URL
///      constants below.
///   4. Build / run:  flutter clean && flutter run
/// ────────────────────────────────────────────────────────────────────────────
abstract final class AppConfig {
  /// Active environment — maps to `env/<environment>.json`.
  static const String environment = 'demo';

  // ─── AUTO-SYNCED FROM env/<environment>.json — DO NOT EDIT BY HAND ────────
  // Run `dart run tool/apply_config.dart` to refresh these values.
  // ──────────────────────────────────────────────────────────────────────────
  static const String baseUrl =
      "https://admin.ooron.in/delivery_boy/";
  static const String socketBaseUrl =
      "wss://admin.ooron.in/ws/chat";
  // ──────────────────────────────────────────────────────────────────────────

  // Pagination
  static const int pageLimit = 10;

  // Defaults
  /// Default dial code shown in the phone field, this work only in fallback if setting API failed.
  static CountriesData defaultCountry = CountriesData(
    code: 'IN',
    dialCode: '+91',
  );
  static const String defaultLanguageCode = 'en';

  // Microsoft Clarity project ID (clarity.microsoft.com dashboard).
  static const String clarityProjectId = 'YOUR_CLARITY_PROJECT_ID_HERE';

  // app name
  static const String appName = 'SnapBuy Deliveryboy';

  // package name
  static const String appPackageName = 'app.snapbuy.deliveryboy';

  //osm map render url
  static const String osmMapRenderUrl =
      "https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png";

  // External map deep links — "$lat,$lng" is appended by launchDirection().
  static const String androidNavigationUrl = "google.navigation:q=";
  static const String appleMapsDirectionUrl = "http://maps.apple.com/?daddr=";
  static const String googleMapsDirectionUrl =
      "https://tile.openstreetmap.org/{z}/{x}/{y}.png"; //"https://www.google.com/maps/dir/?api=1&destination=";

  // App-wide font family
  static final String? fontFamily = GoogleFonts.instrumentSans().fontFamily;

  //Default login detail
  static String defultEmail = '';
  static String defultPassword = '';
}
