/// Fila de reporte: compara la existencia del sistema (SICAR) contra
/// la existencia fisica capturada durante el conteo.
class ReportRow {
  final String clave1;
  final String descripcion;
  final double existenciaSistema;
  final double existenciaFisica;
  final int numConteos;

  const ReportRow({
    required this.clave1,
    required this.descripcion,
    required this.existenciaSistema,
    required this.existenciaFisica,
    required this.numConteos,
  });

  double get diferencia => existenciaFisica - existenciaSistema;

  bool get contado => numConteos > 0;
  bool get esFaltante => contado && diferencia < 0;
  bool get esSobrante => contado && diferencia > 0;
  bool get sinDiferencia => contado && diferencia == 0;

  factory ReportRow.fromMap(Map<String, Object?> map) => ReportRow(
        clave1: map['clave1'] as String,
        descripcion: (map['descripcion'] as String?) ?? '',
        existenciaSistema: (map['existencia'] as num?)?.toDouble() ?? 0,
        existenciaFisica: (map['existenciaFisica'] as num?)?.toDouble() ?? 0,
        numConteos: (map['numConteos'] as num?)?.toInt() ?? 0,
      );
}
