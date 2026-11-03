import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/order.dart';
import '../../state/app_state.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import 'admin_orders.dart';

class AdminOrderDetail extends StatelessWidget {
  const AdminOrderDetail({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final order = state.orderById(orderId);
    if (order == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Pedido no encontrado')),
      );
    }
    final next = order.nextStatus;

    return Scaffold(
      appBar: AppBar(
        title: Text('Pedido #${order.id}'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: StatusChip(status: order.status)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          InfoCard(
            title: 'Cliente',
            child: Column(
              children: [
                KeyValueRow(label: 'Nombre', value: order.customerName),
                Row(
                  children: [
                    Expanded(
                      child: KeyValueRow(label: 'Teléfono', value: order.phone),
                    ),
                    IconButton(
                      tooltip: 'Copiar',
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.content_copy_rounded, size: 18),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: order.phone));
                        showSnack(context, 'Teléfono copiado');
                      },
                    ),
                  ],
                ),
                KeyValueRow(label: 'Fecha', value: formatDateTime(order.createdAt)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          InfoCard(
            title: order.deliveryMethod.label,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(order.deliveryMethod.icon, color: Colors.grey.shade700),
                const SizedBox(width: 10),
                Expanded(child: Text(order.address)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          InfoCard(
            title: 'Pago',
            child: Column(
              children: [
                KeyValueRow(label: 'Método', value: order.paymentMethod.label),
                if (order.paymentRef.isNotEmpty)
                  KeyValueRow(label: 'Referencia', value: order.paymentRef),
                if (order.cashAmount != null) ...[
                  KeyValueRow(label: 'Paga con', value: usd(order.cashAmount!)),
                  if (order.cashAmount! > order.total)
                    KeyValueRow(
                      label: 'Llevar vuelto',
                      value: usd(order.cashAmount! - order.total),
                      bold: true,
                    ),
                ],
                KeyValueRow(label: 'Monto USD', value: usd(order.total)),
                KeyValueRow(label: 'Monto Bs', value: bs(order.totalBs)),
                const SizedBox(height: 4),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Pago verificado',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(
                    order.paymentMethod.needsReference
                        ? 'Confirma que el dinero llegó a la cuenta'
                        : 'Se marca al cobrar en la entrega',
                  ),
                  value: order.paymentVerified,
                  onChanged: order.status == OrderStatus.cancelado
                      ? null
                      : (v) => state.setPaymentVerified(order, v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          InfoCard(
            title: 'Productos (${order.itemCount})',
            child: Column(
              children: [
                for (final l in order.lines)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        Container(
                          width: 30,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('${l.qty}',
                              style: const TextStyle(fontWeight: FontWeight.w800)),
                        ),
                        const SizedBox(width: 10),
                        Text(l.emoji, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l.name,
                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                              Text(l.unit,
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey.shade600)),
                            ],
                          ),
                        ),
                        Text(usd(l.total)),
                      ],
                    ),
                  ),
                const Divider(height: 20),
                KeyValueRow(label: 'Subtotal', value: usd(order.subtotal)),
                KeyValueRow(
                  label: 'Envío',
                  value: order.deliveryFee == 0 ? 'Gratis' : usd(order.deliveryFee),
                ),
                KeyValueRow(label: 'Total', value: usd(order.total), bold: true, big: true),
              ],
            ),
          ),
          if (order.notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            InfoCard(title: 'Notas del cliente', child: Text(order.notes)),
          ],
          const SizedBox(height: 12),
          InfoCard(
            title: 'Historial',
            child: Column(
              children: [
                for (final e in order.history.entries)
                  KeyValueRow(label: e.key.label, value: formatTime(e.value)),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: order.isActive
          ? BottomAction(
              child: Row(
                children: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(color: Color(0xFFDC2626)),
                    ),
                    onPressed: () async {
                      final ok = await confirmDialog(
                        context,
                        title: 'Cancelar pedido',
                        message:
                            'El cliente verá el pedido como cancelado y el stock se devolverá al inventario.',
                        confirmLabel: 'Cancelar pedido',
                        destructive: true,
                      );
                      if (ok) state.cancelOrder(order);
                    },
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  if (next != null)
                    Expanded(
                      child: FilledButton(
                        onPressed: () => advanceWithCheck(context, state, order),
                        child: Text(
                          'Pasar a: ${next.label}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                ],
              ),
            )
          : null,
    );
  }
}
