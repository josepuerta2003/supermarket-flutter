import 'package:flutter/material.dart';

import 'pantalla_acceso.dart';
import 'sesion.dart';

/// Pantalla raíz de la app: decide qué mostrar según la sesión.
///
/// * Sin sesión → [PantallaAcceso] (entrar, crear cuenta o invitado).
/// * Personal del negocio con [panel] → el panel (puede cambiar a la tienda).
/// * Cliente o invitado → la [tienda].
class CuentasRaiz extends StatelessWidget {
  const CuentasRaiz({super.key, required this.tienda, this.panel});

  final WidgetBuilder tienda;
  final WidgetBuilder? panel;

  @override
  Widget build(BuildContext context) {
    final s = Sesion.instancia;
    return AnimatedBuilder(
      animation: s,
      builder: (context, _) {
        final Widget hijo;
        final verPanel = panel;
        if (!s.dentro) {
          hijo = const PantallaAcceso(key: ValueKey('acceso'));
        } else if (verPanel != null && s.esPersonal && s.modoPanel) {
          hijo = KeyedSubtree(
            key: const ValueKey('panel'),
            child: verPanel(context),
          );
        } else {
          hijo = KeyedSubtree(
            key: const ValueKey('tienda'),
            child: tienda(context),
          );
        }
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: hijo,
        );
      },
    );
  }
}

/// Abre una pantalla solo si quien la pide es personal del negocio.
/// Si no, explica por qué y ofrece entrar con una cuenta autorizada.
Future<void> abrirSoloPersonal(BuildContext context, WidgetBuilder pantalla) async {
  final s = Sesion.instancia;
  if (s.esPersonal) {
    await Navigator.of(context).push(MaterialPageRoute(builder: pantalla));
    return;
  }
  final entrar = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const Icon(Icons.lock_outline),
      title: Text(s.config.nombrePanel),
      content: Text(
        s.conCuenta
            ? 'Tu cuenta es de cliente. Para entrar al panel inicia sesión con '
                'una cuenta de empleado o administrador.'
            : 'El panel es solo para el personal del negocio. Inicia sesión '
                'con una cuenta de empleado o administrador.',
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar')),
        FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Iniciar sesión')),
      ],
    ),
  );
  if (entrar != true || !context.mounted) return;
  await Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const PantallaAcceso()),
  );
  if (!context.mounted || !s.esPersonal) return;
  await Navigator.of(context).push(MaterialPageRoute(builder: pantalla));
}
