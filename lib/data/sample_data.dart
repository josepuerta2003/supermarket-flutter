import 'package:flutter/material.dart';

import '../models/product.dart';

/// Catálogo de demostración. Productos genéricos, sin marcas,
/// para mostrar la app a cualquier supermercado.

const List<ProductCategory> sampleCategories = [
  ProductCategory(id: 'viveres', name: 'Víveres', emoji: '🛒', color: Color(0xFFF4A261)),
  ProductCategory(id: 'frutas', name: 'Frutas y verduras', emoji: '🥬', color: Color(0xFF52B788)),
  ProductCategory(id: 'carnes', name: 'Carnes y pollo', emoji: '🍗', color: Color(0xFFE76F51)),
  ProductCategory(id: 'lacteos', name: 'Lácteos y huevos', emoji: '🥛', color: Color(0xFF4EA8DE)),
  ProductCategory(id: 'bebidas', name: 'Bebidas', emoji: '🥤', color: Color(0xFF9B5DE5)),
  ProductCategory(id: 'panaderia', name: 'Panadería', emoji: '🥖', color: Color(0xFFD4A373)),
  ProductCategory(id: 'limpieza', name: 'Limpieza', emoji: '🧽', color: Color(0xFF2EC4B6)),
  ProductCategory(id: 'cuidado', name: 'Cuidado personal', emoji: '🧼', color: Color(0xFFF15BB5)),
];

