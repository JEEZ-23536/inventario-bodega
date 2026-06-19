/// Metodo utilizado para registrar un conteo fisico.
enum MetodoConteo { unidad, paquete, peso, manual }

extension MetodoConteoX on MetodoConteo {
  String get value => toString().split('.').last;

  String get label {
    switch (this) {
      case MetodoConteo.unidad:
        return 'Unidad';
      case MetodoConteo.paquete:
        return 'Paquete';
      case MetodoConteo.peso:
        return 'Peso';
      case MetodoConteo.manual:
        return 'Manual';
    }
  }

  static MetodoConteo fromValue(String v) => MetodoConteo.values.firstWhere(
        (e) => e.value == v,
        orElse: () => MetodoConteo.unidad,
      );
}

/// Un registro individual de conteo fisico para un producto (clave1).
/// Varios registros para la misma clave se suman para obtener
/// la existencia fisica total de ese producto.
class ConteoRecord {
  final int? id;
  final String clave1;
  final double cantidad;
  final MetodoConteo metodo;
  final String? detalle;
  final DateTime fecha;

  const ConteoRecord({
    this.id,
    required this.clave1,
    required this.cantidad,
    required this.metodo,
    this.detalle,
    required this.fecha,
  });

  Map<String, Object?> toMap() {
    final map = <String, Object?>{
      'clave1': clave1,
      'cantidad': cantidad,
      'metodo': metodo.value,
      'detalle': detalle,
      'fecha': fecha.toIso8601String(),
    };
    if (id != null) map['id'] = id;
    return map;
  }

  factory ConteoRecord.fromMap(Map<String, Object?> map) => ConteoRecord(
        id: map['id'] as int?,
        clave1: map['clave1'] as String,
        cantidad: (map['cantidad'] as num).toDouble(),
        metodo: MetodoConteoX.fromValue(map['metodo'] as String? ?? 'unidad'),
        detalle: map['detalle'] as String?,
        fecha: DateTime.parse(map['fecha'] as String),
      );
}
