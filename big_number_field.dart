import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// Campo numerico grande con botones +/- para captura rapida con una
/// sola mano. Acepta decimales si [allowDecimals] es true (modo peso).
class BigNumberField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool allowDecimals;
  final double step;
  final ValueChanged<double>? onChanged;

  const BigNumberField({
    super.key,
    required this.controller,
    required this.label,
    this.allowDecimals = false,
    this.step = 1,
    this.onChanged,
  });

  double get _value => double.tryParse(controller.text.replaceAll(',', '.')) ?? 0;

  void _setValue(double v) {
    if (v < 0) v = 0;
    final text = (v == v.roundToDouble() && !allowDecimals)
        ? v.toInt().toString()
        : v.toStringAsFixed(allowDecimals ? 2 : 0);
    controller.text = text;
    controller.selection = TextSelection.collapsed(offset: controller.text.length);
    onChanged?.call(v);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 8),
        Row(
          children: [
            _StepButton(
              icon: Icons.remove,
              onTap: () => _setValue(_value - step),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: controller,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.numberWithOptions(decimal: allowDecimals),
                inputFormatters: allowDecimals
                    ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))]
                    : [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                onChanged: (v) => onChanged?.call(_value),
              ),
            ),
            const SizedBox(width: 10),
            _StepButton(
              icon: Icons.add,
              onTap: () => _setValue(_value + step),
            ),
          ],
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StepButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surfaceAlt,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          width: 56,
          height: 56,
          child: Icon(icon, color: AppTheme.accent, size: 28),
        ),
      ),
    );
  }
}
