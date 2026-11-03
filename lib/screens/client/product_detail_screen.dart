import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../state/app_state.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.product});

  final Product product;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _qty = 1;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final p = widget.product;
    final category = state.categoryById(p.categoryId);
    final primary = Theme.of(context).colorScheme.primary;
    final inCart = state.qtyInCart(p.id);
    final available = p.stock - inCart;
    if (_qty > available && available > 0) _qty = available;

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: state.cartCount > 0,
              label: Text('${state.cartCount}'),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            onPressed: () => goToCart(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          SizedBox(
            height: 260,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ProductImage(
                    emoji: p.emoji,
                    color: category.color,
                    radius: 28,
                    fontSize: 120,
                  ),
                ),
                if (p.onSale)
                  Positioned(
                    top: 14,
                    left: 14,
                    child: DiscountBadge(percent: p.discountPercent),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            category.name.toUpperCase(),
            style: TextStyle(
              color: primary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            p.name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(p.unit, style: TextStyle(color: Colors.grey.shade600, fontSize: 15)),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                usd(p.price),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: primary,
                ),
              ),
              const SizedBox(width: 10),
              if (p.onSale)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    usd(p.oldPrice!),
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade500,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ),
            ],
          ),
          Text(
            '≈ ${bs(p.price * state.exchangeRate)}',
            style: TextStyle(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                p.inStock ? Icons.check_circle_rounded : Icons.cancel_rounded,
                size: 18,
                color: p.inStock ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
              ),
              const SizedBox(width: 6),
              Text(
                p.inStock
                    ? (p.stock <= 5 ? '¡Quedan solo ${p.stock}!' : 'Disponible')
                    : 'Agotado',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              if (inCart > 0) ...[
                const Spacer(),
                Text(
                  '$inCart en tu carrito',
                  style: TextStyle(color: primary, fontWeight: FontWeight.w600),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Descripción',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            p.description.isEmpty ? 'Sin descripción.' : p.description,
            style: TextStyle(color: Colors.grey.shade800, height: 1.4),
          ),
        ],
      ),
      bottomNavigationBar: BottomAction(
        child: Row(
          children: [
            QtyStepper(
              qty: _qty,
              min: 1,
              max: available < 1 ? 1 : available,
              onChanged: (v) => setState(() => _qty = v),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: available <= 0
                    ? null
                    : () {
                        final nav = Navigator.of(context);
                        state.addToCart(p, _qty);
                        showSnack(
                          context,
                          '${p.name} agregado al carrito',
                          action: SnackBarAction(
                            label: 'Ver carrito',
                            onPressed: () {
                              nav.popUntil((r) => r.isFirst);
                              state.setClientTab(2);
                            },
                          ),
                        );
                        setState(() => _qty = 1);
                      },
                child: Text(
                  available <= 0
                      ? (p.inStock ? 'Máximo en carrito' : 'Agotado')
                      : 'Agregar · ${usd(p.price * _qty)}',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
