import 'package:flutter/material.dart';

import 'modelos.dart';

/// Datos del negocio que usan las pantallas de cuentas.
/// Se configura una sola vez en `main()` con [Sesion.configurar].
class CuentasConfig {
  const CuentasConfig({
    required this.nombreNegocio,
    this.eslogan = '',
    this.icono = Icons.storefront_rounded,
    this.nombrePanel = 'Panel del negocio',
    this.programaPuntos = 'Puntos',
    this.puntosPorDolar = 10,
    this.pideCedula = false,
    this.pideMayorEdad = false,
    this.alActualizarDatos,
  });

  final String nombreNegocio;
  final String eslogan;
  final IconData icono;

  /// Nombre del panel del dueño (por ejemplo "Panel de cocina").
  final String nombrePanel;

  /// Nombre del programa de fidelidad (por ejemplo "FarmaPuntos").
  final String programaPuntos;
  final int puntosPorDolar;

  /// Pide cédula en el registro.
  final bool pideCedula;

  /// Pide fecha de nacimiento y exige 18 años o más (licorerías).
  final bool pideMayorEdad;

  /// Se llama cada vez que el cliente inicia sesión o cambia sus datos,
  /// para copiar nombre, teléfono y dirección al estado de la tienda.
  final void Function(Usuario usuario)? alActualizarDatos;
}

/// Sesión y cuentas de usuario de la demo (en memoria).
///
/// Para producción se reemplazan estos métodos por Firebase Auth / Firestore
/// o por la API del negocio, sin tocar las pantallas.
class Sesion extends ChangeNotifier {
  Sesion._();

  static final Sesion instancia = Sesion._();

  CuentasConfig config = const CuentasConfig(nombreNegocio: 'Mi negocio');
  final List<Usuario> usuarios = [];
  Usuario? usuario;
  bool invitado = false;

  /// Solo para el personal: true muestra el panel, false la tienda.
  bool modoPanel = false;

  int _secuencia = 100;

  static void configurar(CuentasConfig config) {
    instancia.config = config;
    if (instancia.usuarios.isEmpty) instancia._sembrarDemo();
  }

  // ---------------------------------------------------------------
  // Estado
  // ---------------------------------------------------------------
  bool get dentro => usuario != null || invitado;
  bool get conCuenta => usuario != null;
  bool get esPersonal => usuario?.esPersonal ?? false;
  bool get esAdmin => usuario?.rol == Rol.administrador;

  List<Usuario> get clientes =>
      usuarios.where((u) => u.rol == Rol.cliente).toList();
  List<Usuario> get personal => usuarios.where((u) => u.esPersonal).toList();

  int get nuevosEsteMes {
    final hoy = DateTime.now();
    return clientes
        .where((u) =>
            u.registrado.year == hoy.year && u.registrado.month == hoy.month)
        .length;
  }

  int get bloqueados => usuarios.where((u) => !u.activo).length;

  // ---------------------------------------------------------------
  // Acceso
  // ---------------------------------------------------------------
  Usuario? _buscar(String correoOTelefono) {
    final t = correoOTelefono.trim().toLowerCase();
    final dig = soloDigitos(t);
    for (final u in usuarios) {
      if (u.correo.toLowerCase() == t) return u;
      if (dig.length >= 7 && soloDigitos(u.telefono) == dig) return u;
    }
    return null;
  }

  /// Devuelve un mensaje de error o `null` si entró.
  String? iniciarSesion(String correoOTelefono, String clave) {
    if (correoOTelefono.trim().isEmpty || clave.isEmpty) {
      return 'Escribe tu correo (o teléfono) y tu contraseña.';
    }
    final u = _buscar(correoOTelefono);
    if (u == null) return 'No existe una cuenta con ese correo o teléfono.';
    if (!u.claveEs(clave)) return 'Contraseña incorrecta.';
    if (!u.activo) {
      return 'Esta cuenta está bloqueada. Comunícate con el negocio.';
    }
    _entrar(u);
    return null;
  }

