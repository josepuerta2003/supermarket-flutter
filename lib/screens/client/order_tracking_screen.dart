import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order.dart';
import '../../state/app_state.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';

/// Seguimiento del pedido. Se actualiza en vivo cuando el
/// supermercado cambia el estado desde su panel.
class OrderTrackingScreen extends StatelessWidget {
  const OrderTrackingScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final order = state.orderById(orderId);
    if (order == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.receipt_long_outlined,
          title: 'Pedido no encontrado',
          message: 'Es posible que se haya reiniciado la demostración.',
        ),
      );
    }

    final s = order.status;
    return Scaffold(
      appBar: AppBar(title: Text('Pedido #${order.id}')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          // Estado actual
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: s.color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(s.icon, color: Colors.white, size: 40),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        s.clientMessage,
                        style: TextStyle(color: Colors.white.withAlpha(235)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Línea de tiempo
          if (s != OrderStatus.cancelado)
            InfoCard(
              title: 'Seguimiento',
              child: Column(
                children: [
                  for (var i = 0; i < order.flow.length; i++)
                    _TimelineStep(
                      status: order.flow[i],
                      time: order.history[order.flow[i]],
                      done: i <= order.flow.indexOf(s),
                      current: order.flow[i] == s,
                      isLast: i == order.flow.length - 1,
                    ),
                ],
              ),
            ),
          if (s != OrderStatus.cancelado) const SizedBox(height: 12),

          // Entrega
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

          // Pago
          InfoCard(
            title: 'Pago',
            child: Column(
              children: [
                KeyValueRow(label: 'Método', value: order.paymentMethod.label),
                if (order.paymentRef.isNotEmpty)
                  KeyValueRow(label: 'Referencia', value: order.paymentRef),
                if (order.cashAmount != null)
                  KeyValueRow(label: 'Paga con', value: usd(order.cashAmount!)),
                KeyValueRow(
                  label: 'Estado del pago',
                  value: order.paymentVerified ? 'Verificado ✓' : 'Por verificar',
                  valueColor: order.paymentVerified
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFD97706),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Productos
          InfoCard(
            title: 'Productos (${order.itemCount})',
            child: Column(
              children: [
                for (final l in order.lines)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        Text(l.emoji, style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text('${l.qty} × ${l.name}',
                              maxLines: 2, overflow: TextOverflow.ellipsis),
                        ),
                        Text(usd(l.total),
                            style: const TextStyle(fontWeight: FontWeight.w600)),
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
                KeyValueRow(label: 'En bolívares', value: bs(order.totalBs)),
              ],
            ),
          ),
          if (order.notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            InfoCard(title: 'Notas', child: Text(order.notes)),
          ],
          const SizedBox(height: 16),
          Text(
            'Este estado se actualiza automáticamente cuando el supermercado avanza tu pedido.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      ),
      bottomNavigationBar: s == OrderStatus.recibido
          ? BottomAction(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFDC2626),
                  side: const BorderSide(color: Color(0xFFDC2626)),
                ),
                onPressed: () async {
                  final ok = await confirmDialog(
                    context,
                    title: 'Cancelar pedido',
                    message: '¿Seguro que quieres cancelar el pedido #${order.id}?',
                    confirmLabel: 'Sí, cancelar',
                    destructive: true,
                  );
                  if (ok) state.cancelOrder(order);
                },
                child: const Text('Cancelar pedido'),
              ),
            )
          : null,
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.status,
    required this.time,
    required this.done,
    required this.current,
    required this.isLast,
  });

  final OrderStatus status;
  final DateTime? time;
  final bool done;
  final bool current;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final grey = Colors.grey.shade300;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? primary : Colors.white,
                border: Border.all(color: done ? primary : grey, width: 2),
                boxShadow: current
                    ? [BoxShadow(color: primary.withAlpha(80), blurRadius: 10)]
                    : null,
              ),
              child: done
                  ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                  : null,
            ),
            if (!isLast)
              Container(width: 2, height: 30, color: done ? primary : grey),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    status.label,
                    style: TextStyle(
                      fontWeight: current ? FontWeight.w800 : FontWeight.w600,
                      color: done ? null : Colors.grey.shade500,
                    ),
                  ),
                ),
                if (time != null)
                  Text(
                    formatTime(time!),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
