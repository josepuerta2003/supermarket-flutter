import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../state/app_state.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../../widgets/product_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  static const _popular = ['Harina', 'Arroz', 'Pollo', 'Café', 'Leche', 'Huevos', 'Detergente'];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setQuery(String q) {
    _controller.text = q;
    _controller.selection = TextSelection.collapsed(offset: q.length);
    setState(() => _query = q);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final q = normalize(_query.trim());
    final List<Product> results = q.isEmpty
        ? <Product>[]
        : state.activeProducts.where((p) {
            final cat = state.categoryById(p.categoryId).name;
            return normalize(p.name).contains(q) || normalize(cat).contains(q);
          }).toList();

    Widget body;
    if (q.isEmpty) {
      body = ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Búsquedas populares',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _popular
                .map((w) => ActionChip(
                      label: Text(w),
                      avatar: const Icon(Icons.trending_up_rounded, size: 18),
                      onPressed: () => _setQuery(w),
                    ))
                .toList(),
          ),
        ],
      );
    } else if (results.isEmpty) {
      body = EmptyState(
        icon: Icons.search_off_rounded,
        title: 'Sin resultados',
        message: 'No encontramos productos para "$_query".',
      );
    } else {
      body = CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: Text(
                '${results.length} resultados',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          ),
          ProductSliverGrid(products: results),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: TextField(
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Buscar productos',
              prefixIcon: const Icon(Icons.search_rounded),
              isDense: true,
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => _setQuery(''),
                    ),
            ),
          ),
        ),
      ),
      body: body,
      bottomNavigationBar: const CartBar(),
    );
  }
}
