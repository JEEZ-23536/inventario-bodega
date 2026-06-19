import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../database/database_helper.dart';
import '../theme/app_theme.dart';
import 'count_capture_screen.dart';

/// Pantalla de escaneo continuo: detecta un codigo, busca el producto
/// por clave1, y al guardar el conteo regresa automaticamente aqui
/// para seguir escaneando el siguiente producto.
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  final _db = DatabaseHelper.instance;

  bool _processing = false;
  String? _lastNotFound;

  // Estado del permiso de camara: null = verificando, true = concedido,
  // false = denegado (se muestra pantalla para abrir Ajustes).
  bool? _cameraGranted;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.camera.status;
    if (status.isGranted) {
      setState(() => _cameraGranted = true);
      return;
    }
    final result = await Permission.camera.request();
    if (!mounted) return;
    setState(() => _cameraGranted = result.isGranted);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    final barcode = capture.barcodes.firstOrNull;
    final code = barcode?.rawValue?.trim();
    if (code == null || code.isEmpty) return;

    setState(() {
      _processing = true;
      _lastNotFound = null;
    });

    await _controller.stop();

    final product = await _db.getProductByClave(code);

    if (!mounted) return;

    if (product == null) {
      setState(() {
        _processing = false;
        _lastNotFound = code;
      });
      await _controller.start();
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CountCaptureScreen(product: product, returnToScanner: true),
      ),
    );

    if (!mounted) return;
    setState(() => _processing = false);
    await _controller.start();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraGranted == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('ESCANEAR PRODUCTO')),
        body: const Center(child: CircularProgressIndicator(color: AppTheme.accent)),
      );
    }

    if (_cameraGranted == false) {
      return Scaffold(
        appBar: AppBar(title: const Text('ESCANEAR PRODUCTO')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.camera_alt_outlined, color: AppTheme.accent, size: 56),
                const SizedBox(height: 16),
                const Text(
                  'Se necesita permiso de camara para escanear codigos de barras.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => openAppSettings(),
                  icon: const Icon(Icons.settings),
                  label: const Text('Abrir ajustes'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _checkPermission,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('ESCANEAR PRODUCTO'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          // Marco visual de escaneo
          Center(
            child: Container(
              width: 260,
              height: 180,
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.accent, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          if (_processing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: AppTheme.accent),
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
              child: _lastNotFound != null
                  ? Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.danger.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.white),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Codigo "$_lastNotFound" no encontrado en el catalogo.',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    )
                  : const Text(
                      'Apunta la camara al codigo de barras',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
