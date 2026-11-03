import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import 'admin_product_form.dart';

class AdminProducts extends StatefulWidget {
  const AdminProducts({super.key});

  @override
  State<AdminProducts> createState() => _AdminProductsState();
}

class _AdminProductsState extends State<AdminProducts> {
  String _query = '';
  String? _categoryId;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final q = normalize(_query.trim());
    final list = state.products.where((p) {
      if (_categoryId != null && p.categoryId != _categoryId) return false;
      if (q.isNotEmpty && !normalize(p.name).contains(q)) return false;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AdminProductForm()),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nuevo producto'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: 'Buscar producto',
                prefixIcon: Icon(Icons.search_rounded),
                isDense: true,
              ),
            ),
          ),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('Todos (${state.products.length})'),
                    selected: _categoryId == null,
                    onSelected: (_) => setState(() => _categoryId = null),
                  ),
                ),
                for (final c in state.categories)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('${c.emoji} ${c.name}'),
                      selected: _categoryId == c.id,
                      onSelected: (_) => setState(() => _categoryId = c.id),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: list.isEmpty
                ? Center(
                    child: Text('No hay productos',
                        style: TextStyle(color: Colors.grey.shade600)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                    itemCount: list.length,
                    itemBuilder: (context, i) {
                      final p = list[i];
                      final cat = state.categoryById(p.categoryId);
                      final low = p.stock <= 5;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AdminProductForm(product: p),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Row(
                                children: [
                                  Opacity(
                                    opacity: p.active ? 1 : 0.4,
                                    child: ProductImage(
                                      emoji: p.emoji,
                                      color: cat.color,
                                      size: 52,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: p.active ? null : Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Text(
                                              usd(p.price),
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w800),
                                            ),
                                            if (p.onSale) ...[
                                              const SizedBox(width: 6),
                                              DiscountBadge(percent: p.discountPercent),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          p.stock == 0
                                              ? 'Agotado'
                                              : 'Stock: ${p.stock}',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: low
                                                ? FontWeight.w700
                                                : FontWeight.w400,
                                            color: low
                                                ? const Color(0xFFDC2626)
                                                : Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    children: [
                                      Switch(
                                        value: p.active,
                                        onChanged: (_) => state.toggleActive(p),
                                      ),
                                      Text(
                                        p.active ? 'Visible' : 'Oculto',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
