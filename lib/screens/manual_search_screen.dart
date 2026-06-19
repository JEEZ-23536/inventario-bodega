import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';
import 'count_capture_screen.dart';

/// Permite buscar productos por nombre o clave y registrar un conteo
/// manual sin necesidad de usar la camara.
class ManualSearchScreen extends StatefulWidget {
  const ManualSearchScreen({super.key});

  @override
  State<ManualSearchScreen> createState() => _ManualSearchScreenState();
}

class _ManualSearchScreenState extends State<ManualSearchScreen> {
  final _db = DatabaseHelper.instance;
  final _searchCtrl = TextEditingController();
  List<Product> _results = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _search('');
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    setState(() => _loading = true);
    final results = await _db.searchProductsByName(query);
    if (!mounted) return;
    setState(() {
      _results = results;
      _loading = false;
    });
  }

  Future<void> _openCapture(Product product) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CountCaptureScreen(product: product)),
    );
    if (!mounted) return;
    _search(_searchCtrl.text);
  }

  String _formatNum(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('BUSCAR PRODUCTO')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre o clave...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchCtrl.clear();
                            _search('');
                          },
                        )
                      : null,
                ),
                onChanged: _search,
              ),
            ),
            if (_loading) const LinearProgressIndicator(color: AppTheme.accent, minHeight: 2),
            Expanded(
              child: _results.isEmpty && !_loading
                  ? const Center(
                      child: Text('Sin resultados', style: TextStyle(color: Colors.white54)),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        final p = _results[index];
                        return Card(
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            title: Text(
                              p.descripcion,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '${p.clave1} · Existencia: ${_formatNum(p.existencia)}',
                                style: const TextStyle(color: Colors.white60, fontSize: 13),
                              ),
                            ),
                            trailing: const Icon(Icons.chevron_right, color: AppTheme.accent),
                            onTap: () => _openCapture(p),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
