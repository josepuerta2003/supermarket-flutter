import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../cuentas/cuentas.dart' show Sesion;
import '../../models/order.dart';
import '../../state/app_state.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import 'order_success_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  late DeliveryMethod _method;
  PaymentMethod? _payment;

  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  final _reference = TextEditingController();
  final _payRef = TextEditingController();
  final _cash = TextEditingController();
  final _notes = TextEditingController();

  @override
  void initState() {
    super.initState();
    final s = context.read<AppState>();
    _method = s.deliveryEnabled ? DeliveryMethod.delivery : DeliveryMethod.pickup;
    _name = TextEditingController(text: s.customerName);
    _phone = TextEditingController(text: s.customerPhone);
    _address = TextEditingController(text: s.customerAddress);
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _address, _reference, _payRef, _cash, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Este campo es obligatorio' : null;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    // Si el negocio desactiva un método mientras se está en esta pantalla.
    if (_method == DeliveryMethod.delivery && !state.deliveryEnabled) {
      _method = DeliveryMethod.pickup;
    } else if (_method == DeliveryMethod.pickup && !state.pickupEnabled) {
      _method = DeliveryMethod.delivery;
    }
    final payments =
        PaymentMethod.values.where(state.enabledPayments.contains).toList();
    if (_payment == null || !payments.contains(_payment)) {
      _payment = payments.isEmpty ? null : payments.first;
    }

    final subtotal = state.cartSubtotal;
    final fee = state.deliveryFeeFor(_method, subtotal);
    final total = subtotal + fee;
    final totalBs = total * state.exchangeRate;
    final deliveryFeeLabel =
        state.deliveryFeeFor(DeliveryMethod.delivery, subtotal) == 0
            ? 'Envío gratis'
            : usd(state.deliveryFee);

    return Scaffold(
      appBar: AppBar(title: const Text('Finalizar pedido')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            // -------- 1. Entrega --------
            const _StepTitle(number: 1, title: '¿Cómo quieres recibirlo?'),
            Row(
              children: [
                Expanded(
                  child: _ChoiceCard(
                    icon: DeliveryMethod.delivery.icon,
                    title: 'Delivery',
                    subtitle: state.deliveryEnabled ? deliveryFeeLabel : 'No disponible',
                    selected: _method == DeliveryMethod.delivery,
                    enabled: state.deliveryEnabled,
                    onTap: () => setState(() => _method = DeliveryMethod.delivery),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ChoiceCard(
                    icon: DeliveryMethod.pickup.icon,
                    title: 'Retiro en tienda',
                    subtitle: state.pickupEnabled ? 'Sin costo' : 'No disponible',
                    selected: _method == DeliveryMethod.pickup,
                    enabled: state.pickupEnabled,
                    onTap: () => setState(() => _method = DeliveryMethod.pickup),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_method == DeliveryMethod.delivery) ...[
              TextFormField(
                controller: _address,
                minLines: 1,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Dirección de entrega',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                validator: _required,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _reference,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Punto de referencia (opcional)',
                  prefixIcon: Icon(Icons.flag_outlined),
                ),
              ),
            ] else
              _InfoBox(
                icon: Icons.storefront_rounded,
                lines: [state.storeAddress, state.storeHours],
              ),

            // -------- 2. Datos --------
            const _StepTitle(number: 2, title: 'Tus datos'),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nombre y apellido',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: _required,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Teléfono',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              validator: (v) =>
                  (v == null || v.replaceAll(RegExp(r'\D'), '').length < 10)
                      ? 'Ingresa un teléfono válido'
                      : null,
            ),

            // -------- 3. Pago --------
            const _StepTitle(number: 3, title: 'Método de pago'),
            ...payments.map(
              (m) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _PaymentTile(
                  method: m,
                  selected: _payment == m,
                  onTap: () => setState(() => _payment = m),
                ),
              ),
            ),
            if (_payment != null) ...[
              const SizedBox(height: 4),
              _paymentDetails(_payment!, total, totalBs, state),
            ],

            // -------- 4. Resumen --------
            const _StepTitle(number: 4, title: 'Resumen'),
            InfoCard(
              child: Column(
                children: [
                  KeyValueRow(
                    label: 'Productos (${state.cartCount})',
                    value: usd(subtotal),
                  ),
                  KeyValueRow(
                    label: 'Envío',
                    value: _method == DeliveryMethod.pickup
                        ? 'Retiro en tienda'
                        : (fee == 0 ? 'Gratis' : usd(fee)),
                  ),
                  const Divider(height: 20),
                  KeyValueRow(label: 'Total', value: usd(total), bold: true, big: true),
                  KeyValueRow(label: 'Total en bolívares', value: bs(totalBs)),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Tasa: 1 USD = ${formatNumber(state.exchangeRate)} Bs',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notes,
              minLines: 1,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Notas para el pedido (opcional)',
                hintText: 'Ej: llamar al llegar, sin bolsas plásticas',
                prefixIcon: Icon(Icons.edit_note_rounded),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAction(
        child: FilledButton(
          onPressed: state.cartItems.isEmpty || _payment == null
              ? null
              : () => _submit(state),
          child: Text('Confirmar pedido · ${usd(total)}'),
        ),
      ),
    );
  }

  Widget _paymentDetails(
      PaymentMethod m, double total, double totalBs, AppState s) {
    return switch (m) {
      PaymentMethod.pagoMovil => Column(
          children: [
            _CopyBox(
              title: 'Datos para Pago Móvil',
              rows: [
                ('Banco', s.pmBank),
                ('Teléfono', s.pmPhone),
                ('RIF / C.I.', s.pmId),
                ('Monto', bs(totalBs)),
              ],
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _payRef,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Número de referencia',
                helperText: 'Últimos dígitos de la operación',
                prefixIcon: Icon(Icons.confirmation_number_outlined),
              ),
              validator: (v) => (v == null || v.trim().length < 4)
                  ? 'Ingresa al menos 4 dígitos'
                  : null,
            ),
          ],
        ),
      PaymentMethod.zelle => Column(
          children: [
            _CopyBox(
              title: 'Datos para Zelle',
              rows: [
                ('Correo', s.zelleEmail),
                ('Titular', s.zelleHolder),
                ('Monto', usd(total)),
              ],
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _payRef,
              decoration: const InputDecoration(
                labelText: 'Número de confirmación',
                prefixIcon: Icon(Icons.confirmation_number_outlined),
              ),
              validator: (v) => (v == null || v.trim().length < 4)
                  ? 'Ingresa el número de confirmación'
                  : null,
            ),
          ],
        ),
      PaymentMethod.efectivo => _cashDetails(total),
      PaymentMethod.punto => _InfoBox(
          icon: Icons.credit_card_rounded,
          lines: [
            'Llevaremos el punto de venta al momento de la entrega o retiro.',
            'Monto a pagar: ${bs(totalBs)}',
          ],
        ),
    };
  }

  Widget _cashDetails(double total) {
    final cash = parseNumber(_cash.text);
    final change = cash == null ? 0.0 : cash - total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _cash,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: '¿Con cuánto vas a pagar? (USD, opcional)',
            prefixIcon: Icon(Icons.payments_outlined),
          ),
        ),
        if (change > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Text(
              'Tu vuelto: ${usd(change)}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
      ],
    );
  }

  void _submit(AppState state) {
    if (!(_formKey.currentState?.validate() ?? false)) {
      showSnack(context, 'Revisa los datos marcados en rojo');
      return;
    }
    final isDelivery = _method == DeliveryMethod.delivery;
    final address = isDelivery
        ? [
            _address.text.trim(),
            if (_reference.text.trim().isNotEmpty) 'Ref: ${_reference.text.trim()}',
          ].join(' · ')
        : state.storeAddress;

    state.updateCustomer(
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      address: isDelivery ? _address.text.trim() : null,
    );

    final order = state.placeOrder(
      method: _method,
      address: address,
      payment: _payment!,
      paymentRef: _payment!.needsReference ? _payRef.text.trim() : '',
      cashAmount:
          _payment == PaymentMethod.efectivo ? parseNumber(_cash.text) : null,
      customerName: _name.text.trim(),
      phone: _phone.text.trim(),
      notes: _notes.text.trim(),
    );
    Sesion.instancia.registrarCompra(order.total);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => OrderSuccessScreen(order: order)),
    );
  }
}

