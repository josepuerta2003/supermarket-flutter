import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order.dart';
import '../../state/app_state.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import 'admin_order_detail.dart';

class AdminOrders extends StatelessWidget {
  const AdminOrders({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final active = state.orders.where((o) => o.isActive).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt)); // más antiguos primero
    final done = state.orders
        .where((o) => o.status == OrderStatus.entregado)
        .toList();
    final cancelled = state.orders
        .where((o) => o.status == OrderStatus.cancelado)
        .toList();

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(text: 'Activos (${active.length})'),
              const Tab(text: 'Entregados'),
              const Tab(text: 'Cancelados'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _OrderList(
                  orders: active,
                  emptyText: 'No hay pedidos por atender 🎉',
                ),
                _OrderList(orders: done, emptyText: 'Aún no hay pedidos entregados'),
                _OrderList(orders: cancelled, emptyText: 'No hay pedidos cancelados'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderList extends StatelessWidget {
  const _OrderList({required this.orders, required this.emptyText});

  final List<Order> orders;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Center(
        child: Text(emptyText, style: TextStyle(color: Colors.grey.shade600)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      separatorBuilder: (context, i) => const SizedBox(height: 10),
      itemBuilder: (context, i) => _AdminOrderCard(order: orders[i]),
    );
  }
}

class _AdminOrderCard extends StatelessWidget {
  const _AdminOrderCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final next = order.nextStatus;
    final needsCheck =
        order.paymentMethod.needsReference && !order.paymentVerified && order.isActive;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => AdminOrderDetail(orderId: order.id),
        )),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '#${order.id}',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.customerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  StatusChip(status: order.status),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${formatDateTime(order.createdAt)} · ${order.itemCount} productos',
                style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(order.deliveryMethod.icon, size: 18, color: Colors.grey.shade700),
                  const SizedBox(width: 4),
                  Text(order.deliveryMethod.label,
                      style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 12),
                  Icon(order.paymentMethod.icon, size: 18, color: Colors.grey.shade700),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(order.paymentMethod.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13)),
                  ),
                  const Spacer(),
                  Text(
                    usd(order.total),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ],
              ),
              if (needsCheck) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        size: 18, color: Color(0xFFD97706)),
                    const SizedBox(width: 6),
                    Text(
                      'Pago por verificar · Ref. ${order.paymentRef}',
                      style: const TextStyle(
                        color: Color(0xFFD97706),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
              if (next != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(minimumSize: const Size(64, 44)),
                    onPressed: () => advanceWithCheck(context, state, order),
                    icon: Icon(next.icon, size: 18),
                    label: Text('Marcar como: ${next.label}'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Avanza el pedido al siguiente estado; si el pago no está verificado
/// pide confirmación primero.
Future<void> advanceWithCheck(
    BuildContext context, AppState state, Order order) async {
  final next = order.nextStatus;
  if (next == null) return;
  if (order.paymentMethod.needsReference && !order.paymentVerified) {
    final ok = await confirmDialog(
      context,
      title: 'Pago sin verificar',
      message:
          'El pago por ${order.paymentMethod.label} (ref. ${order.paymentRef}) '
          'aún no está verificado. ¿Marcarlo como verificado y continuar?',
      confirmLabel: 'Verificar y continuar',
    );
    if (!ok) return;
    state.setPaymentVerified(order, true);
  }
  state.setStatus(order, next);
}
