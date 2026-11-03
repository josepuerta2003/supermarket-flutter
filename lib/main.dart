import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/brand.dart';
import 'config/theme.dart';
import 'cuentas/cuentas.dart';
import 'screens/splash_screen.dart';
import 'state/app_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final estado = AppState();

  // Cuentas de usuario: login, registro, perfil y roles.
  Sesion.configurar(CuentasConfig(
    nombreNegocio: Brand.appName,
    eslogan: Brand.slogan,
    icono: Icons.storefront_rounded,
    nombrePanel: 'Panel del supermercado',
    programaPuntos: 'SuperPuntos',
    alActualizarDatos: (u) => estado.updateCustomer(
      name: u.nombre,
      phone: u.telefono,
      address: u.direccionPrincipal?.completa,
    ),
  ));

  runApp(
    ChangeNotifierProvider.value(
      value: estado,
      child: const SuperApp(),
    ),
  );
}

class SuperApp extends StatelessWidget {
  const SuperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: Brand.appName,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const SplashScreen(),
    );
  }
}
