import 'dart:io';
import 'package:flutter/services.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class TamperCheck {
  static const String _validSignature =
      '60:A9:71:4E:EB:77:88:97:DD:EC:4A:2F:65:AC:48:AF:BD:71:4F:93:75:62:FD:95:08:9F:50:46:3F:20:1C:DD';

  static const String _validPackage = 'com.alaa.anti_tamper';

  static Future<TamperResult> runAllChecks() async {
    final checks = await Future.wait([
      _checkPackageName(),
      _checkSignature(),
      _checkDebugMode(),
      _checkEmulator(),
      _checkRoot(),
    ]);

    final failed = checks.where((c) => !c.passed).toList();
    return TamperResult(passed: failed.isEmpty, failedChecks: failed);
  }

  static Future<CheckResult> _checkPackageName() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final valid = info.packageName == _validPackage;
      return CheckResult(name: 'Package Name', passed: valid, detail: info.packageName);
    } catch (e) {
      return CheckResult(name: 'Package Name', passed: false, detail: e.toString());
    }
  }

  static Future<CheckResult> _checkSignature() async {
    try {
      const platform = MethodChannel('com.alaa.anti_tamper/security');
      final sig = await platform.invokeMethod<String>('getSignature');
      if (sig == null) return CheckResult(name: 'Signature', passed: false, detail: 'null');
      final valid = sig.trim() == _validSignature;
      return CheckResult(
        name: 'Signature',
        passed: valid,
        detail: valid ? 'Valid' : 'INVALID: $sig',
      );
    } catch (e) {
      return CheckResult(name: 'Signature', passed: false, detail: e.toString());
    }
  }

  static Future<CheckResult> _checkDebugMode() async {
    const isDebug = bool.fromEnvironment('dart.vm.product') == false;
    return CheckResult(
      name: 'Debug Mode',
      passed: !isDebug,
      detail: isDebug ? 'DEBUG BUILD DETECTED' : 'Release OK',
    );
  }

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

class CheckResult {
  final String name;
  final bool passed;
  final String detail;
  const CheckResult({required this.name, required this.passed, required this.detail});
}

class TamperResult {
  final bool passed;
  final List<CheckResult> failedChecks;
  const TamperResult({required this.passed, required this.failedChecks});
}
