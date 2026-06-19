/// Representa un producto importado desde el catalogo de SICAR.
class Product {
  final String clave1; // codigo / clave del producto (clave1 *)
  final String descripcion; // descripcion *
  final double costo;
  final double precio1;
  final double existencia; // existencia segun el sistema (SICAR)

  const Product({
    required this.clave1,
    required this.descripcion,
    this.costo = 0,
    this.precio1 = 0,
    this.existencia = 0,
  });

  Map<String, Object?> toMap() => {
        'clave1': clave1,
        'descripcion': descripcion,
        'costo': costo,
        'precio1': precio1,
        'existencia': existencia,
      };

  factory Product.fromMap(Map<String, Object?> map) => Product(
        clave1: map['clave1'] as String,
        descripcion: (map['descripcion'] as String?) ?? '',
        costo: (map['costo'] as num?)?.toDouble() ?? 0,
        precio1: (map['precio1'] as num?)?.toDouble() ?? 0,
        existencia: (map['existencia'] as num?)?.toDouble() ?? 0,
      );
}
