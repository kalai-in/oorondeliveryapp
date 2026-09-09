import 'dart:convert';
import 'package:flutter/services.dart';

/// Holds the currently active translation map and resolves string keys to display text.
class LocalizationService {
  LocalizationService._();
  static final LocalizationService instance = LocalizationService._();

  static const _assetPath = 'assets/languages/en.json';

  /// Local en.json — always loaded first as a base, so any key missing from
  /// the server response still resolves instead of falling back to the raw key.
  Map<String, String> _assetTranslations = {};
  Map<String, String> _translations = {};
  bool _assetsLoaded = false;

  /// Server data overlays on top of the local asset base — missing keys in
  /// the server response keep their local fallback instead of disappearing.
  /// Asset base is loaded on first use so this works even when the cache/API
  /// path never calls [loadFromAssets] directly.
  Future<void> load(Map<dynamic, dynamic> data) async {
    if (!_assetsLoaded) await loadFromAssets();
    final merged = Map<String, String>.from(_assetTranslations);
    data.forEach((k, v) {
      final value = v?.toString() ?? '';
      if (value.isNotEmpty) merged[k.toString()] = value;
    });
    _translations = merged;
  }

  /// Loads the bundled `en.json` translations as the base fallback layer.
  Future<void> loadFromAssets() async {
    final raw = await rootBundle.loadString(_assetPath);
    final map = jsonDecode(raw) as Map<String, dynamic>;
    _assetTranslations = map.map((k, v) => MapEntry(k, v?.toString() ?? ''));
    _assetsLoaded = true;
    _translations = Map.from(_assetTranslations);
  }

  void clear() => _translations = {};

  bool get hasTranslations => _translations.isNotEmpty;

  /// Resolves [key] to its translated text, falling back to [fallback] or the key itself.
  String translate(String key, {String? fallback}) {
    final val = _translations[key];
    if (val != null && val.isNotEmpty) return val;
    return fallback ?? key;
  }
}