// ---------------------------------------------------------------
// Componentes de la pantalla
// ---------------------------------------------------------------

class _StepTitle extends StatelessWidget {
  const _StepTitle({required this.number, required this.title});

  final int number;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Text(
              '$number',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: enabled ? onTap : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? primary : Colors.grey.shade200,
                width: selected ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon,
                        size: 28,
                        color: selected ? primary : Colors.grey.shade700),
                    const Spacer(),
                    Icon(
                      selected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      size: 20,
                      color: selected ? primary : Colors.grey.shade400,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({
    required this.method,
    required this.selected,
    required this.onTap,
  });

  final PaymentMethod method;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? primary : Colors.grey.shade200,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: primary.withAlpha(selected ? 40 : 18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(method.icon, color: primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(method.label,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    Text(
                      method.description,
                      style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selected ? primary : Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.icon, required this.lines});

  final IconData icon;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: primary.withAlpha(18),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < lines.length; i++)
                  Padding(
                    padding: EdgeInsets.only(top: i == 0 ? 0 : 4),
                    child: Text(
                      lines[i],
                      style: TextStyle(
                        fontWeight: i == 0 ? FontWeight.w700 : FontWeight.w400,
                        color: i == 0 ? null : Colors.grey.shade700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CopyBox extends StatelessWidget {
  const _CopyBox({required this.title, required this.rows});

  final String title;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 6, 10),
      decoration: BoxDecoration(
        color: primary.withAlpha(18),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          for (final r in rows)
            Row(
              children: [
                SizedBox(
                  width: 92,
                  child: Text(r.$1, style: TextStyle(color: Colors.grey.shade700)),
                ),
                Expanded(
                  child: Text(r.$2,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
                IconButton(
                  tooltip: 'Copiar',
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.content_copy_rounded, size: 18, color: primary),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: r.$2));
                    showSnack(context, '${r.$1} copiado');
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }
}
