import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Tarjeta grande que muestra los datos clave de un producto:
/// codigo, descripcion y existencia actual del sistema.
class ProductInfoCard extends StatelessWidget {
  final String clave1;
  final String descripcion;
  final double existenciaSistema;

  const ProductInfoCard({
    super.key,
    required this.clave1,
    required this.descripcion,
    required this.existenciaSistema,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.qr_code_2, color: AppTheme.accent, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  clave1,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accent,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            descripcion,
            style: const TextStyle(fontSize: 17, color: Colors.white, height: 1.3),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceAlt,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.inventory_2_outlined, color: Colors.white70, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Existencia sistema: ',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Text(
                  _formatNum(existenciaSistema),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatNum(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }
}
