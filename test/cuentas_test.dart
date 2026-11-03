import 'package:flutter_test/flutter_test.dart';
import 'package:super_app/cuentas/cuentas.dart';

void main() {
  setUp(() {
    Sesion.configurar(const CuentasConfig(nombreNegocio: 'SuperMarket'));
    Sesion.instancia.reiniciarDemo();
  });

  test('Login con correo o teléfono y contraseña', () {
    final s = Sesion.instancia;
    expect(s.iniciarSesion('cliente@demo.com', 'mala'), isNotNull);
    expect(s.iniciarSesion('0412-000-0000', 'cliente123'), isNull);
    expect(s.usuario?.correo, 'cliente@demo.com');
    expect(s.esPersonal, isFalse);
  });

  test('Registro nuevo, datos y direcciones', () {
    final s = Sesion.instancia;
    expect(
      s.registrar(
        nombre: 'Ana Prueba',
        correo: 'ana@prueba.com',
        telefono: '0414-123-4567',
        clave: 'secreta1',
        direccion: 'Calle 5',
      ),
      isNull,
    );
    expect(s.usuario?.direccionPrincipal?.detalle, 'Calle 5');
    // No se puede repetir el correo.
    s.cerrarSesion();
    expect(
      s.registrar(
        nombre: 'Otra Ana',
        correo: 'ana@prueba.com',
        telefono: '0414-999-9999',
        clave: 'secreta1',
      ),
      isNotNull,
    );
  });

  test('Roles: el admin gestiona usuarios y siempre queda un admin', () {
    final s = Sesion.instancia;
    expect(s.iniciarSesion('admin@demo.com', 'admin123'), isNull);
    expect(s.esAdmin, isTrue);
    final yo = s.usuario!;
    expect(s.cambiarRol(yo, Rol.cliente), isNotNull);
    expect(s.alternarActivo(yo), isNotNull);

    final empleado = s.usuarios.firstWhere((u) => u.rol == Rol.empleado);
    expect(s.alternarActivo(empleado), isNull);
    expect(empleado.activo, isFalse);
    s.cerrarSesion();
    expect(s.iniciarSesion('empleado@demo.com', 'empleado123'), isNotNull);
  });

  test('Las compras suman puntos', () {
    final s = Sesion.instancia;
    s.iniciarSesion('cliente@demo.com', 'cliente123');
    final antes = s.usuario!.puntos;
    s.registrarCompra(10);
    expect(s.usuario!.puntos, antes + 100);
  });
}