  /// Devuelve un mensaje de error o `null` si la cuenta se creó.
  String? registrar({
    required String nombre,
    required String correo,
    required String telefono,
    required String clave,
    String cedula = '',
    DateTime? fechaNacimiento,
    String direccion = '',
  }) {
    if (nombre.trim().length < 3) return 'Escribe tu nombre y apellido.';
    if (!correoValido(correo)) return 'El correo no es válido.';
    if (soloDigitos(telefono).length < 10) return 'El teléfono no es válido.';
    if (clave.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres.';
    }
    if (_buscar(correo) != null) return 'Ya existe una cuenta con ese correo.';
    if (_buscar(telefono) != null) {
      return 'Ya existe una cuenta con ese teléfono.';
    }
    if (config.pideMayorEdad) {
      if (fechaNacimiento == null) return 'Indica tu fecha de nacimiento.';
      if (edadDe(fechaNacimiento) < 18) {
        return 'Debes ser mayor de 18 años para crear una cuenta.';
      }
    }
    final u = Usuario(
      id: 'u${_secuencia++}',
      nombre: nombre.trim(),
      correo: correo.trim().toLowerCase(),
      telefono: telefono.trim(),
      clave: clave,
      cedula: cedula.trim(),
      fechaNacimiento: fechaNacimiento,
      puntos: 50, // regalo de bienvenida
      direcciones: [
        if (direccion.trim().isNotEmpty)
          Direccion(id: 'd${_secuencia++}', etiqueta: 'Casa', detalle: direccion.trim()),
      ],
    );
    usuarios.add(u);
    _entrar(u);
    return null;
  }

  void entrarComoInvitado() {
    usuario = null;
    invitado = true;
    modoPanel = false;
    notifyListeners();
  }

  void _entrar(Usuario u) {
    usuario = u;
    invitado = false;
    modoPanel = u.esPersonal;
    u.ultimoAcceso = DateTime.now();
    _sincronizar();
    notifyListeners();
  }

  void cerrarSesion() {
    usuario = null;
    invitado = false;
    modoPanel = false;
    notifyListeners();
  }

  /// Cierra sesión desde cualquier pantalla y vuelve al inicio de la app.
  static void salir(BuildContext context) {
    Navigator.of(context).popUntil((r) => r.isFirst);
    instancia.cerrarSesion();
  }

  void verPanel() {
    if (!esPersonal) return;
    modoPanel = true;
    notifyListeners();
  }

  void verTienda() {
    modoPanel = false;
    notifyListeners();
  }

  /// En la demo no se envían correos: se muestra un mensaje.
  String recuperarClave(String correoOTelefono) {
    final u = _buscar(correoOTelefono);
    if (u == null) {
      return 'Si existe una cuenta con esos datos, te enviaremos un enlace '
          'para crear una nueva contraseña.';
    }
    return 'Enviamos un enlace a ${_ocultarCorreo(u.correo)} para crear una '
        'nueva contraseña.';
  }

  // ---------------------------------------------------------------
  // Perfil del usuario actual
  // ---------------------------------------------------------------
  String? actualizarDatos({
    required String nombre,
    required String correo,
    required String telefono,
    String? cedula,
  }) {
    final u = usuario;
    if (u == null) return 'No has iniciado sesión.';
    if (nombre.trim().length < 3) return 'Escribe tu nombre y apellido.';
    if (!correoValido(correo)) return 'El correo no es válido.';
    if (soloDigitos(telefono).length < 10) return 'El teléfono no es válido.';
    final otroCorreo = _buscar(correo);
    if (otroCorreo != null && otroCorreo.id != u.id) {
      return 'Ese correo ya lo usa otra cuenta.';
    }
    final otroTel = _buscar(telefono);
    if (otroTel != null && otroTel.id != u.id) {
      return 'Ese teléfono ya lo usa otra cuenta.';
    }
    u
      ..nombre = nombre.trim()
      ..correo = correo.trim().toLowerCase()
      ..telefono = telefono.trim();
    if (cedula != null) u.cedula = cedula.trim();
    _sincronizar();
    notifyListeners();
    return null;
  }

  String? cambiarClave(String actual, String nueva) {
    final u = usuario;
    if (u == null) return 'No has iniciado sesión.';
    if (!u.claveEs(actual)) return 'La contraseña actual no es correcta.';
    if (nueva.length < 6) {
      return 'La nueva contraseña debe tener al menos 6 caracteres.';
    }
    u.cambiarClave(nueva);
    notifyListeners();
    return null;
  }

