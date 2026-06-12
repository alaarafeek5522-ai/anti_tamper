import 'dart:io';
import 'package:flutter/services.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class TamperCheck {
  // ✅ SHA-256 للتوقيع الأصلي — هتحطه بعد أول build
  static const String _validSignature =
      'YOUR_APP_SIGNATURE_SHA256_HERE';

  static const String _validPackage = 'com.alaa.anti_tamper';

  // ─── Main Check ───────────────────────────────────────
  static Future<TamperResult> runAllChecks() async {
    final checks = await Future.wait([
      _checkPackageName(),
      _checkSignature(),
      _checkDebugMode(),
      _checkEmulator(),
      _checkRoot(),
    ]);

    final failed = checks.where((c) => !c.passed).toList();

    return TamperResult(
      passed: failed.isEmpty,
      failedChecks: failed,
    );
  }

  // ─── 1. Package Name ──────────────────────────────────
  static Future<CheckResult> _checkPackageName() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final valid = info.packageName == _validPackage;
      return CheckResult(
        name: 'Package Name',
        passed: valid,
        detail: info.packageName,
      );
    } catch (e) {
      return CheckResult(name: 'Package Name', passed: false, detail: e.toString());
    }
  }

  // ─── 2. Signature ─────────────────────────────────────
  static Future<CheckResult> _checkSignature() async {
    try {
      const platform = MethodChannel('com.alaa.anti_tamper/security');
      final sig = await platform.invokeMethod<String>('getSignature');
      if (sig == null) {
        return CheckResult(name: 'Signature', passed: false, detail: 'null');
      }
      final hash = sha256.convert(utf8.encode(sig)).toString();
      final valid = _validSignature == 'YOUR_APP_SIGNATURE_SHA256_HERE'
          ? true // أول تشغيل — اطبع الـ hash وحطه فوق
          : hash == _validSignature;
      return CheckResult(
        name: 'Signature',
        passed: valid,
        detail: 'SHA256: $hash',
      );
    } catch (e) {
      return CheckResult(name: 'Signature', passed: false, detail: e.toString());
    }
  }

  // ─── 3. Debug Mode ────────────────────────────────────
  static Future<CheckResult> _checkDebugMode() async {
    const isDebug = bool.fromEnvironment('dart.vm.product') == false;
    return CheckResult(
      name: 'Debug Mode',
      passed: !isDebug,
      detail: isDebug ? 'DEBUG BUILD DETECTED' : 'Release OK',
    );
  }

  // ─── 4. Emulator ─────────────────────────────────────
  static Future<CheckResult> _checkEmulator() async {
    try {
      final info = DeviceInfoPlugin();
      final android = await info.androidInfo;
      final isEmu = !android.isPhysicalDevice ||
          android.brand.toLowerCase().contains('generic') ||
          android.model.toLowerCase().contains('sdk') ||
          android.fingerprint.contains('generic') ||
          android.hardware.contains('goldfish') ||
          android.hardware.contains('ranchu');
      return CheckResult(
        name: 'Emulator',
        passed: !isEmu,
        detail: isEmu ? 'EMULATOR DETECTED' : 'Physical Device OK',
      );
    } catch (e) {
      return CheckResult(name: 'Emulator', passed: false, detail: e.toString());
    }
  }

  // ─── 5. Root ──────────────────────────────────────────
  static Future<CheckResult> _checkRoot() async {
    final paths = [
      '/system/bin/su', '/system/xbin/su', '/sbin/su',
      '/data/local/xbin/su', '/data/local/bin/su',
      '/su/bin/su', '/magisk',
    ];
    for (final p in paths) {
      if (await File(p).exists()) {
        return CheckResult(name: 'Root', passed: false, detail: 'Found: $p');
      }
    }
    return CheckResult(name: 'Root', passed: true, detail: 'Clean');
  }
}

// ─── Models ───────────────────────────────────────────
class CheckResult {
  final String name;
  final bool passed;
  final String detail;
  const CheckResult({
    required this.name,
    required this.passed,
    required this.detail,
  });
}

class TamperResult {
  final bool passed;
  final List<CheckResult> failedChecks;
  const TamperResult({required this.passed, required this.failedChecks});
}
