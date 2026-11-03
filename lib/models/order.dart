import 'package:flutter/material.dart';

// ---------------------------------------------------------------
// Entrega
// ---------------------------------------------------------------
enum DeliveryMethod { delivery, pickup }

extension DeliveryMethodX on DeliveryMethod {
  String get label =>
      this == DeliveryMethod.delivery ? 'Delivery' : 'Retiro en tienda';

  IconData get icon => this == DeliveryMethod.delivery
      ? Icons.delivery_dining_rounded
      : Icons.storefront_rounded;
}

// ---------------------------------------------------------------
// Pago
// ---------------------------------------------------------------
enum PaymentMethod { pagoMovil, zelle, efectivo, punto }

extension PaymentMethodX on PaymentMethod {
  String get label => switch (this) {
        PaymentMethod.pagoMovil => 'Pago Móvil',
        PaymentMethod.zelle => 'Zelle',
        PaymentMethod.efectivo => 'Efectivo',
        PaymentMethod.punto => 'Punto de venta',
      };

  String get description => switch (this) {
        PaymentMethod.pagoMovil => 'Transfiere en bolívares y envía la referencia',
        PaymentMethod.zelle => 'Paga en dólares desde tu cuenta',
        PaymentMethod.efectivo => 'Dólares o bolívares al recibir',
        PaymentMethod.punto => 'Tarjeta de débito al recibir',
      };

  IconData get icon => switch (this) {
        PaymentMethod.pagoMovil => Icons.phone_android_rounded,
        PaymentMethod.zelle => Icons.attach_money_rounded,
        PaymentMethod.efectivo => Icons.payments_rounded,
        PaymentMethod.punto => Icons.credit_card_rounded,
      };

  /// Pagos que el negocio debe verificar antes de despachar.
  bool get needsReference =>
      this == PaymentMethod.pagoMovil || this == PaymentMethod.zelle;
}

// ---------------------------------------------------------------
// Estado del pedido
// ---------------------------------------------------------------
enum OrderStatus {
  recibido,
  confirmado,
  preparando,
  enCamino,
  listoRetiro,
  entregado,
  cancelado,
}

extension OrderStatusX on OrderStatus {
  String get label => switch (this) {
        OrderStatus.recibido => 'Recibido',
        OrderStatus.confirmado => 'Confirmado',
        OrderStatus.preparando => 'En preparación',
        OrderStatus.enCamino => 'En camino',
        OrderStatus.listoRetiro => 'Listo para retirar',
        OrderStatus.entregado => 'Entregado',
        OrderStatus.cancelado => 'Cancelado',
      };

  String get clientMessage => switch (this) {
        OrderStatus.recibido =>
          'El supermercado recibió tu pedido y lo revisará en breve.',
        OrderStatus.confirmado => 'Tu pedido fue confirmado.',
        OrderStatus.preparando => 'Estamos preparando tus productos.',
        OrderStatus.enCamino => 'Tu pedido va en camino. ¡Ya casi llega!',
        OrderStatus.listoRetiro =>
          'Tu pedido está listo. Puedes pasar a retirarlo.',
        OrderStatus.entregado => 'Pedido entregado. ¡Gracias por tu compra!',
        OrderStatus.cancelado => 'Este pedido fue cancelado.',
      };

  IconData get icon => switch (this) {
        OrderStatus.recibido => Icons.inbox_rounded,
        OrderStatus.confirmado => Icons.thumb_up_alt_rounded,
        OrderStatus.preparando => Icons.shopping_basket_rounded,
        OrderStatus.enCamino => Icons.two_wheeler_rounded,
        OrderStatus.listoRetiro => Icons.store_mall_directory_rounded,
        OrderStatus.entregado => Icons.check_circle_rounded,
        OrderStatus.cancelado => Icons.cancel_rounded,
      };

  Color get color => switch (this) {
        OrderStatus.recibido => const Color(0xFF2563EB),
        OrderStatus.confirmado => const Color(0xFF7C3AED),
        OrderStatus.preparando => const Color(0xFFD97706),
        OrderStatus.enCamino => const Color(0xFF0284C7),
        OrderStatus.listoRetiro => const Color(0xFF0D9488),
        OrderStatus.entregado => const Color(0xFF16A34A),
        OrderStatus.cancelado => const Color(0xFFDC2626),
      };
}

/// Pasos que sigue un pedido según el tipo de entrega.
List<OrderStatus> flowFor(DeliveryMethod method) =>
    method == DeliveryMethod.delivery
        ? const [
            OrderStatus.recibido,
            OrderStatus.confirmado,
            OrderStatus.preparando,
            OrderStatus.enCamino,
            OrderStatus.entregado,
          ]
        : const [
            OrderStatus.recibido,
            OrderStatus.confirmado,
            OrderStatus.preparando,
            OrderStatus.listoRetiro,
            OrderStatus.entregado,
          ];

// ---------------------------------------------------------------
// Pedido
// ---------------------------------------------------------------
class OrderLine {
  const OrderLine({
    required this.productId,
    required this.name,
    required this.emoji,
    required this.unit,
    required this.price,
    required this.qty,
  });

  final String productId;
  final String name;
  final String emoji;
  final String unit;
  final double price;
  final int qty;

  double get total => price * qty;
}

class Order {
  Order({
    required this.id,
    required this.lines,
    required this.subtotal,
    required this.deliveryFee,
    required this.rate,
    required this.deliveryMethod,
    required this.address,
    required this.paymentMethod,
    this.paymentRef = '',
    this.cashAmount,
    required this.customerName,
    required this.phone,
    this.notes = '',
    required this.createdAt,
    this.isMine = false,
    required this.status,
    this.paymentVerified = false,
    required this.history,
  });

  final String id;
  final List<OrderLine> lines;
  final double subtotal;
  final double deliveryFee;

  /// Tasa Bs/USD al momento del pedido.
  final double rate;
  final DeliveryMethod deliveryMethod;
  final String address;
  final PaymentMethod paymentMethod;
  final String paymentRef;
  final double? cashAmount;
  final String customerName;
  final String phone;
  final String notes;
  final DateTime createdAt;

  /// true = pedido hecho desde este teléfono (vista cliente).
  final bool isMine;

  OrderStatus status;
  bool paymentVerified;
  final Map<OrderStatus, DateTime> history;

  double get total => subtotal + deliveryFee;
  double get totalBs => total * rate;
  int get itemCount => lines.fold(0, (s, l) => s + l.qty);

  List<OrderStatus> get flow => flowFor(deliveryMethod);

  bool get isActive =>
      status != OrderStatus.entregado && status != OrderStatus.cancelado;

  OrderStatus? get nextStatus {
    if (!isActive) return null;
    final i = flow.indexOf(status);
    if (i < 0 || i >= flow.length - 1) return null;
    return flow[i + 1];
  }
}
