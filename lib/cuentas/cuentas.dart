/// Módulo de cuentas de usuario (demo, en memoria y sin paquetes externos).
///
/// Incluye: inicio de sesión, registro, modo invitado, recuperación de
/// contraseña, perfil (datos, direcciones, seguridad, notificaciones y
/// puntos), acceso al panel por rol y gestión de usuarios para el negocio.
///
/// Cuentas de demostración:
///   cliente@demo.com  / cliente123
///   empleado@demo.com / empleado123
///   admin@demo.com    / admin123
library;

export 'cuentas_raiz.dart';
export 'modelos.dart';
export 'pantalla_acceso.dart';
export 'pantalla_perfil.dart';
export 'pantalla_usuarios.dart';
export 'sesion.dart';
