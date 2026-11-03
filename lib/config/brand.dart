import 'package:flutter/material.dart';

/// ===============================================================
///  IDENTIDAD DE LA MARCA
///  Cambia estos valores para cada supermercado y toda la app
///  se adapta: nombre, colores y logo.
/// ===============================================================
class Brand {
  Brand._();

  static const String appName = 'SuperMarket';
  static const String slogan = 'Tu mercado, a un toque';

  /// Color principal (botones, barra, precios).
  static const Color primary = Color(0xFF16A34A);

  /// Color de acento (ofertas, detalles).
  static const Color secondary = Color(0xFFF59E0B);

  static const Color background = Color(0xFFF6F7F9);
  static const Color textDark = Color(0xFF1C1F24);

  /// Ruta del logo del cliente, por ejemplo 'assets/logo.png'.
  /// Si se deja vacío se muestra un logo genérico.
  /// (Recuerda declarar el asset en pubspec.yaml).
  static const String logoAsset = '';

  static const String whatsapp = '+58 400-000-0000';
}

/// Datos iniciales del negocio. Todos se pueden cambiar
/// también desde el Panel del supermercado > Ajustes.
class BusinessDefaults {
  BusinessDefaults._();

  static const String storeAddress = 'Av. Principal, Local 1 (dirección del negocio)';
  static const String storeHours = 'Lun a Sáb 8:00 am – 8:00 pm · Dom 9:00 am – 2:00 pm';

  static const String pmBank = 'Banco del negocio';
  static const String pmPhone = '0414-000-0000';
  static const String pmId = 'J-00000000-0';

  static const String zelleEmail = 'pagos@tunegocio.com';
  static const String zelleHolder = 'Nombre del titular';

  /// Tasa de ejemplo (Bs por 1 USD). Se edita desde el panel.
  static const double exchangeRate = 200.0;
  static const double deliveryFee = 2.0;
  static const double freeDeliveryFrom = 30.0;
}
