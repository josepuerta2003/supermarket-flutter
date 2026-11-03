import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/brand.dart';
import '../../models/order.dart';
import '../../state/app_state.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';

class AdminSettings extends StatelessWidget {
  const AdminSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final primary = Theme.of(context).colorScheme.primary;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        // Tasa de cambio
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primary, Color.lerp(primary, Colors.black, 0.3)!],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              const Icon(Icons.currency_exchange_rounded,
                  color: Colors.white, size: 34),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tasa de cambio',
                      style: TextStyle(color: Colors.white.withAlpha(210)),
                    ),
                    Text(
                      '1 USD = ${formatNumber(state.exchangeRate)} Bs',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Los precios en Bs se recalculan solos',
                      style: TextStyle(
                          color: Colors.white.withAlpha(200), fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                icon: const Icon(Icons.edit_rounded),
                onPressed: () async {
                  final v = await promptNumber(
                    context,
                    title: 'Tasa (Bs por 1 USD)',
                    initial: state.exchangeRate,
                  );
                  if (v != null && v > 0) state.setExchangeRate(v);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        _Section(
          title: 'Entregas',
          children: [
            SwitchListTile(
              secondary: const Icon(Icons.delivery_dining_rounded),
              title: const Text('Delivery a domicilio'),
              value: state.deliveryEnabled,
              onChanged: (v) {
                if (!state.setDeliveryEnabled(v)) {
                  showSnack(context, 'Debe quedar al menos una forma de entrega');
                }
              },
            ),
            SwitchListTile(
              secondary: const Icon(Icons.storefront_rounded),
              title: const Text('Retiro en tienda'),
              value: state.pickupEnabled,
              onChanged: (v) {
                if (!state.setPickupEnabled(v)) {
                  showSnack(context, 'Debe quedar al menos una forma de entrega');
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.local_shipping_outlined),
              title: const Text('Costo del delivery'),
              trailing: _Value(usd(state.deliveryFee)),
              onTap: () async {
                final v = await promptNumber(
                  context,
                  title: 'Costo del delivery (USD)',
                  initial: state.deliveryFee,
                );
                if (v != null) state.setDeliveryFee(v);
              },
            ),
            ListTile(
              leading: const Icon(Icons.card_giftcard_rounded),
              title: const Text('Envío gratis desde'),
              trailing: _Value(usd(state.freeDeliveryFrom)),
              onTap: () async {
                final v = await promptNumber(
                  context,
                  title: 'Envío gratis desde (USD)',
                  initial: state.freeDeliveryFrom,
                );
                if (v != null) state.setFreeDeliveryFrom(v);
              },
            ),
          ],
        ),
        const SizedBox(height: 16),

        _Section(
          title: 'Métodos de pago',
          children: [
            for (final m in PaymentMethod.values)
              SwitchListTile(
                secondary: Icon(m.icon),
                title: Text(m.label),
                subtitle: Text(m.description),
                value: state.enabledPayments.contains(m),
                onChanged: (_) {
                  if (!state.togglePayment(m)) {
                    showSnack(context, 'Debe quedar al menos un método de pago');
                  }
                },
              ),
          ],
        ),
        const SizedBox(height: 16),

        _Section(
          title: 'Datos de cobro',
          children: [
            _EditTile(
              icon: Icons.account_balance_outlined,
              label: 'Banco (Pago Móvil)',
              value: state.pmBank,
              onSaved: (v) => state.updateBusiness(bank: v),
            ),
            _EditTile(
              icon: Icons.phone_android_rounded,
              label: 'Teléfono (Pago Móvil)',
              value: state.pmPhone,
              keyboardType: TextInputType.phone,
              onSaved: (v) => state.updateBusiness(phone: v),
            ),
            _EditTile(
              icon: Icons.badge_outlined,
              label: 'RIF / C.I.',
              value: state.pmId,
              onSaved: (v) => state.updateBusiness(id: v),
            ),
            _EditTile(
              icon: Icons.alternate_email_rounded,
              label: 'Correo Zelle',
              value: state.zelleEmail,
              keyboardType: TextInputType.emailAddress,
              onSaved: (v) => state.updateBusiness(zelle: v),
            ),
            _EditTile(
              icon: Icons.person_outline_rounded,
              label: 'Titular Zelle',
              value: state.zelleHolder,
              onSaved: (v) => state.updateBusiness(holder: v),
            ),
          ],
        ),
        const SizedBox(height: 16),

        _Section(
          title: 'Datos del negocio',
          children: [
            ListTile(
              leading: const Icon(Icons.storefront_outlined),
              title: const Text('Nombre de la tienda'),
              subtitle: const Text(
                '${Brand.appName}  ·  Se configura en lib/config/brand.dart',
              ),
            ),
            _EditTile(
              icon: Icons.location_on_outlined,
              label: 'Dirección',
              value: state.storeAddress,
              maxLines: 2,
              onSaved: (v) => state.updateBusiness(address: v),
            ),
            _EditTile(
              icon: Icons.access_time_rounded,
              label: 'Horario',
              value: state.storeHours,
              maxLines: 2,
              onSaved: (v) => state.updateBusiness(hours: v),
            ),
          ],
        ),
        const SizedBox(height: 16),

        _Section(
          title: 'Demostración',
          children: [
            ListTile(
              leading: const Icon(Icons.restart_alt_rounded),
              title: const Text('Reiniciar datos de demostración'),
              subtitle: const Text('Restaura productos, pedidos y ajustes'),
              onTap: () async {
                final ok = await confirmDialog(
                  context,
                  title: 'Reiniciar demo',
                  message: 'Se perderán los cambios hechos durante la demostración.',
                  confirmLabel: 'Reiniciar',
                  destructive: true,
                );
                if (ok) state.resetDemo();
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Material(
          color: Colors.white,
          clipBehavior: Clip.antiAlias,
          borderRadius: BorderRadius.circular(18),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _Value extends StatelessWidget {
  const _Value(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(text, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(width: 4),
        Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
      ],
    );
  }
}

class _EditTile extends StatelessWidget {
  const _EditTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onSaved,
    this.keyboardType,
    this.maxLines = 1,
  });

  final IconData icon;
  final String label;
  final String value;
  final ValueChanged<String> onSaved;
  final TextInputType? keyboardType;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: Icon(Icons.edit_outlined, size: 20, color: Colors.grey.shade500),
      onTap: () async {
        final v = await promptText(
          context,
          title: label,
          initial: value,
          keyboardType: keyboardType,
          maxLines: maxLines,
        );
        if (v != null && v.isNotEmpty) onSaved(v);
      },
    );
  }
}
