import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../config/brand.dart';
import '../data/sample_data.dart';
import '../models/order.dart';
import '../models/product.dart';

/// Estado global de la app (catálogo, carrito, pedidos y ajustes).
///
/// En esta versión de demostración todo vive en memoria. Para producción
/// se reemplazan estos métodos por llamadas a Firebase o a una API,
/// sin tocar las pantallas.
class AppState extends ChangeNotifier {
  AppState() {
    _seed();
  }

  // ---------------- Catálogo ----------------
  late List<ProductCategory> categories;
  late List<Product> products;

  // ---------------- Carrito -----------------
  final Map<String, int> _cart = {};

  // ---------------- Pedidos -----------------
  late List<Order> orders;
  int _nextOrder = 1050;

  // ---------------- Navegación cliente -------
  int clientTab = 0;

  // ---------------- Cliente -----------------
  late String customerName;
  late String customerPhone;
  late String customerAddress;

  // ---------------- Ajustes del negocio -----
  late double exchangeRate;
  late double deliveryFee;
  late double freeDeliveryFrom;
  late bool deliveryEnabled;
  late bool pickupEnabled;
  late Set<PaymentMethod> enabledPayments;
  late String storeAddress;
  late String storeHours;
  late String pmBank;
  late String pmPhone;
  late String pmId;
  late String zelleEmail;
  late String zelleHolder;

  /// Ventas de los 6 días anteriores (demo).
  late List<double> previousDaysSales;

  // =========================================================
  // Datos de demostración
  // =========================================================
  void _seed() {
    categories = List.of(sampleCategories);
    products = sampleProducts();
    _nextOrder = 1050;
    clientTab = 0;

    customerName = 'Cliente Demo';
    customerPhone = '0412-000-0000';
    customerAddress = 'Calle 1, casa 2, urb. Centro';

    exchangeRate = BusinessDefaults.exchangeRate;
    deliveryFee = BusinessDefaults.deliveryFee;
    freeDeliveryFrom = BusinessDefaults.freeDeliveryFrom;
    deliveryEnabled = true;
    pickupEnabled = true;
    enabledPayments = PaymentMethod.values.toSet();
    storeAddress = BusinessDefaults.storeAddress;
    storeHours = BusinessDefaults.storeHours;
    pmBank = BusinessDefaults.pmBank;
    pmPhone = BusinessDefaults.pmPhone;
    pmId = BusinessDefaults.pmId;
    zelleEmail = BusinessDefaults.zelleEmail;
    zelleHolder = BusinessDefaults.zelleHolder;

    previousDaysSales = [182.40, 240.10, 205.75, 310.20, 276.90, 352.30];

    orders = [
      _demoOrder(1049, [('p01', 2), ('p14', 1), ('p17', 2), ('p19', 1)],
          DeliveryMethod.delivery, PaymentMethod.pagoMovil, OrderStatus.recibido, 6,
          'María González', 'Urb. Los Pinos, calle 3, casa 12', ref: '004518'),
      _demoOrder(1048, [('p06', 1), ('p24', 2), ('p18', 1)],
          DeliveryMethod.pickup, PaymentMethod.zelle, OrderStatus.confirmado, 25,
          'Carlos Rodríguez', '', ref: '88213', verified: true),
      _demoOrder(1047, [('p02', 2), ('p03', 2), ('p04', 1), ('p09', 2), ('p10', 1)],
          DeliveryMethod.delivery, PaymentMethod.efectivo, OrderStatus.preparando, 48,
          'Ana Pérez', 'Av. Bolívar, edif. Sol, apto 4B'),
      _demoOrder(1046, [('p26', 1), ('p29', 2), ('p30', 1), ('p21', 6)],
          DeliveryMethod.delivery, PaymentMethod.punto, OrderStatus.enCamino, 75,
          'Luis Martínez', 'Sector El Carmen, calle 8'),
      _demoOrder(1045, [('p15', 1), ('p13', 3), ('p22', 2)],
          DeliveryMethod.pickup, PaymentMethod.pagoMovil, OrderStatus.listoRetiro, 110,
          'Daniela Suárez', '', ref: '771204', verified: true),
      _demoOrder(1044, [('p19', 2), ('p17', 4), ('p25', 1), ('p20', 1)],
          DeliveryMethod.delivery, PaymentMethod.zelle, OrderStatus.entregado, 200,
          'José Ramírez', 'Urb. La Floresta, casa 21', ref: '55092', verified: true),
      _demoOrder(1043, [('p01', 3), ('p02', 2), ('p06', 1), ('p14', 2)],
          DeliveryMethod.delivery, PaymentMethod.pagoMovil, OrderStatus.entregado, 2880,
          customerName, customerAddress, ref: '239981', verified: true, mine: true),
      _demoOrder(1042, [('p16', 1)],
          DeliveryMethod.delivery, PaymentMethod.efectivo, OrderStatus.cancelado, 1500,
          'Pedro Gómez', 'Calle Comercio, local 5'),
    ];
  }

