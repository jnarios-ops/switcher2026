import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';

class AppReleaseInfo {
  final String versionName;
  final int versionCode;
  final String apkUrl;
  final bool forceUpdate;
  final String notes;

  const AppReleaseInfo({
    required this.versionName,
    required this.versionCode,
    required this.apkUrl,
    this.forceUpdate = true,
    this.notes = '',
  });
}

enum UpdateCheckResult {
  upToDate,
  updateAvailable,
  skipped,
}

class UpdateCheckOutcome {
  final UpdateCheckResult result;
  final AppReleaseInfo? release;
  final int localVersionCode;
  final String localVersionName;
  final String? error;

  const UpdateCheckOutcome({
    required this.result,
    this.release,
    required this.localVersionCode,
    required this.localVersionName,
    this.error,
  });
}

/// Consulta `app_releases` filtrado por `app_id=gps` y descarga el APK.
class AppUpdateService {
  AppUpdateService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  static const bucket = 'app-releases';

  /// Flutter `--split-per-abi` genera versionCode = offset + buildNumber.
  static int logicalVersionCode(int code) {
    if (code <= 0) return 0;
    if (code < 1000) return code;
    return code % 1000;
  }

  Future<UpdateCheckOutcome> check() async {
    final info = await PackageInfo.fromPlatform();
    final localRaw = int.tryParse(info.buildNumber) ?? 0;
    final localLogical = logicalVersionCode(localRaw);
    final localName = info.version;

    if (kIsWeb || (!Platform.isAndroid)) {
      return UpdateCheckOutcome(
        result: UpdateCheckResult.skipped,
        localVersionCode: localLogical,
        localVersionName: localName,
      );
    }

    try {
      final rows = await _client
          .from('app_releases')
          .select(
              'app_id, version_name, version_code, apk_path, apk_url, force_update, notes')
          .eq('platform', 'android')
          .eq('app_id', AppConfig.appId)
          .eq('active', true)
          .order('version_code', ascending: false)
          .limit(5);

      final list = (rows as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      if (list.isEmpty) {
        return UpdateCheckOutcome(
          result: UpdateCheckResult.upToDate,
          localVersionCode: localLogical,
          localVersionName: localName,
        );
      }

      Map<String, dynamic> row = list.first;
      var bestLogical = logicalVersionCode(
          (row['version_code'] as num?)?.toInt() ?? 0);
      for (final r in list) {
        final c = logicalVersionCode((r['version_code'] as num?)?.toInt() ?? 0);
        if (c > bestLogical) {
          bestLogical = c;
          row = r;
        }
      }

      final remoteRaw = (row['version_code'] as num?)?.toInt() ?? 0;
      final remoteLogical = logicalVersionCode(remoteRaw);
      final path = '${row['apk_path'] ?? ''}';
      final urlOverride = '${row['apk_url'] ?? ''}'.trim();
      final apkUrl = urlOverride.isNotEmpty
          ? urlOverride
          : '${AppConfig.supabaseUrl}/storage/v1/object/public/$bucket/$path';

      final release = AppReleaseInfo(
        versionName: '${row['version_name'] ?? ''}',
        versionCode: remoteLogical,
        apkUrl: apkUrl,
        forceUpdate: row['force_update'] != false,
        notes: '${row['notes'] ?? ''}',
      );

      if (remoteLogical > localLogical) {
        return UpdateCheckOutcome(
          result: UpdateCheckResult.updateAvailable,
          release: release,
          localVersionCode: localLogical,
          localVersionName: localName,
        );
      }

      return UpdateCheckOutcome(
        result: UpdateCheckResult.upToDate,
        release: release,
        localVersionCode: localLogical,
        localVersionName: localName,
      );
    } catch (e) {
      return UpdateCheckOutcome(
        result: UpdateCheckResult.skipped,
        localVersionCode: localLogical,
        localVersionName: localName,
        error: '$e',
      );
    }
  }

  Future<void> downloadAndInstall(
    AppReleaseInfo release, {
    void Function(double progress)? onProgress,
  }) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/switcher-gps-${release.versionCode}.apk');
    if (await file.exists()) {
      try {
        await file.delete();
      } catch (_) {}
    }

    final uri = Uri.parse(release.apkUrl);
    final encoded = uri.replace(
      pathSegments: uri.pathSegments.map(Uri.encodeComponent).toList(),
    );

    final req = http.Request('GET', encoded);
    final res = await http.Client().send(req);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('No se pudo descargar el APK (${res.statusCode})');
    }

    final total = res.contentLength ?? 0;
    final sink = file.openWrite();
    var received = 0;
    await for (final chunk in res.stream) {
      sink.add(chunk);
      received += chunk.length;
      if (total > 0 && onProgress != null) {
        onProgress(received / total);
      }
    }
    await sink.close();

    final result = await OpenFilex.open(
      file.path,
      type: 'application/vnd.android.package-archive',
    );
    if (result.type != ResultType.done) {
      throw Exception(
          result.message.isNotEmpty ? result.message : 'No se pudo abrir el instalador');
    }
  }
}