List<Product> sampleProducts() => [
      // Víveres
      Product(id: 'p01', name: 'Harina de maíz precocida', categoryId: 'viveres', price: 1.15, oldPrice: 1.35, unit: 'Paquete 1 kg', emoji: '🌽', featured: true, stock: 120,
          description: 'Harina de maíz blanco precocida, ideal para arepas, empanadas y hallacas.'),
      Product(id: 'p02', name: 'Arroz blanco tipo I', categoryId: 'viveres', price: 1.25, unit: 'Paquete 1 kg', emoji: '🍚', featured: true, stock: 90,
          description: 'Arroz de grano largo, rinde y queda suelto.'),
      Product(id: 'p03', name: 'Pasta larga', categoryId: 'viveres', price: 1.40, oldPrice: 1.70, unit: 'Paquete 1 kg', emoji: '🍝', stock: 70,
          description: 'Pasta de sémola de trigo durum, tipo spaghetti.'),
      Product(id: 'p04', name: 'Aceite de girasol', categoryId: 'viveres', price: 3.20, unit: 'Botella 1 L', emoji: '🌻', featured: true, stock: 45,
          description: 'Aceite vegetal 100% girasol para freír y cocinar.'),
      Product(id: 'p05', name: 'Azúcar refinada', categoryId: 'viveres', price: 1.30, unit: 'Paquete 1 kg', emoji: '🍬', stock: 60,
          description: 'Azúcar blanca refinada.'),
      Product(id: 'p06', name: 'Café molido', categoryId: 'viveres', price: 4.50, oldPrice: 5.20, unit: 'Paquete 500 g', emoji: '☕', featured: true, stock: 38,
          description: 'Café tostado y molido, aroma intenso. Para colar o greca.'),
      Product(id: 'p07', name: 'Caraotas negras', categoryId: 'viveres', price: 2.10, unit: 'Paquete 1 kg', emoji: '🥫', stock: 40,
          description: 'Caraotas negras seleccionadas, perfectas para el pabellón.'),
      Product(id: 'p08', name: 'Atún en aceite', categoryId: 'viveres', price: 1.60, unit: 'Lata 140 g', emoji: '🐟', stock: 4,
          description: 'Lomitos de atún en aceite vegetal.'),

      // Frutas y verduras
      Product(id: 'p09', name: 'Cambur', categoryId: 'frutas', price: 0.90, unit: 'Por kg', emoji: '🍌', featured: true, stock: 80,
          description: 'Cambur fresco, en su punto.'),
      Product(id: 'p10', name: 'Tomate', categoryId: 'frutas', price: 1.50, unit: 'Por kg', emoji: '🍅', stock: 60,
          description: 'Tomate perita fresco para ensaladas y guisos.'),
      Product(id: 'p11', name: 'Cebolla', categoryId: 'frutas', price: 1.20, unit: 'Por kg', emoji: '🧅', stock: 55,
          description: 'Cebolla blanca.'),
      Product(id: 'p12', name: 'Papa', categoryId: 'frutas', price: 1.10, unit: 'Por kg', emoji: '🥔', stock: 70,
          description: 'Papa lavada, ideal para sopas, puré y fritas.'),
      Product(id: 'p13', name: 'Aguacate', categoryId: 'frutas', price: 1.00, oldPrice: 1.30, unit: 'Unidad', emoji: '🥑', stock: 30,
          description: 'Aguacate grande y cremoso.'),

      // Carnes y pollo
      Product(id: 'p14', name: 'Pollo entero', categoryId: 'carnes', price: 3.40, unit: 'Por kg', emoji: '🍗', featured: true, stock: 35,
          description: 'Pollo fresco entero, limpio.'),
      Product(id: 'p15', name: 'Carne molida de primera', categoryId: 'carnes', price: 6.80, oldPrice: 7.50, unit: 'Por kg', emoji: '🥩', stock: 25,
          description: 'Carne de res molida, baja en grasa.'),
      Product(id: 'p16', name: 'Chuleta ahumada', categoryId: 'carnes', price: 7.90, unit: 'Por kg', emoji: '🥓', stock: 3,
          description: 'Chuleta de cerdo ahumada.'),

      // Lácteos y huevos
      Product(id: 'p17', name: 'Leche completa', categoryId: 'lacteos', price: 1.70, unit: 'Envase 1 L', emoji: '🥛', featured: true, stock: 50,
          description: 'Leche de vaca completa, pasteurizada.'),
      Product(id: 'p18', name: 'Queso blanco duro', categoryId: 'lacteos', price: 6.50, unit: 'Por kg', emoji: '🧀', stock: 20,
          description: 'Queso blanco llanero, ideal para arepas.'),
      Product(id: 'p19', name: 'Huevos', categoryId: 'lacteos', price: 5.80, oldPrice: 6.40, unit: 'Cartón 30 und', emoji: '🥚', featured: true, stock: 28,
          description: 'Huevos frescos tamaño grande.'),
      Product(id: 'p20', name: 'Mantequilla', categoryId: 'lacteos', price: 3.90, unit: 'Envase 500 g', emoji: '🧈', stock: 22,
          description: 'Mantequilla con sal.'),

      // Bebidas
      Product(id: 'p21', name: 'Agua mineral', categoryId: 'bebidas', price: 0.80, unit: 'Botella 1,5 L', emoji: '💧', stock: 100,
          description: 'Agua mineral natural sin gas.'),
      Product(id: 'p22', name: 'Refresco de cola', categoryId: 'bebidas', price: 2.20, oldPrice: 2.60, unit: 'Botella 2 L', emoji: '🥤', stock: 48,
          description: 'Refresco sabor cola.'),
      Product(id: 'p23', name: 'Jugo de naranja', categoryId: 'bebidas', price: 2.40, unit: 'Envase 1 L', emoji: '🧃', stock: 30,
          description: 'Jugo de naranja pasteurizado.'),

      // Panadería
      Product(id: 'p24', name: 'Pan campesino', categoryId: 'panaderia', price: 1.20, unit: 'Unidad', emoji: '🥖', featured: true, stock: 40,
          description: 'Pan horneado del día.'),
      Product(id: 'p25', name: 'Pan de sándwich', categoryId: 'panaderia', price: 2.30, unit: 'Paquete 500 g', emoji: '🍞', stock: 25,
          description: 'Pan blanco rebanado.'),

      // Limpieza
      Product(id: 'p26', name: 'Detergente en polvo', categoryId: 'limpieza', price: 3.10, oldPrice: 3.60, unit: 'Paquete 1 kg', emoji: '🧺', stock: 33,
          description: 'Detergente para ropa blanca y de color.'),
      Product(id: 'p27', name: 'Lavaplatos en crema', categoryId: 'limpieza', price: 1.90, unit: 'Envase 500 g', emoji: '🍽️', stock: 40,
          description: 'Lavaplatos en crema aroma limón.'),
      Product(id: 'p28', name: 'Cloro', categoryId: 'limpieza', price: 1.10, unit: 'Botella 1 L', emoji: '🧴', stock: 5,
          description: 'Blanqueador desinfectante.'),

      // Cuidado personal
      Product(id: 'p29', name: 'Papel higiénico', categoryId: 'cuidado', price: 2.60, unit: 'Paquete 4 rollos', emoji: '🧻', featured: true, stock: 60,
          description: 'Papel higiénico doble hoja.'),
      Product(id: 'p30', name: 'Jabón de baño', categoryId: 'cuidado', price: 2.40, unit: 'Paquete 3 und', emoji: '🧼', stock: 45,
          description: 'Jabón de tocador humectante.'),
      Product(id: 'p31', name: 'Crema dental', categoryId: 'cuidado', price: 1.80, oldPrice: 2.10, unit: 'Tubo 100 ml', emoji: '🦷', stock: 36,
          description: 'Crema dental con flúor, protección anticaries.'),
    ];

/// Emojis disponibles al crear un producto desde el panel.
const List<String> productEmojis = [
  '🛒', '🌽', '🍚', '🍝', '🌻', '🍬', '☕', '🥫', '🐟', '🍌', '🍅', '🧅',
  '🥔', '🥑', '🍎', '🍊', '🥕', '🍗', '🥩', '🥓', '🥛', '🧀', '🥚', '🧈',
  '💧', '🥤', '🧃', '🍺', '🥖', '🍞', '🍪', '🍫', '🧺', '🍽️', '🧴', '🧻',
  '🧼', '🦷', '🍼', '🐶',
];