  Order _demoOrder(
    int number,
    List<(String, int)> items,
    DeliveryMethod method,
    PaymentMethod payment,
    OrderStatus status,
    int minutesAgo,
    String customer,
    String address, {
    String ref = '',
    bool verified = false,
    bool mine = false,
  }) {
    final created = DateTime.now().subtract(Duration(minutes: minutesAgo));
    final lines = <OrderLine>[];
    for (final it in items) {
      final p = productById(it.$1);
      if (p == null) continue;
      lines.add(OrderLine(
        productId: p.id,
        name: p.name,
        emoji: p.emoji,
        unit: p.unit,
        price: p.price,
        qty: it.$2,
      ));
    }
    final subtotal = lines.fold(0.0, (s, l) => s + l.total);

    final history = <OrderStatus, DateTime>{};
    final flow = flowFor(method);
    if (status == OrderStatus.cancelado) {
      history[OrderStatus.recibido] = created;
      history[OrderStatus.cancelado] = created.add(const Duration(minutes: 8));
    } else {
      final idx = flow.indexOf(status);
      final step = idx <= 0 ? 0 : math.max(1, math.min(15, minutesAgo ~/ (idx + 1)));
      for (var i = 0; i <= idx; i++) {
        history[flow[i]] = created.add(Duration(minutes: i * step));
      }
    }

    return Order(
      id: '$number',
      lines: lines,
      subtotal: subtotal,
      deliveryFee: deliveryFeeFor(method, subtotal),
      rate: exchangeRate,
      deliveryMethod: method,
      address: method == DeliveryMethod.pickup ? storeAddress : address,
      paymentMethod: payment,
      paymentRef: ref,
      customerName: customer,
      phone: '0414-555-${number.toString().padLeft(4, '0')}',
      createdAt: created,
      isMine: mine,
      status: status,
      paymentVerified: verified || status == OrderStatus.entregado,
      history: history,
    );
  }

  void resetDemo() {
    _cart.clear();
    _seed();
    notifyListeners();
  }

  // =========================================================
  // Navegación
  // =========================================================
  void setClientTab(int i) {
    clientTab = i;
    notifyListeners();
  }

  // =========================================================
  // Catálogo
  // =========================================================
  List<Product> get activeProducts => products.where((p) => p.active).toList();

  ProductCategory categoryById(String id) =>
      categories.firstWhere((c) => c.id == id, orElse: () => categories.first);

  Product? productById(String id) {
    for (final p in products) {
      if (p.id == id) return p;
    }
    return null;
  }

  List<Product> productsIn(String categoryId) =>
      activeProducts.where((p) => p.categoryId == categoryId).toList();

  String newProductId() => 'p${DateTime.now().millisecondsSinceEpoch}';

  void addProduct(Product p) {
    products.add(p);
    notifyListeners();
  }

