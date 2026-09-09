// ignore_for_file: avoid_print
//
// ─── apply_config.dart ──────────────────────────────────────────────────────
// Reads the active environment from
//   lib/core/configs/app_config.dart  →  static const String environment
// loads the matching `env/<environment>.json` file, then propagates its values
// into:
//   • lib/core/configs/app_config.dart       (BASE_URL, SOCKET_BASE_URL)
//
// Run from the project root after editing AppConfig.environment OR an env JSON:
//
//   dart run tool/apply_config.dart
//
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'dart:io';

void main() {
  final appConfig = File('lib/core/configs/app_config.dart');

  if (!appConfig.existsSync()) _fail('AppConfig not found at ${appConfig.path}');

  // 1. Resolve active environment
  final src = appConfig.readAsStringSync();
  final environment = _readConst(src, 'environment');
  print('• environment    = $environment');

  // 2. Load env/<environment>.json
  final envFile = File('env/$environment.json');
  if (!envFile.existsSync()) {
    final available = Directory('env').existsSync()
        ? Directory('env').listSync().whereType<File>().map((f) => f.path).join(', ')
        : '(env/ folder missing)';
    _fail(
      'Env file not found: ${envFile.path}\n'
      '   AppConfig.environment is "$environment".\n'
      '   Available: $available',
    );
  }

  final json = jsonDecode(envFile.readAsStringSync()) as Map<String, dynamic>;
  final baseUrl = _readJson(json, 'BASE_URL', envFile.path);
  final socketBaseUrl = _readJson(json, 'SOCKET_BASE_URL', envFile.path);

  print('• BASE_URL        = $baseUrl');
  print('• SOCKET_BASE_URL = $socketBaseUrl');

  // 3. Patch consumer
  _patchAppConfig(appConfig, baseUrl: baseUrl, socketBaseUrl: socketBaseUrl);

  print('\n✅ Synced "$environment" env into AppConfig.');
  print('   Now run:  flutter clean && flutter run');
}

// ─── Readers ────────────────────────────────────────────────────────────────

String _readConst(String src, String name) {
  final pattern = RegExp(
    '''static\\s+const\\s+String\\s+$name\\s*=\\s*['"]([^'"]+)['"]\\s*;''',
  );
  final match = pattern.firstMatch(src);
  if (match == null) _fail('Constant `$name` not found in AppConfig');
  return match.group(1)!;
}

String _readJson(Map<String, dynamic> json, String key, String path) {
  final value = json[key];
  if (value is! String || value.isEmpty) {
    _fail('Key `$key` missing or empty in $path');
  }
  return value;
}

// ─── Writers ────────────────────────────────────────────────────────────────

void _patchAppConfig(File file, {required String baseUrl, required String socketBaseUrl}) {
  final original = file.readAsStringSync();

  var patched = original;
  patched = _replaceConst(patched, 'baseUrl', baseUrl);
  patched = _replaceConst(patched, 'socketBaseUrl', socketBaseUrl);

  if (patched != original) {
    file.writeAsStringSync(patched);
    print('✓ Patched ${file.path}');
  } else {
    print('• ${file.path} already up to date');
  }
}

String _replaceConst(String src, String name, String value) {
  final pattern = RegExp(
    '''(static\\s+const\\s+String\\s+$name\\s*=\\s*['"])([^'"]*)(['"]\\s*;)''',
  );
  if (!pattern.hasMatch(src)) {
    _fail('Constant `$name` not found in AppConfig — cannot sync');
  }
  return src.replaceFirstMapped(
    pattern,
    (m) => '${m.group(1)}$value${m.group(3)}',
  );
}

Never _fail(String msg) {
  stderr.writeln('❌ $msg');
  exit(1);
}
