import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/report_row.dart';
import '../services/excel_export_service.dart';
import '../theme/app_theme.dart';

enum _Filtro { todos, faltantes, sobrantes, sinContar, exactos }

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _db = DatabaseHelper.instance;
  final _exportService = ExcelExportService();

  List<ReportRow> _allRows = [];
  _Filtro _filtro = _Filtro.todos;
  bool _loading = true;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final rows = await _db.getReport();
    if (!mounted) return;
    setState(() {
      _allRows = rows;
      _loading = false;
    });
  }

  List<ReportRow> get _filteredRows {
    switch (_filtro) {
      case _Filtro.faltantes:
        return _allRows.where((r) => r.esFaltante).toList();
      case _Filtro.sobrantes:
        return _allRows.where((r) => r.esSobrante).toList();
      case _Filtro.sinContar:
        return _allRows.where((r) => !r.contado).toList();
      case _Filtro.exactos:
        return _allRows.where((r) => r.sinDiferencia).toList();
      case _Filtro.todos:
        return _allRows;
    }
  }

  Future<void> _export() async {
    setState(() => _exporting = true);
    try {
      final file = await _exportService.exportReport(_allRows);
      await _exportService.shareFile(file);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al exportar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  String _formatNum(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final faltantes = _allRows.where((r) => r.esFaltante).length;
    final sobrantes = _allRows.where((r) => r.esSobrante).length;
    final sinContar = _allRows.where((r) => !r.contado).length;
    final exactos = _allRows.where((r) => r.sinDiferencia).length;

    return Scaffold(
      appBar: AppBar(title: const Text('REPORTE DE DIFERENCIAS')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _SummaryChip(
                            label: 'Faltantes',
                            count: faltantes,
                            color: AppTheme.danger,
                            selected: _filtro == _Filtro.faltantes,
                            onTap: () => setState(() => _filtro = _Filtro.faltantes),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _SummaryChip(
                            label: 'Sobrantes',
                            count: sobrantes,
                            color: AppTheme.success,
                            selected: _filtro == _Filtro.sobrantes,
                            onTap: () => setState(() => _filtro = _Filtro.sobrantes),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _SummaryChip(
                            label: 'Sin contar',
                            count: sinContar,
                            color: AppTheme.neutral,
                            selected: _filtro == _Filtro.sinContar,
                            onTap: () => setState(() => _filtro = _Filtro.sinContar),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        ChoiceChip(
                          label: const Text('Todos'),
                          selected: _filtro == _Filtro.todos,
                          onSelected: (_) => setState(() => _filtro = _Filtro.todos),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: Text('Exactos ($exactos)'),
                          selected: _filtro == _Filtro.exactos,
                          onSelected: (_) => setState(() => _filtro = _Filtro.exactos),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _filteredRows.isEmpty
                        ? const Center(
                            child: Text('Sin registros para este filtro',
                                style: TextStyle(color: Colors.white54)),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 16),
                            itemCount: _filteredRows.length,
                            itemBuilder: (context, index) {
                              final r = _filteredRows[index];
                              return _ReportTile(row: r, formatNum: _formatNum);
                            },
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton.icon(
                      onPressed: _exporting || _allRows.isEmpty ? null : _export,
                      icon: _exporting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                            )
                          : const Icon(Icons.ios_share),
                      label: Text(_exporting ? 'Generando...' : 'Exportar a Excel'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _SummaryChip({
    required this.label,
    required this.count,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.2) : AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? color : Colors.transparent, width: 1.5),
        ),
        child: Column(
          children: [
            Text('$count',
                style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  final ReportRow row;
  final String Function(double) formatNum;

  const _ReportTile({required this.row, required this.formatNum});

  Color get _diffColor {
    if (!row.contado) return AppTheme.neutral;
    if (row.esFaltante) return AppTheme.danger;
    if (row.esSobrante) return AppTheme.success;
    return Colors.white60;
  }

  String get _diffText {
    if (!row.contado) return 'Sin contar';
    final d = row.diferencia;
    final sign = d > 0 ? '+' : '';
    return '$sign${formatNum(d)}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.descripcion,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${row.clave1} · Sistema: ${formatNum(row.existenciaSistema)} · Fisico: '
                    '${row.contado ? formatNum(row.existenciaFisica) : "-"}',
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _diffColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _diffText,
                style: TextStyle(color: _diffColor, fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
