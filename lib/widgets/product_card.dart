import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../screens/client/product_detail_screen.dart';
import '../state/app_state.dart';
import '../utils/format.dart';
import 'common.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final qty = state.qtyInCart(product.id);
    final category = state.categoryById(product.categoryId);
    final primary = Theme.of(context).colorScheme.primary;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ProductDetailScreen(product: product),
        )),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ProductImage(
                        emoji: product.emoji,
                        color: category.color,
                        fontSize: 54,
                      ),
                    ),
                    if (product.onSale)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: DiscountBadge(percent: product.discountPercent),
                      ),
                    if (!product.inStock)
                      Positioned.fill(
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(170),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Text(
                            'Agotado',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                product.unit,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          usd(product.price),
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: primary,
                          ),
                        ),
                        if (product.onSale)
                          Text(
                            usd(product.oldPrice!),
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.grey.shade500,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (qty == 0)
                    Material(
                      color: product.inStock ? primary : Colors.grey.shade300,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: product.inStock
                            ? () => state.addToCart(product)
                            : null,
                        child: const SizedBox(
                          width: 34,
                          height: 34,
                          child: Icon(Icons.add_rounded,
                              color: Colors.white, size: 22),
                        ),
                      ),
                    )
                  else
                    QtyStepper(
                      qty: qty,
                      max: product.stock,
                      compact: true,
                      onChanged: (v) => state.setQty(product.id, v),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Grilla de productos para usar dentro de un CustomScrollView.
class ProductSliverGrid extends StatelessWidget {
  const ProductSliverGrid({super.key, required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 220,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.62,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, i) => ProductCard(product: products[i]),
          childCount: products.length,
        ),
      ),
    );
  }
}
