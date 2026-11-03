import 'package:flutter/material.dart';

class ProductCategory {
  const ProductCategory({
    required this.id,
    required this.name,
    required this.emoji,
    required this.color,
  });

  final String id;
  final String name;
  final String emoji;
  final Color color;
}

class Product {
  Product({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.price,
    this.oldPrice,
    required this.unit,
    required this.emoji,
    this.description = '',
    this.stock = 50,
    this.active = true,
    this.featured = false,
  });

  final String id;
  String name;
  String categoryId;

  /// Precio en USD.
  double price;

  /// Precio anterior (si existe y es mayor, el producto está en oferta).
  double? oldPrice;
  String unit;
  String emoji;
  String description;
  int stock;
  bool active;
  bool featured;

  bool get onSale => oldPrice != null && oldPrice! > price;

  int get discountPercent =>
      onSale ? ((1 - price / oldPrice!) * 100).round() : 0;

  bool get inStock => stock > 0;
}

class CartItem {
  const CartItem(this.product, this.qty);

  final Product product;
  final int qty;

  double get total => product.price * qty;
}