  /// Elimina la cuenta del usuario actual. Devuelve un error o `null`.
  String? eliminarMiCuenta(String clave) {
    final u = usuario;
    if (u == null) return 'No has iniciado sesión.';
    if (!u.claveEs(clave)) return 'Contraseña incorrecta.';
    if (_esUltimoAdmin(u)) {
      return 'Eres el único administrador: asigna otro antes de eliminar tu cuenta.';
    }
    usuarios.remove(u);
    cerrarSesion();
    return null;
  }

  void guardarDireccion({
    Direccion? existente,
    required String etiqueta,
    required String detalle,
    String referencia = '',
  }) {
    final u = usuario;
    if (u == null) return;
    if (existente != null) {
      existente
        ..etiqueta = etiqueta.trim()
        ..detalle = detalle.trim()
        ..referencia = referencia.trim();
    } else {
      u.direcciones.add(Direccion(
        id: 'd${_secuencia++}',
        etiqueta: etiqueta.trim(),
        detalle: detalle.trim(),
        referencia: referencia.trim(),
      ));
    }
    _sincronizar();
    notifyListeners();
  }

  void eliminarDireccion(Direccion d) {
    usuario?.direcciones.remove(d);
    _sincronizar();
    notifyListeners();
  }

  void marcarPrincipal(Direccion d) {
    final lista = usuario?.direcciones;
    if (lista == null || !lista.remove(d)) return;
    lista.insert(0, d);
    _sincronizar();
    notifyListeners();
  }

  void cambiarNotificaciones({bool? promos, bool? pedidos, bool? whatsapp}) {
    final u = usuario;
    if (u == null) return;
    if (promos != null) u.notifPromos = promos;
    if (pedidos != null) u.notifPedidos = pedidos;
    if (whatsapp != null) u.notifWhatsapp = whatsapp;
    notifyListeners();
  }

  /// Suma un pedido y sus puntos al cliente que tiene la sesión abierta.
  void registrarCompra(double totalUsd) {
    final u = usuario;
    if (u == null) return;
    u.pedidos++;
    u.gastado += totalUsd;
    u.puntos += (totalUsd * config.puntosPorDolar).round();
    notifyListeners();
  }

  // ---------------------------------------------------------------
  // Gestión de usuarios (panel del negocio)
  // ---------------------------------------------------------------
  String? crearUsuario({
    required String nombre,
    required String correo,
    required String telefono,
    required String clave,
    required Rol rol,
  }) {
    if (!esAdmin) return 'Solo un administrador puede crear usuarios.';
    if (nombre.trim().length < 3) return 'Escribe nombre y apellido.';
    if (!correoValido(correo)) return 'El correo no es válido.';
    if (soloDigitos(telefono).length < 10) return 'El teléfono no es válido.';
    if (clave.length < 6) return 'La contraseña debe tener al menos 6 caracteres.';
    if (_buscar(correo) != null) return 'Ya existe una cuenta con ese correo.';
    if (_buscar(telefono) != null) return 'Ya existe una cuenta con ese teléfono.';
    usuarios.add(Usuario(
      id: 'u${_secuencia++}',
      nombre: nombre.trim(),
      correo: correo.trim().toLowerCase(),
      telefono: telefono.trim(),
      clave: clave,
      rol: rol,
    ));
    notifyListeners();
    return null;
  }

  String? cambiarRol(Usuario u, Rol rol) {
    if (!esAdmin) return 'Solo un administrador puede cambiar roles.';
    if (u.rol == rol) return null;
    if (_esUltimoAdmin(u)) return 'Debe quedar al menos un administrador activo.';
    u.rol = rol;
    notifyListeners();
    return null;
  }

  String? alternarActivo(Usuario u) {
    if (!esAdmin) return 'Solo un administrador puede bloquear cuentas.';
    if (u.id == usuario?.id) return 'No puedes bloquear tu propia cuenta.';
    if (u.activo && _esUltimoAdmin(u)) {
      return 'Debe quedar al menos un administrador activo.';
    }
    u.activo = !u.activo;
    notifyListeners();
    return null;
  }

  /// Devuelve la contraseña temporal asignada, o `null` si no se pudo.
  String? restablecerClave(Usuario u) {
    if (!esAdmin) return null;
    final temporal = 'tmp${(DateTime.now().millisecondsSinceEpoch % 9000) + 1000}';
    u.cambiarClave(temporal);
    notifyListeners();
    return temporal;
  }

