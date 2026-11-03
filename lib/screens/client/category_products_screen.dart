import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import '../../widgets/product_card.dart';

enum _Sort { relevancia, ofertas, menorPrecio, mayorPrecio }

class CategoryProductsScreen extends StatefulWidget {
  const CategoryProductsScreen({super.key, required this.category});

  final ProductCategory category;

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  _Sort _sort = _Sort.relevancia;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final list = state.productsIn(widget.category.id);
    switch (_sort) {
      case _Sort.relevancia:
        break;
      case _Sort.ofertas:
        list.sort((a, b) => b.discountPercent.compareTo(a.discountPercent));
      case _Sort.menorPrecio:
        list.sort((a, b) => a.price.compareTo(b.price));
      case _Sort.mayorPrecio:
        list.sort((a, b) => b.price.compareTo(a.price));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.category.emoji}  ${widget.category.name}'),
        actions: [
          PopupMenuButton<_Sort>(
            icon: const Icon(Icons.sort_rounded),
            tooltip: 'Ordenar',
            initialValue: _sort,
            onSelected: (v) => setState(() => _sort = v),
            itemBuilder: (_) => const [
              PopupMenuItem(value: _Sort.relevancia, child: Text('Relevancia')),
              PopupMenuItem(value: _Sort.ofertas, child: Text('Ofertas primero')),
              PopupMenuItem(value: _Sort.menorPrecio, child: Text('Menor precio')),
              PopupMenuItem(value: _Sort.mayorPrecio, child: Text('Mayor precio')),
            ],
          ),
        ],
      ),
      body: list.isEmpty
          ? const EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'Sin productos por ahora',
              message: 'Pronto agregaremos productos a esta categoría.',
            )
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: Text(
                      '${list.length} productos',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                ),
                ProductSliverGrid(products: list),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
      bottomNavigationBar: const CartBar(),
    );
  }
}