  /// Llamar después de modificar un producto existente.
  void productUpdated(Product p) {
    if (!p.active || p.stock <= 0) _cart.remove(p.id);
    final q = _cart[p.id];
    if (q != null && q > p.stock) _cart[p.id] = p.stock;
    notifyListeners();
  }

  void toggleActive(Product p) {
    p.active = !p.active;
    if (!p.active) _cart.remove(p.id);
    notifyListeners();
  }

  void deleteProduct(Product p) {
    products.removeWhere((x) => x.id == p.id);
    _cart.remove(p.id);
    notifyListeners();
  }

  // =========================================================
  // Carrito
  // =========================================================
  int qtyInCart(String id) => _cart[id] ?? 0;

  List<CartItem> get cartItems {
    final list = <CartItem>[];
    _cart.forEach((id, q) {
      final p = productById(id);
      if (p != null) list.add(CartItem(p, q));
    });
    return list;
  }

  int get cartCount => _cart.values.fold(0, (a, b) => a + b);

  double get cartSubtotal => cartItems.fold(0.0, (s, i) => s + i.total);

  void addToCart(Product p, [int qty = 1]) {
    setQty(p.id, qtyInCart(p.id) + qty);
  }

  void setQty(String id, int qty) {
    final p = productById(id);
    if (p == null || qty <= 0) {
      _cart.remove(id);
    } else {
      _cart[id] = math.min(qty, p.stock);
      if (_cart[id]! <= 0) _cart.remove(id);
    }
    notifyListeners();
  }

