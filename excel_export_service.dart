import 'dart:io';

import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/report_row.dart';

class ExcelExportService {
  /// Genera un archivo Excel con el reporte de diferencias y devuelve
  /// la ruta del archivo creado en el almacenamiento de la app.
  Future<File> exportReport(List<ReportRow> rows) async {
    final excelFile = Excel.createExcel();
    final defaultSheetName = excelFile.getDefaultSheet()!;
    excelFile.rename(defaultSheetName, 'Reporte');
    final sheet = excelFile['Reporte'];

    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#FFA000'),
      fontColorHex: ExcelColor.black,
    );

    const headers = [
      'Codigo',
      'Descripcion',
      'Existencia sistema',
      'Existencia fisica',
      'Diferencia',
    ];

    for (int c = 0; c < headers.length; c++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0));
      cell.value = TextCellValue(headers[c]);
      cell.cellStyle = headerStyle;
    }

    int rowIndex = 1;
    for (final row in rows) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value =
          TextCellValue(row.clave1);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value =
          TextCellValue(row.descripcion);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).value =
          DoubleCellValue(row.existenciaSistema);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex)).value =
          row.contado ? DoubleCellValue(row.existenciaFisica) : TextCellValue('Sin contar');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex)).value =
          row.contado ? DoubleCellValue(row.diferencia) : TextCellValue('-');
      rowIndex++;
    }

    sheet.setColumnWidth(0, 16);
    sheet.setColumnWidth(1, 40);
    sheet.setColumnWidth(2, 18);
    sheet.setColumnWidth(3, 18);
    sheet.setColumnWidth(4, 14);

    final bytes = excelFile.encode();
    if (bytes == null) {
      throw Exception('No se pudo generar el archivo Excel.');
    }

    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = '${dir.path}/reporte_inventario_$timestamp.xlsx';
    final file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  /// Abre el dialogo nativo para compartir/guardar el archivo exportado.
  Future<void> shareFile(File file) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'Reporte de inventario',
      ),
    );
  }
}
