import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order.dart';
import '../../state/app_state.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import 'admin_product_form.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key, required this.onGoToOrders});

  final VoidCallback onGoToOrders;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final counts = state.statusCounts;
    final top = state.topSellers;
    final low = state.lowStock;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        const Text(
          'Hola 👋',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        Text(
          'Así va tu negocio hoy',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
        ),
        const SizedBox(height: 16),

        // KPIs
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.45,
          children: [
            _Kpi(
              label: 'Ventas de hoy',
              value: usd(state.todaySales),
              icon: Icons.attach_money_rounded,
              color: const Color(0xFF16A34A),
            ),
            _Kpi(
              label: 'Pedidos de hoy',
              value: '${state.todayOrders.length}',
              icon: Icons.receipt_long_rounded,
              color: const Color(0xFF2563EB),
            ),
            _Kpi(
              label: 'Por atender',
              value: '${state.pendingCount}',
              icon: Icons.pending_actions_rounded,
              color: const Color(0xFFD97706),
              onTap: onGoToOrders,
            ),
            _Kpi(
              label: 'Ticket promedio',
              value: usd(state.avgTicket),
              icon: Icons.shopping_basket_rounded,
              color: const Color(0xFF7C3AED),
            ),
          ],
        ),
        const SizedBox(height: 12),

        InfoCard(
          title: 'Ventas de los últimos 7 días',
          child: _BarChart(values: state.last7DaysSales),
        ),
        const SizedBox(height: 12),

        InfoCard(
          title: 'Pedidos por estado',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: OrderStatus.values
                .where((s) => (counts[s] ?? 0) > 0)
                .map((s) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: s.color.withAlpha(26),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(s.icon, size: 16, color: s.color),
                          const SizedBox(width: 6),
                          Text(
                            '${s.label}: ${counts[s]}',
                            style: TextStyle(
                              color: s.color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 12),

        InfoCard(
          title: 'Más vendidos',
          child: top.isEmpty
              ? Text('Aún no hay ventas.',
                  style: TextStyle(color: Colors.grey.shade600))
              : Column(
                  children: [
                    for (var i = 0; i < top.length; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 22,
                              child: Text(
                                '${i + 1}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ),
                            Text(top[i].key.emoji,
                                style: const TextStyle(fontSize: 22)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                top[i].key.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            Text(
                              '${top[i].value} und',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 12),

        InfoCard(
          title: 'Stock bajo',
          child: low.isEmpty
              ? Text('Todo el inventario está en orden ✓',
                  style: TextStyle(color: Colors.grey.shade600))
              : Column(
                  children: [
                    for (final p in low)
                      InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AdminProductForm(product: p),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Text(p.emoji, style: const TextStyle(fontSize: 22)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  p.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDC2626).withAlpha(24),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  p.stock == 0 ? 'Agotado' : 'Quedan ${p.stock}',
                                  style: const TextStyle(
                                    color: Color(0xFFDC2626),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withAlpha(28),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
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

class _BarChart extends StatelessWidget {
  const _BarChart({required this.values});

  final List<double> values;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final maxV = values.fold(0.0, (m, v) => v > m ? v : m);
    final now = DateTime.now();
    const barMax = 110.0;

    return SizedBox(
      height: 160,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(values.length, (i) {
          final v = values[i];
          final day = now.subtract(Duration(days: values.length - 1 - i));
          final isToday = i == values.length - 1;
          final double h =
              maxV == 0 ? 4.0 : (v / maxV * barMax).clamp(4.0, barMax).toDouble();
          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '\$${v.round()}',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Container(
                  height: h,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: isToday ? primary : primary.withAlpha(90),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(6)),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isToday ? 'Hoy' : weekdayShort[day.weekday - 1],
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
