import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order.dart';
import '../../state/app_state.dart';
import '../../utils/format.dart';
import 'order_tracking_screen.dart';

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key, required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (context, v, child) =>
                    Transform.scale(scale: v, child: child),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: primary.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check_circle_rounded, size: 84, color: primary),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '¡Pedido enviado!',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'Pedido #${order.id}',
                style: TextStyle(
                  fontSize: 16,
                  color: primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'El supermercado recibió tu pedido por ${usd(order.total)}. '
                'Te avisaremos cuando sea confirmado.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 15, height: 1.4),
              ),
              if (order.paymentMethod.needsReference) ...[
                const SizedBox(height: 10),
                Text(
                  'Verificaremos tu pago por ${order.paymentMethod.label} '
                  '(ref. ${order.paymentRef}).',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                ),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => OrderTrackingScreen(orderId: order.id),
                    ),
                  ),
                  child: const Text('Ver estado del pedido'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    final state = context.read<AppState>();
                    Navigator.of(context).popUntil((r) => r.isFirst);
                    state.setClientTab(0);
                  },
                  child: const Text('Seguir comprando'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
