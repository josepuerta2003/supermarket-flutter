import 'package:flutter/material.dart';

/// Tipo de cuenta. El personal (empleado o administrador) puede entrar
/// al panel del negocio; el cliente solo ve la tienda.
enum Rol { cliente, empleado, administrador }

extension RolX on Rol {
  String get etiqueta {
    switch (this) {
      case Rol.cliente:
        return 'Cliente';
      case Rol.empleado:
        return 'Empleado';
      case Rol.administrador:
        return 'Administrador';
    }
  }

  IconData get icono {
    switch (this) {
      case Rol.cliente:
        return Icons.person_outline;
      case Rol.empleado:
        return Icons.badge_outlined;
      case Rol.administrador:
        return Icons.admin_panel_settings_outlined;
    }
  }

  bool get esPersonal => this != Rol.cliente;
}

class Direccion {
  Direccion({
    required this.id,
    required this.etiqueta,
    required this.detalle,
    this.referencia = '',
  });

  final String id;
  String etiqueta;
  String detalle;
  String referencia;

  String get completa =>
      referencia.trim().isEmpty ? detalle : '$detalle (Ref: $referencia)';
}

class Usuario {
  Usuario({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.telefono,
    required String clave,
    this.rol = Rol.cliente,
    this.cedula = '',
    this.fechaNacimiento,
    List<Direccion>? direcciones,
    this.puntos = 0,
    this.pedidos = 0,
    this.gastado = 0,
    this.activo = true,
    DateTime? registrado,
    this.notifPromos = true,
    this.notifPedidos = true,
    this.notifWhatsapp = false,
  })  : _clave = clave,
        direcciones = direcciones ?? [],
        registrado = registrado ?? DateTime.now();

  final String id;
  String nombre;
  String correo;
  String telefono;
  String cedula;
  DateTime? fechaNacimiento;
  Rol rol;
  final List<Direccion> direcciones;
  int puntos;
  int pedidos;
  double gastado;
  bool activo;
  final DateTime registrado;
  DateTime? ultimoAcceso;
  bool notifPromos;
  bool notifPedidos;
  bool notifWhatsapp;
  String _clave;

  bool claveEs(String c) => c == _clave;
  void cambiarClave(String nueva) => _clave = nueva;

  bool get esPersonal => rol.esPersonal;

  /// La primera dirección de la lista es la principal.
  Direccion? get direccionPrincipal =>
      direcciones.isEmpty ? null : direcciones.first;

  String get primerNombre {
    final partes = nombre.trim().split(RegExp(r'\s+'));
    return partes.isEmpty || partes.first.isEmpty ? nombre : partes.first;
  }

  String get iniciales {
    final partes = nombre
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();
    return partes.isEmpty ? '?' : partes;
  }

  int? get edad {
    final f = fechaNacimiento;
    if (f == null) return null;
    final hoy = DateTime.now();
    var e = hoy.year - f.year;
    if (hoy.month < f.month || (hoy.month == f.month && hoy.day < f.day)) e--;
    return e;
  }
}

/// Utilidades de formato usadas por las pantallas de cuentas.
String fechaCorta(DateTime d) {
  String dos(int n) => n.toString().padLeft(2, '0');
  return '${dos(d.day)}/${dos(d.month)}/${d.year}';
}

String soloDigitos(String s) => s.replaceAll(RegExp(r'\D'), '');
