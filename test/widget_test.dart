import 'package:flutter_test/flutter_test.dart';
import 'package:super_app/models/order.dart';
import 'package:super_app/state/app_state.dart';

void main() {
  test('Flujo completo: carrito → pedido → entrega', () {
    final s = AppState();
    final p = s.productById('p01')!;
    final stockBefore = p.stock;

    s.addToCart(p, 3);
    expect(s.cartCount, 3);

    final order = s.placeOrder(
      method: DeliveryMethod.delivery,
      address: 'Calle 1',
      payment: PaymentMethod.efectivo,
      customerName: 'Prueba',
      phone: '04120000000',
    );

    expect(s.cartCount, 0);
    expect(p.stock, stockBefore - 3);
    expect(order.status, OrderStatus.recibido);
    expect(s.myOrders.first.id, order.id);

    while (order.nextStatus != null) {
      s.advanceOrder(order);
    }
    expect(order.status, OrderStatus.entregado);
    expect(order.paymentVerified, isTrue);
  });

  test('Cancelar devuelve el stock', () {
    final s = AppState();
    final p = s.productById('p14')!;
    final before = p.stock;
    s.addToCart(p, 2);
    final o = s.placeOrder(
      method: DeliveryMethod.pickup,
      address: s.storeAddress,
      payment: PaymentMethod.punto,
      customerName: 'Prueba',
      phone: '04120000000',
    );
    s.cancelOrder(o);
    expect(p.stock, before);
    expect(o.status, OrderStatus.cancelado);
  });
}
