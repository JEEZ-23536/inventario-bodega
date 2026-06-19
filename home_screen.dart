import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../services/excel_import_service.dart';
import '../theme/app_theme.dart';
import 'manual_search_screen.dart';
import 'reports_screen.dart';
import 'scanner_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _excelService = ExcelImportService();
  final _db = DatabaseHelper.instance;

  int _productsCount = 0;
  int _conteosCount = 0;
  bool _importing = false;

  @override
  void initState() {
    super.initState();
    _refreshStats();
  }

  Future<void> _refreshStats() async {
    final products = await _db.getProductsCount();
    final conteos = await _db.getConteosCount();
    if (!mounted) return;
    setState(() {
      _productsCount = products;
      _conteosCount = conteos;
    });
  }

  Future<void> _importExcel() async {
    try {
      final file = await _excelService.pickExcelFile();
      if (file == null) return;

      setState(() => _importing = true);
      final result = await _excelService.importFromFile(file);
      await _db.upsertProducts(result.products);
      setState(() => _importing = false);
      await _refreshStats();

      if (!mounted) return;
      final msg = result.skippedRows > 0
          ? '${result.products.length} productos importados. ${result.skippedRows} filas omitidas por datos incompletos.'
          : '${result.products.length} productos importados correctamente.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      setState(() => _importing = false);
      if (!mounted) return;
      _showError(e.toString());
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: AppTheme.danger),
            SizedBox(width: 10),
            Text('Error al importar'),
          ],
        ),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar')),
        ],
      ),
    );
  }

  Future<void> _confirmNuevaSesion() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Nueva sesion de conteo'),
        content: const Text(
          'Esto borrara todos los conteos fisicos capturados (el catalogo de productos NO se borra). '
          '¿Deseas continuar?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Borrar conteos', style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _db.resetConteos();
      await _refreshStats();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conteos reiniciados.')),
      );
    }
  }

  bool get _hasCatalog => _productsCount > 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('INVENTARIO DE BODEGA'),
        actions: [
          IconButton(
            tooltip: 'Nueva sesion de conteo',
            icon: const Icon(Icons.restart_alt),
            onPressed: _hasCatalog ? _confirmNuevaSesion : null,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _StatsBar(productsCount: _productsCount, conteosCount: _conteosCount),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _importing ? null : _importExcel,
                icon: _importing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : const Icon(Icons.upload_file),
                label: Text(_importing ? 'Importando...' : 'Importar Excel (SICAR)'),
              ),
              const SizedBox(height: 28),
              const Divider(),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: [
                    _MenuTile(
                      icon: Icons.qr_code_scanner,
                      title: 'Escanear codigo',
                      subtitle: 'Conteo por escaneo de codigo de barras',
                      enabled: _hasCatalog,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ScannerScreen()),
                      ).then((_) => _refreshStats()),
                    ),
                    _MenuTile(
                      icon: Icons.search,
                      title: 'Buscar producto',
                      subtitle: 'Inventario sin escaneo, busqueda por nombre',
                      enabled: _hasCatalog,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ManualSearchScreen()),
                      ).then((_) => _refreshStats()),
                    ),
                    _MenuTile(
                      icon: Icons.fact_check_outlined,
                      title: 'Reportes y diferencias',
                      subtitle: 'Faltantes, sobrantes y exportar a Excel',
                      enabled: _hasCatalog,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ReportsScreen()),
                      ),
                    ),
                  ],
                ),
              ),
              if (!_hasCatalog)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Importa un Excel de SICAR para comenzar a contar.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsBar extends StatelessWidget {
  final int productsCount;
  final int conteosCount;

  const _StatsBar({required this.productsCount, required this.conteosCount});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatCard(label: 'Productos', value: '$productsCount', icon: Icons.inventory_2)),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(label: 'Conteos', value: '$conteosCount', icon: Icons.check_circle_outline)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.accent, size: 24),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.white60)),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: enabled ? AppTheme.accent.withValues(alpha: 0.15) : Colors.white10,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: enabled ? AppTheme.accent : Colors.white30, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: enabled ? Colors.white : Colors.white30,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 13, color: enabled ? Colors.white60 : Colors.white24),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: enabled ? Colors.white38 : Colors.white12),
            ],
          ),
        ),
      ),
    );
  }
}
