import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/brand.dart';
import '../../cuentas/cuentas.dart' show PantallaUsuarios, Sesion;
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import 'admin_dashboard.dart';
import 'admin_orders.dart';
import 'admin_products.dart';
import 'admin_settings.dart';

/// Panel del supermercado: resumen, pedidos, productos y ajustes.
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pending = context.watch<AppState>().pendingCount;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            const BrandLogo(size: 36),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Panel del negocio',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    Brand.appName,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Ver tienda',
            onPressed: () {
              final nav = Navigator.of(context);
              if (nav.canPop()) {
                nav.pop();
              } else {
                Sesion.instancia.verTienda();
              }
            },
            icon: const Icon(Icons.storefront_outlined),
          ),
          PopupMenuButton<String>(
            tooltip: 'Más opciones',
            onSelected: (op) {
              if (op == 'usuarios') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PantallaUsuarios()),
                );
              } else if (op == 'salir') {
                Sesion.salir(context);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'usuarios',
                child: ListTile(
                  leading: Icon(Icons.group_outlined),
                  title: Text('Usuarios y clientes'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'salir',
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Cerrar sesión'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: [
          AdminDashboard(onGoToOrders: () => setState(() => _index = 1)),
          const AdminOrders(),
          const AdminProducts(),
          const AdminSettings(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Resumen',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: pending > 0,
              label: Text('$pending'),
              child: const Icon(Icons.receipt_long_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: pending > 0,
              label: Text('$pending'),
              child: const Icon(Icons.receipt_long_rounded),
            ),
            label: 'Pedidos',
          ),
          const NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2_rounded),
            label: 'Productos',
          ),
          const NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}
