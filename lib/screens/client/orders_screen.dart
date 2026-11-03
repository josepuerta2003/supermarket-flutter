import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order.dart';
import '../../state/app_state.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import 'order_tracking_screen.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final mine = state.myOrders;
    final active = mine.where((o) => o.isActive).toList();
    final past = mine.where((o) => !o.isActive).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Mis pedidos')),
      body: mine.isEmpty
          ? EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Aún no tienes pedidos',
              message: 'Cuando hagas un pedido podrás seguirlo desde aquí.',
              action: FilledButton(
                onPressed: () => state.setClientTab(0),
                child: const Text('Empezar a comprar'),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                if (active.isNotEmpty) ...[
                  const _Header('En curso'),
                  ...active.map((o) => OrderCard(order: o)),
                ],
                if (past.isNotEmpty) ...[
                  const _Header('Anteriores'),
                  ...past.map((o) => OrderCard(order: o)),
                ],
              ],
            ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 10),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }
}

class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => OrderTrackingScreen(orderId: order.id),
          )),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: order.status.color.withAlpha(30),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(order.status.icon, color: order.status.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pedido #${order.id}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${order.itemCount} productos · ${formatDateTime(order.createdAt)}',
                        style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 6),
                      StatusChip(status: order.status),
                    ],
                  ),
                ),
                Text(
                  usd(order.total),
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
