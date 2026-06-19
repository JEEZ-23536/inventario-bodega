import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/conteo_record.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';
import '../widgets/big_number_field.dart';
import '../widgets/product_info_card.dart';

/// Pantalla de captura de conteo fisico para un producto.
/// Soporta 3 modos: unidad simple, por paquetes, y por peso.
/// Al guardar, regresa a la pantalla anterior (escaner o busqueda).
class CountCaptureScreen extends StatefulWidget {
  final Product product;
  final bool returnToScanner;

  const CountCaptureScreen({
    super.key,
    required this.product,
    this.returnToScanner = false,
  });

  @override
  State<CountCaptureScreen> createState() => _CountCaptureScreenState();
}

class _CountCaptureScreenState extends State<CountCaptureScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _db = DatabaseHelper.instance;

  // Modo unidad
  final _cantidadCtrl = TextEditingController(text: '0');

  // Modo paquete
  final _numPaquetesCtrl = TextEditingController(text: '0');
  final _piezasPorPaqueteCtrl = TextEditingController(text: '0');

  // Modo peso
  final _pesoMuestraCtrl = TextEditingController(text: '0');
  final _piezasMuestraCtrl = TextEditingController(text: '0');
  final _pesoTotalCtrl = TextEditingController(text: '0');

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    for (final c in [
      _cantidadCtrl,
      _numPaquetesCtrl,
      _piezasPorPaqueteCtrl,
      _pesoMuestraCtrl,
      _piezasMuestraCtrl,
      _pesoTotalCtrl,
    ]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _cantidadCtrl.dispose();
    _numPaquetesCtrl.dispose();
    _piezasPorPaqueteCtrl.dispose();
    _pesoMuestraCtrl.dispose();
    _piezasMuestraCtrl.dispose();
    _pesoTotalCtrl.dispose();
    super.dispose();
  }

  double _num(TextEditingController c) =>
      double.tryParse(c.text.replaceAll(',', '.')) ?? 0;

  double get _totalPaquetes => _num(_numPaquetesCtrl) * _num(_piezasPorPaqueteCtrl);

  double get _totalPeso {
    final pesoMuestra = _num(_pesoMuestraCtrl);
    final piezasMuestra = _num(_piezasMuestraCtrl);
    final pesoTotal = _num(_pesoTotalCtrl);
    if (pesoMuestra <= 0) return 0;
    return (piezasMuestra / pesoMuestra) * pesoTotal;
  }

  String _formatNum(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }

  Future<void> _save() async {
    double cantidad;
    MetodoConteo metodo;
    String? detalle;

    switch (_tabController.index) {
      case 0:
        cantidad = _num(_cantidadCtrl);
        metodo = MetodoConteo.unidad;
        break;
      case 1:
        cantidad = _totalPaquetes;
        metodo = MetodoConteo.paquete;
        detalle =
            '${_formatNum(_num(_numPaquetesCtrl))} paquetes x ${_formatNum(_num(_piezasPorPaqueteCtrl))} pzas';
        break;
      default:
        cantidad = _totalPeso;
        metodo = MetodoConteo.peso;
        detalle =
            'Muestra: ${_formatNum(_num(_piezasMuestraCtrl))} pzas / ${_formatNum(_num(_pesoMuestraCtrl))} '
            '· Total: ${_formatNum(_num(_pesoTotalCtrl))}';
    }

    if (cantidad <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa una cantidad mayor a cero antes de guardar.')),
      );
      return;
    }

    setState(() => _saving = true);

    await _db.insertConteo(ConteoRecord(
      clave1: widget.product.clave1,
      cantidad: cantidad,
      metodo: metodo,
      detalle: detalle,
      fecha: DateTime.now(),
    ));

    if (!mounted) return;
    setState(() => _saving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Guardado: ${_formatNum(cantidad)} pzas de ${widget.product.clave1}')),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CAPTURAR CONTEO'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'UNIDAD', icon: Icon(Icons.inventory, size: 18)),
            Tab(text: 'PAQUETE', icon: Icon(Icons.inbox, size: 18)),
            Tab(text: 'PESO', icon: Icon(Icons.scale, size: 18)),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              ProductInfoCard(
                clave1: widget.product.clave1,
                descripcion: widget.product.descripcion,
                existenciaSistema: widget.product.existencia,
              ),
              const SizedBox(height: 20),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildUnidadTab(),
                    _buildPaqueteTab(),
                    _buildPesoTab(),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : const Icon(Icons.check_circle),
                label: Text(_saving ? 'Guardando...' : 'Guardar y continuar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnidadTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          BigNumberField(
            controller: _cantidadCtrl,
            label: 'Cantidad fisica encontrada',
          ),
        ],
      ),
    );
  }

  Widget _buildPaqueteTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          BigNumberField(
            controller: _numPaquetesCtrl,
            label: 'Numero de paquetes',
          ),
          const SizedBox(height: 20),
          BigNumberField(
            controller: _piezasPorPaqueteCtrl,
            label: 'Piezas por paquete',
          ),
          const SizedBox(height: 24),
          _TotalDisplay(label: 'Cantidad total calculada', value: _totalPaquetes),
        ],
      ),
    );
  }

  Widget _buildPesoTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          BigNumberField(
            controller: _pesoMuestraCtrl,
            label: 'Peso muestra (ej. kg)',
            allowDecimals: true,
            step: 0.1,
          ),
          const SizedBox(height: 20),
          BigNumberField(
            controller: _piezasMuestraCtrl,
            label: 'Piezas en la muestra',
          ),
          const SizedBox(height: 20),
          BigNumberField(
            controller: _pesoTotalCtrl,
            label: 'Peso total encontrado',
            allowDecimals: true,
            step: 0.1,
          ),
          const SizedBox(height: 24),
          _TotalDisplay(label: 'Piezas estimadas calculadas', value: _totalPeso),
        ],
      ),
    );
  }
}

class _TotalDisplay extends StatelessWidget {
  final String label;
  final double value;

  const _TotalDisplay({required this.label, required this.value});

  String _formatNum(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.accent, width: 1.5),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 6),
          Text(
            _formatNum(value),
            style: const TextStyle(color: AppTheme.accent, fontSize: 32, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