  void removeFromCart(String id) {
    _cart.remove(id);
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  double deliveryFeeFor(DeliveryMethod method, double subtotal) {
    if (method == DeliveryMethod.pickup) return 0;
    return subtotal >= freeDeliveryFrom ? 0 : deliveryFee;
  }

  // =========================================================
  // Pedidos
  // =========================================================
  Order placeOrder({
    required DeliveryMethod method,
    required String address,
    required PaymentMethod payment,
    String paymentRef = '',
    double? cashAmount,
    required String customerName,
    required String phone,
    String notes = '',
  }) {
    final lines = cartItems
        .map((i) => OrderLine(
              productId: i.product.id,
              name: i.product.name,
              emoji: i.product.emoji,
              unit: i.product.unit,
              price: i.product.price,
              qty: i.qty,
            ))
        .toList();
    final subtotal = lines.fold(0.0, (s, l) => s + l.total);
    final now = DateTime.now();

    final order = Order(
      id: '${_nextOrder++}',
      lines: lines,
      subtotal: subtotal,
      deliveryFee: deliveryFeeFor(method, subtotal),
      rate: exchangeRate,
      deliveryMethod: method,
      address: address,
      paymentMethod: payment,
      paymentRef: paymentRef,
      cashAmount: cashAmount,
      customerName: customerName,
      phone: phone,
      notes: notes,
      createdAt: now,
      isMine: true,
      status: OrderStatus.recibido,
      history: {OrderStatus.recibido: now},
    );

    for (final i in cartItems) {
      i.product.stock = math.max(0, i.product.stock - i.qty);
    }
    _cart.clear();
    orders.insert(0, order);
    notifyListeners();
    return order;
  }

  Order? orderById(String id) {
    for (final o in orders) {
      if (o.id == id) return o;
    }
    return null;
  }

  List<Order> get myOrders => orders.where((o) => o.isMine).toList();

  void advanceOrder(Order o) {
    final next = o.nextStatus;
    if (next != null) setStatus(o, next);
  }

  void setStatus(Order o, OrderStatus status) {
    o.status = status;
    o.history[status] = DateTime.now();
    if (status == OrderStatus.entregado) o.paymentVerified = true;
    notifyListeners();
  }

  void cancelOrder(Order o) {
    if (!o.isActive) return;
    for (final l in o.lines) {
      final p = productById(l.productId);
      if (p != null) p.stock += l.qty;
    }
    setStatus(o, OrderStatus.cancelado);
  }

  void setPaymentVerified(Order o, bool value) {
    o.paymentVerified = value;
    notifyListeners();
  }

  // =========================================================
  // Cliente
  // =========================================================
  void updateCustomer({String? name, String? phone, String? address}) {
    if (name != null && name.isNotEmpty) customerName = name;
    if (phone != null && phone.isNotEmpty) customerPhone = phone;
    if (address != null && address.isNotEmpty) customerAddress = address;
    notifyListeners();
  }

  // =========================================================
  // Ajustes del negocio
  // =========================================================
  void setExchangeRate(double v) {
    exchangeRate = v;
    notifyListeners();
  }

  void setDeliveryFee(double v) {
    deliveryFee = v;
    notifyListeners();
  }

  void setFreeDeliveryFrom(double v) {
    freeDeliveryFrom = v;
    notifyListeners();
  }

  /// Devuelve false si la acción dejaría la tienda sin forma de entrega.
  bool setDeliveryEnabled(bool v) {
    if (!v && !pickupEnabled) return false;
    deliveryEnabled = v;
    notifyListeners();
    return true;
  }

  bool setPickupEnabled(bool v) {
    if (!v && !deliveryEnabled) return false;
    pickupEnabled = v;
    notifyListeners();
    return true;
  }

  /// Devuelve false si se intenta desactivar el último método de pago.
  bool togglePayment(PaymentMethod m) {
    if (enabledPayments.contains(m)) {
      if (enabledPayments.length == 1) return false;
      enabledPayments.remove(m);
    } else {
      enabledPayments.add(m);
    }
    notifyListeners();
    return true;
  }

  void updateBusiness({
    String? address,
    String? hours,
    String? bank,
    String? phone,
    String? id,
    String? zelle,
    String? holder,
  }) {
    if (address != null) storeAddress = address;
    if (hours != null) storeHours = hours;
    if (bank != null) pmBank = bank;
    if (phone != null) pmPhone = phone;
    if (id != null) pmId = id;
    if (zelle != null) zelleEmail = zelle;
    if (holder != null) zelleHolder = holder;
    notifyListeners();
  }

  // =========================================================
  // Estadísticas (panel)
  // =========================================================
  bool _isToday(DateTime d) {
    final n = DateTime.now();
    return d.year == n.year && d.month == n.month && d.day == n.day;
  }

  List<Order> get todayOrders =>
      orders.where((o) => _isToday(o.createdAt)).toList();

  double get todaySales => todayOrders
      .where((o) => o.status != OrderStatus.cancelado)
      .fold(0.0, (s, o) => s + o.total);

  int get pendingCount => orders.where((o) => o.isActive).length;

  double get avgTicket {
    final valid = orders.where((o) => o.status != OrderStatus.cancelado).toList();
    if (valid.isEmpty) return 0;
    return valid.fold(0.0, (s, o) => s + o.total) / valid.length;
  }

  List<double> get last7DaysSales => [...previousDaysSales, todaySales];

  Map<OrderStatus, int> get statusCounts {
    final m = <OrderStatus, int>{};
    for (final o in orders) {
      m[o.status] = (m[o.status] ?? 0) + 1;
    }
    return m;
  }

  List<MapEntry<Product, int>> get topSellers {
    final m = <String, int>{};
    for (final o in orders) {
      if (o.status == OrderStatus.cancelado) continue;
      for (final l in o.lines) {
        m[l.productId] = (m[l.productId] ?? 0) + l.qty;
      }
    }
    final entries = <MapEntry<Product, int>>[];
    m.forEach((id, q) {
      final p = productById(id);
      if (p != null) entries.add(MapEntry(p, q));
    });
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries.take(5).toList();
  }

  List<Product> get lowStock {
    final list = products.where((p) => p.stock <= 5).toList();
    list.sort((a, b) => a.stock.compareTo(b.stock));
    return list;
  }
}
