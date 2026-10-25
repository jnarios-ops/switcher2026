import 'package:flutter/material.dart';

import '../services/app_update_service.dart';
import '../theme.dart';

/// Arranque: si hay versión nueva, descarga e instala. No se puede omitir.
class UpdateGateScreen extends StatefulWidget {
  const UpdateGateScreen({super.key, required this.child});

  final Widget child;

  @override
  State<UpdateGateScreen> createState() => _UpdateGateScreenState();
}

class _UpdateGateScreenState extends State<UpdateGateScreen> {
  final _svc = AppUpdateService();
  bool _ready = false;
  bool _checking = true;
  bool _downloading = false;
  double _progress = 0;
  String? _status;
  UpdateCheckOutcome? _outcome;

  @override
  void initState() {
    super.initState();
    _runCheck();
  }

  Future<void> _runCheck() async {
    setState(() {
      _checking = true;
      _status = 'Buscando actualizaciones…';
    });
    final outcome = await _svc.check();
    if (!mounted) return;
    setState(() {
      _outcome = outcome;
      _checking = false;
    });

    if (outcome.result != UpdateCheckResult.updateAvailable ||
        outcome.release == null) {
      setState(() => _ready = true);
      return;
    }

    await _startDownload(outcome.release!);
  }

  Future<void> _startDownload(AppReleaseInfo release) async {
    setState(() {
      _downloading = true;
      _progress = 0;
      _status =
          'Actualizando ${_outcome?.localVersionName ?? ''} → ${release.versionName}…';
    });
    try {
      await _svc.downloadAndInstall(
        release,
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
      );
      if (!mounted) return;
      setState(() {
        _status =
            'Instala la actualización cuando Android lo pida. Luego vuelve a abrir la app.';
        _downloading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _downloading = false;
        _status = 'Error al actualizar: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) return widget.child;

    final release = _outcome?.release;

    return Scaffold(
      backgroundColor: SwColors.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/brand/logo_switcher.png',
                    height: 36,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.system_update,
                      size: 48,
                      color: SwColors.accent,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Switcher GPS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 28),
                  if (_checking || _downloading)
                    const CircularProgressIndicator(color: SwColors.accent),
                  if (_downloading) ...[
                    const SizedBox(height: 20),
                    LinearProgressIndicator(
                      value: _progress > 0 ? _progress : null,
                      color: SwColors.accent,
                      backgroundColor: SwColors.border,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(_progress * 100).clamp(0, 100).toStringAsFixed(0)}%',
                      style: const TextStyle(color: SwColors.muted),
                    ),
                  ],
                  if (_status != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _status!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                  if (!_checking &&
                      !_downloading &&
                      _status != null &&
                      (_status!.contains('Instala la actualización') ||
                          _status!.startsWith('Error'))) ...[
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: release != null
                          ? () => _startDownload(release)
                          : _runCheck,
                      style: FilledButton.styleFrom(
                          backgroundColor: SwColors.accent),
                      child: Text(
                        _status!.startsWith('Error')
                            ? 'Reintentar'
                            : 'Instalar ahora',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