  String? eliminarUsuario(Usuario u) {
    if (!esAdmin) return 'Solo un administrador puede eliminar cuentas.';
    if (u.id == usuario?.id) return 'No puedes eliminar tu propia cuenta desde aquí.';
    if (_esUltimoAdmin(u)) return 'Debe quedar al menos un administrador activo.';
    usuarios.remove(u);
    notifyListeners();
    return null;
  }

  bool _esUltimoAdmin(Usuario u) {
    if (u.rol != Rol.administrador || !u.activo) return false;
    return usuarios.where((x) => x.rol == Rol.administrador && x.activo).length <= 1;
  }

  // ---------------------------------------------------------------
  // Utilidades
  // ---------------------------------------------------------------
  void _sincronizar() {
    final u = usuario;
    if (u != null && !u.esPersonal) config.alActualizarDatos?.call(u);
  }

  static bool correoValido(String c) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(c.trim());

  static int edadDe(DateTime f) {
    final hoy = DateTime.now();
    var e = hoy.year - f.year;
    if (hoy.month < f.month || (hoy.month == f.month && hoy.day < f.day)) e--;
    return e;
  }

  static String _ocultarCorreo(String c) {
    final i = c.indexOf('@');
    if (i <= 1) return c;
    return '${c[0]}${'*' * (i - 1)}${c.substring(i)}';
  }

  /// Vuelve a las cuentas de demostración (útil antes de una presentación).
  void reiniciarDemo() {
    usuarios.clear();
    usuario = null;
    invitado = false;
    modoPanel = false;
    _sembrarDemo();
    notifyListeners();
  }

  void _sembrarDemo() {
    final hoy = DateTime.now();
    usuarios.addAll([
      Usuario(
        id: 'u1',
        nombre: 'Dueño del negocio',
        correo: 'admin@demo.com',
        telefono: '0414-000-0001',
        clave: 'admin123',
        rol: Rol.administrador,
        registrado: hoy.subtract(const Duration(days: 120)),
      ),
      Usuario(
        id: 'u2',
        nombre: 'Empleado Demo',
        correo: 'empleado@demo.com',
        telefono: '0414-000-0002',
        clave: 'empleado123',
        rol: Rol.empleado,
        registrado: hoy.subtract(const Duration(days: 60)),
      ),
      Usuario(
        id: 'u3',
        nombre: 'Cliente Demo',
        correo: 'cliente@demo.com',
        telefono: '0412-000-0000',
        clave: 'cliente123',
        cedula: config.pideCedula || config.pideMayorEdad ? 'V-12345678' : '',
        fechaNacimiento: DateTime(1995, 5, 14),
        puntos: 340,
        pedidos: 12,
        gastado: 186.5,
        registrado: hoy.subtract(const Duration(days: 45)),
        direcciones: [
          Direccion(
              id: 'd1',
              etiqueta: 'Casa',
              detalle: 'Calle 1, casa 2, urb. Centro',
              referencia: 'Portón negro'),
          Direccion(
              id: 'd2',
              etiqueta: 'Trabajo',
              detalle: 'Av. Principal, edif. Torre Sol, piso 3'),
        ],
      ),
      Usuario(
        id: 'u4',
        nombre: 'María González',
        correo: 'maria@ejemplo.com',
        telefono: '0424-111-2233',
        clave: 'demo123',
        puntos: 120,
        pedidos: 5,
        gastado: 74,
        registrado: hoy.subtract(const Duration(days: 8)),
        direcciones: [
          Direccion(id: 'd3', etiqueta: 'Casa', detalle: 'Urb. Los Pinos, calle 3, casa 12'),
        ],
      ),
      Usuario(
        id: 'u5',
        nombre: 'Carlos Rodríguez',
        correo: 'carlos@ejemplo.com',
        telefono: '0416-222-3344',
        clave: 'demo123',
        puntos: 60,
        pedidos: 2,
        gastado: 31.2,
        registrado: hoy.subtract(const Duration(days: 3)),
      ),
      Usuario(
        id: 'u6',
        nombre: 'Luis Martínez',
        correo: 'luis@ejemplo.com',
        telefono: '0426-333-4455',
        clave: 'demo123',
        pedidos: 1,
        gastado: 12,
        activo: false,
        registrado: hoy.subtract(const Duration(days: 90)),
      ),
    ]);
  }
}
