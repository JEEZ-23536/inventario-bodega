import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/conteo_record.dart';
import '../models/product.dart';
import '../models/report_row.dart';

/// Acceso centralizado a la base de datos SQLite local.
class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'inventario_bodega.db');
    return openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE productos (
        clave1 TEXT PRIMARY KEY,
        descripcion TEXT NOT NULL,
        costo REAL NOT NULL DEFAULT 0,
        precio1 REAL NOT NULL DEFAULT 0,
        existencia REAL NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE conteos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        clave1 TEXT NOT NULL,
        cantidad REAL NOT NULL,
        metodo TEXT NOT NULL,
        detalle TEXT,
        fecha TEXT NOT NULL
      )
    ''');

    await db.execute('CREATE INDEX idx_conteos_clave1 ON conteos (clave1)');
    await db.execute('CREATE INDEX idx_productos_descripcion ON productos (descripcion)');
  }

  // ---------------------------------------------------------------------
  // PRODUCTOS
  // ---------------------------------------------------------------------

  /// Inserta o actualiza (upsert) productos importados desde Excel.
  /// No borra conteos existentes, asi se puede re-importar el catalogo
  /// actualizado sin perder el trabajo de conteo ya capturado.
  Future<void> upsertProducts(List<Product> products) async {
    final db = await database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final p in products) {
        batch.insert('productos', p.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    });
  }

  Future<Product?> getProductByClave(String clave1) async {
    final db = await database;
    final rows = await db.query(
      'productos',
      where: 'clave1 = ?',
      whereArgs: [clave1.trim()],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Product.fromMap(rows.first);
  }

  Future<List<Product>> searchProductsByName(String query) async {
    final db = await database;
    final q = query.trim();
    if (q.isEmpty) {
      final rows = await db.query('productos', orderBy: 'descripcion ASC', limit: 50);
      return rows.map(Product.fromMap).toList();
    }
    final rows = await db.query(
      'productos',
      where: 'descripcion LIKE ? OR clave1 LIKE ?',
      whereArgs: ['%$q%', '%$q%'],
      orderBy: 'descripcion ASC',
      limit: 100,
    );
    return rows.map(Product.fromMap).toList();
  }

  Future<int> getProductsCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as c FROM productos');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> clearProducts() async {
    final db = await database;
    await db.delete('productos');
  }

  // ---------------------------------------------------------------------
  // CONTEOS
  // ---------------------------------------------------------------------

  Future<int> insertConteo(ConteoRecord record) async {
    final db = await database;
    return db.insert('conteos', record.toMap());
  }

  Future<int> getConteosCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as c FROM conteos');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getConteosCountForClave(String clave1) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as c FROM conteos WHERE clave1 = ?',
      [clave1],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<ConteoRecord>> getConteosForClave(String clave1) async {
    final db = await database;
    final rows = await db.query(
      'conteos',
      where: 'clave1 = ?',
      whereArgs: [clave1],
      orderBy: 'fecha DESC',
    );
    return rows.map(ConteoRecord.fromMap).toList();
  }

  /// Borra todos los conteos capturados (inicia una nueva sesion de
  /// inventario) sin afectar el catalogo de productos importado.
  Future<void> resetConteos() async {
    final db = await database;
    await db.delete('conteos');
  }

  // ---------------------------------------------------------------------
  // REPORTES
  // ---------------------------------------------------------------------

  /// Devuelve, por cada producto, la existencia del sistema vs. la suma
  /// de todos los conteos fisicos capturados para esa clave.
  Future<List<ReportRow>> getReport() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT
        p.clave1 AS clave1,
        p.descripcion AS descripcion,
        p.existencia AS existencia,
        COALESCE((SELECT SUM(c.cantidad) FROM conteos c WHERE c.clave1 = p.clave1), 0) AS existenciaFisica,
        (SELECT COUNT(*) FROM conteos c WHERE c.clave1 = p.clave1) AS numConteos
      FROM productos p
      ORDER BY p.descripcion ASC
    ''');
    return result.map(ReportRow.fromMap).toList();
  }

  Future<void> resetAll() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('conteos');
      await txn.delete('productos');
    });
  }
}
