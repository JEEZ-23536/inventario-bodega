import 'dart:io';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';

import '../models/product.dart';

class ExcelImportResult {
  final List<Product> products;
  final int skippedRows;
  final String sheetName;

  ExcelImportResult({
    required this.products,
    required this.skippedRows,
    required this.sheetName,
  });
}

/// Excepcion lanzada cuando el archivo no tiene las columnas obligatorias.
class ExcelImportException implements Exception {
  final String message;
  ExcelImportException(this.message);
  @override
  String toString() => message;
}

class ExcelImportService {
  /// Abre el selector de archivos del sistema y permite elegir un .xlsx.
  /// Devuelve null si el usuario cancela.
  Future<File?> pickExcelFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      withData: false,
    );
    if (result == null || result.files.single.path == null) return null;
    return File(result.files.single.path!);
  }

  /// Normaliza un encabezado de columna: minusculas, sin acentos, sin
  /// espacios extra, sin asteriscos (SICAR marca obligatorios con "*").
  String _normalizeHeader(String raw) {
    var s = raw.trim().toLowerCase();
    s = s.replaceAll('*', '').trim();
    const accents = {
      'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ñ': 'n',
    };
    accents.forEach((a, b) => s = s.replaceAll(a, b));
    s = s.replaceAll(RegExp(r'\s+'), '');
    return s;
  }

  /// Variantes aceptadas de cada columna esperada (ya normalizadas).
  static const Map<String, List<String>> _columnAliases = {
    'clave1': ['clave1', 'clave', 'codigo', 'clavesat', 'sku'],
    'descripcion': ['descripcion', 'desc', 'nombre', 'articulo', 'producto'],
    'costo': ['costo', 'preciocosto', 'costo1'],
    'precio1': ['precio1', 'precio', 'preciovta', 'precioventa'],
    'existencia': ['existencia', 'existencias', 'stock', 'inventario', 'cantidad'],
  };

  int? _findColumn(List<String> normalizedHeaders, String field) {
    final aliases = _columnAliases[field]!;
    for (final alias in aliases) {
      final idx = normalizedHeaders.indexOf(alias);
      if (idx != -1) return idx;
    }
    return null;
  }

  double _parseNumber(Object? value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    final s = value.toString().trim().replaceAll(',', '');
    if (s.isEmpty) return 0;
    return double.tryParse(s) ?? 0;
  }

  String _parseText(Object? value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  /// Lee el archivo Excel y mapea las columnas requeridas:
  /// clave1 *, descripcion *, costo, precio1, existencia.
  /// Busca automaticamente la fila de encabezado dentro de las primeras
  /// 10 filas de la primera hoja con datos.
  Future<ExcelImportResult> importFromFile(File file) async {
    final bytes = await file.readAsBytes();
    final excelFile = Excel.decodeBytes(bytes);

    if (excelFile.tables.isEmpty) {
      throw ExcelImportException('El archivo no contiene hojas con datos.');
    }

    // Usa la primera hoja que tenga al menos una fila.
    String? sheetName;
    Sheet? sheet;
    for (final name in excelFile.tables.keys) {
      final candidate = excelFile.tables[name]!;
      if (candidate.maxRows > 0) {
        sheetName = name;
        sheet = candidate;
        break;
      }
    }
    if (sheet == null) {
      throw ExcelImportException('El archivo no contiene filas con datos.');
    }

    final rows = sheet.rows;

    // Busca la fila de encabezado: la primera fila que contenga
    // tanto una variante de "clave1" como de "descripcion".
    int headerRowIndex = -1;
    List<String> normalizedHeaders = [];
    final maxScan = rows.length < 10 ? rows.length : 10;
    for (int r = 0; r < maxScan; r++) {
      final candidateHeaders = rows[r]
          .map((cell) => _normalizeHeader(cell?.value?.toString() ?? ''))
          .toList();
      final hasClave = _findColumn(candidateHeaders, 'clave1') != null;
      final hasDesc = _findColumn(candidateHeaders, 'descripcion') != null;
      if (hasClave && hasDesc) {
        headerRowIndex = r;
        normalizedHeaders = candidateHeaders;
        break;
      }
    }

    if (headerRowIndex == -1) {
      throw ExcelImportException(
        'No se encontraron las columnas obligatorias "clave1" y "descripcion" '
        'en las primeras filas del archivo. Verifica que sea un export valido de SICAR.',
      );
    }

    final idxClave = _findColumn(normalizedHeaders, 'clave1')!;
    final idxDesc = _findColumn(normalizedHeaders, 'descripcion')!;
    final idxCosto = _findColumn(normalizedHeaders, 'costo');
    final idxPrecio = _findColumn(normalizedHeaders, 'precio1');
    final idxExistencia = _findColumn(normalizedHeaders, 'existencia');

    final products = <Product>[];
    int skipped = 0;

    for (int r = headerRowIndex + 1; r < rows.length; r++) {
      final row = rows[r];
      if (row.isEmpty) continue;

      String cellAt(int idx) {
        if (idx >= row.length) return '';
        return row[idx]?.value?.toString() ?? '';
      }

      final clave = _parseText(cellAt(idxClave));
      final desc = _parseText(cellAt(idxDesc));

      if (clave.isEmpty || desc.isEmpty) {
        skipped++;
        continue;
      }

      products.add(Product(
        clave1: clave,
        descripcion: desc,
        costo: idxCosto != null ? _parseNumber(cellAt(idxCosto)) : 0,
        precio1: idxPrecio != null ? _parseNumber(cellAt(idxPrecio)) : 0,
        existencia: idxExistencia != null ? _parseNumber(cellAt(idxExistencia)) : 0,
      ));
    }

    if (products.isEmpty) {
      throw ExcelImportException('No se encontraron productos validos en el archivo.');
    }

    return ExcelImportResult(
      products: products,
      skippedRows: skipped,
      sheetName: sheetName!,
    );
  }
}
