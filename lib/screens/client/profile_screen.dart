import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/brand.dart';
import '../../cuentas/cuentas.dart' show PantallaPerfil, Sesion;
import '../../models/order.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';

/// Perfil del cliente: cuenta (login, datos, direcciones, seguridad,
/// notificaciones y SuperPuntos) + información de la tienda.
/// El acceso al panel aparece solo para empleados y administradores.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return PantallaPerfil(
      onMisPedidos: () => state.setClientTab(3),
      onAbrirPanel: (_) => Sesion.instancia.verPanel(),
      extras: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
          child: Text('Nuestra tienda',
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.primary)),
        ),
        _Group(children: [
          _Tile(
            icon: Icons.storefront_outlined,
            title: Brand.appName,
            subtitle: state.storeAddress,
          ),
          _Tile(
            icon: Icons.access_time_rounded,
            title: 'Horario',
            subtitle: state.storeHours,
          ),
          _Tile(
            icon: Icons.payments_outlined,
            title: 'Métodos de pago aceptados',
            subtitle: PaymentMethod.values
                .where(state.enabledPayments.contains)
                .map((m) => m.label)
                .join(' · '),
          ),
          _Tile(
            icon: Icons.chat_outlined,
            title: 'Atención al cliente',
            subtitle: 'WhatsApp ${Brand.whatsapp}',
            onTap: () => showSnack(context, 'Aquí se abriría WhatsApp del negocio'),
          ),
        ]),
      ],
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) items.add(const Divider(height: 1, indent: 56));
      items.add(children[i]);
    }
    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(18),
      child: Column(children: items),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      trailing: onTap == null ? null : const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
