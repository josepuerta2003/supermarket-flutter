import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../state/app_state.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import 'checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final items = state.cartItems;
    final subtotal = state.cartSubtotal;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi carrito'),
        actions: [
          if (items.isNotEmpty)
            TextButton(
              onPressed: () async {
                final ok = await confirmDialog(
                  context,
                  title: 'Vaciar carrito',
                  message: '¿Quieres quitar todos los productos del carrito?',
                  confirmLabel: 'Vaciar',
                  destructive: true,
                );
                if (ok) state.clearCart();
              },
              child: const Text('Vaciar'),
            ),
        ],
      ),
      body: items.isEmpty
          ? EmptyState(
              icon: Icons.shopping_cart_outlined,
              title: 'Tu carrito está vacío',
              message: 'Agrega productos para hacer tu pedido.',
              action: FilledButton(
                onPressed: () => state.setClientTab(0),
                child: const Text('Ver productos'),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              children: [
                if (state.deliveryEnabled && subtotal < state.freeDeliveryFrom)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Te faltan ${usd(state.freeDeliveryFrom - subtotal)} para el envío gratis 🚚',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: (subtotal / state.freeDeliveryFrom)
                                .clamp(0.0, 1.0)
                                .toDouble(),
                            minHeight: 8,
                            backgroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ...items.map(
                  (it) => Dismissible(
                    key: ValueKey(it.product.id),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) => state.removeFromCart(it.product.id),
                    background: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.only(right: 20),
                      alignment: Alignment.centerRight,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.delete_outline_rounded,
                          color: Colors.white),
                    ),
                    child: _CartTile(item: it),
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    'Desliza un producto a la izquierda para quitarlo',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: items.isEmpty
          ? null
          : BottomAction(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  KeyValueRow(
                    label: 'Subtotal (${state.cartCount} productos)',
                    value: usd(subtotal),
                    bold: true,
                    big: true,
                  ),
                  KeyValueRow(
                    label: 'En bolívares',
                    value: bs(subtotal * state.exchangeRate),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                      ),
                      child: const Text('Continuar con el pedido'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _CartTile extends StatelessWidget {
  const _CartTile({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final p = item.product;
    final category = state.categoryById(p.categoryId);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ProductImage(emoji: p.emoji, color: category.color, size: 64),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  p.unit,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  usd(item.total),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          QtyStepper(
            qty: item.qty,
            max: p.stock,
            compact: true,
            onChanged: (v) => state.setQty(p.id, v),
          ),
        ],
      ),
    );
  }
}
