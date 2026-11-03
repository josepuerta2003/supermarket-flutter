import 'package:flutter/material.dart';

import 'modelos.dart';
import 'pantalla_acceso.dart';
import 'pantalla_usuarios.dart';
import 'sesion.dart';

/// Perfil del usuario: datos, direcciones, seguridad, notificaciones,
/// puntos, acceso al panel (personal) y cierre de sesión.
class PantallaPerfil extends StatelessWidget {
  const PantallaPerfil({
    super.key,
    this.titulo = 'Mi perfil',
    this.extras = const [],
    this.onAbrirPanel,
    this.onMisPedidos,
    this.mostrarAppBar = true,
  });

  final String titulo;

  /// Bloques propios de cada app (datos del negocio, horario, etc.).
  final List<Widget> extras;

  /// Si se indica, el personal ve un botón para abrir el panel.
  final void Function(BuildContext context)? onAbrirPanel;
  final VoidCallback? onMisPedidos;
  final bool mostrarAppBar;

  @override
  Widget build(BuildContext context) {
    final s = Sesion.instancia;
    return AnimatedBuilder(
      animation: s,
      builder: (context, _) {
        final u = s.usuario;
        final cuerpo = ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            if (u == null) const _TarjetaInvitado() else _Cabecera(usuario: u),
            if (u != null && !u.esPersonal) ...[
              const SizedBox(height: 12),
              _TarjetaPuntos(usuario: u),
            ],
            if (u != null && u.esPersonal && onAbrirPanel != null) ...[
              const SizedBox(height: 12),
              _BotonPanel(onTap: () => onAbrirPanel!(context)),
            ],
            if (u != null) ...[
              const _Titulo('Mi cuenta'),
              _Grupo(children: [
                _Opcion(
                  icono: Icons.person_outline,
                  titulo: 'Mis datos',
                  subtitulo: '${u.correo} · ${u.telefono}',
                  onTap: () => _abrir(context, const PantallaMisDatos()),
                ),
                _Opcion(
                  icono: Icons.location_on_outlined,
                  titulo: 'Mis direcciones',
                  subtitulo: u.direccionPrincipal == null
                      ? 'Agrega dónde recibir tus pedidos'
                      : '${u.direcciones.length} guardada(s) · Principal: ${u.direccionPrincipal!.etiqueta}',
                  onTap: () => _abrir(context, const PantallaDirecciones()),
                ),
                if (onMisPedidos != null)
                  _Opcion(
                    icono: Icons.receipt_long_outlined,
                    titulo: 'Mis pedidos',
                    subtitulo: '${u.pedidos} pedido(s) realizados',
                    onTap: onMisPedidos,
                  ),
                _Opcion(
                  icono: Icons.lock_outline,
                  titulo: 'Seguridad',
                  subtitulo: 'Cambiar contraseña o eliminar la cuenta',
                  onTap: () => _abrir(context, const PantallaSeguridad()),
                ),
              ]),
              const _Titulo('Notificaciones'),
              _Grupo(children: [
                SwitchListTile(
                  secondary: const Icon(Icons.local_offer_outlined),
                  title: const Text('Ofertas y promociones'),
                  value: u.notifPromos,
                  onChanged: (v) => s.cambiarNotificaciones(promos: v),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_active_outlined),
                  title: const Text('Estado de mis pedidos'),
                  value: u.notifPedidos,
                  onChanged: (v) => s.cambiarNotificaciones(pedidos: v),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.chat_outlined),
                  title: const Text('Avisos por WhatsApp'),
                  value: u.notifWhatsapp,
                  onChanged: (v) => s.cambiarNotificaciones(whatsapp: v),
                ),
              ]),
            ],
            if (u != null && u.esPersonal) ...[
              const _Titulo('Negocio'),
              _Grupo(children: [
                _Opcion(
                  icono: Icons.group_outlined,
                  titulo: 'Usuarios y clientes',
                  subtitulo: '${s.clientes.length} clientes · ${s.personal.length} del personal',
                  onTap: () => _abrir(context, const PantallaUsuarios()),
                ),
              ]),
            ],
            if (extras.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...extras,
            ],
            const SizedBox(height: 20),
            if (u != null || s.invitado)
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: () => _confirmarSalida(context),
                icon: const Icon(Icons.logout),
                label: Text(u == null ? 'Salir del modo invitado' : 'Cerrar sesión'),
              ),
            const SizedBox(height: 12),
            Center(
              child: Text('${s.config.nombreNegocio} · versión demo',
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ),
          ],
        );
        if (!mostrarAppBar) return cuerpo;
        return Scaffold(appBar: AppBar(title: Text(titulo)), body: cuerpo);
      },
    );
  }

  static void _abrir(BuildContext context, Widget pantalla) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => pantalla));
  }

  Future<void> _confirmarSalida(BuildContext context) async {
    final s = Sesion.instancia;
    if (s.usuario == null) {
      Sesion.salir(context);
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que quieres salir de tu cuenta?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Salir')),
        ],
      ),
    );
    if (ok == true && context.mounted) Sesion.salir(context);
  }
}

// =====================================================================
// Piezas del perfil
// =====================================================================
class _Cabecera extends StatelessWidget {
  const _Cabecera({required this.usuario});

  final Usuario usuario;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.primary,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: cs.onPrimary,
            child: Text(usuario.iniciales,
                style: TextStyle(
                    color: cs.primary, fontSize: 22, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(usuario.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: cs.onPrimary,
                        fontSize: 19,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(usuario.correo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: cs.onPrimary.withAlpha(220))),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _Etiqueta(icono: usuario.rol.icono, texto: usuario.rol.etiqueta),
                    _Etiqueta(
                        icono: Icons.event_outlined,
                        texto: 'Desde ${fechaCorta(usuario.registrado)}'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: cs.onPrimary.withAlpha(40),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 14, color: cs.onPrimary),
          const SizedBox(width: 4),
          Text(texto,
              style: TextStyle(
                  color: cs.onPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _TarjetaPuntos extends StatelessWidget {
  const _TarjetaPuntos({required this.usuario});

  final Usuario usuario;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cfg = Sesion.instancia.config;
    const meta = 500;
    final avance = (usuario.puntos % meta) / meta;
    final faltan = meta - (usuario.puntos % meta);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.workspace_premium_outlined, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(cfg.programaPuntos,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
                Text('${usuario.puntos}',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: cs.primary)),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(value: avance, minHeight: 8),
            ),
            const SizedBox(height: 8),
            Text(
              'Te faltan $faltan puntos para tu próximo descuento · '
              '${usuario.pedidos} pedidos',
              style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaInvitado extends StatelessWidget {
  const _TarjetaInvitado();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    void abrir(bool registro) => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => PantallaAcceso(empezarEnRegistro: registro)));
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: cs.primary.withAlpha(30),
                  child: Icon(Icons.person_outline, color: cs.primary, size: 28),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Estás como invitado',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Crea tu cuenta para guardar tus direcciones, ver tu historial, '
              'pedir más rápido y sumar ${Sesion.instancia.config.programaPuntos}.',
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                      onPressed: () => abrir(true),
                      child: const Text('Crear cuenta')),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                      onPressed: () => abrir(false),
                      child: const Text('Iniciar sesión')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BotonPanel extends StatelessWidget {
  const _BotonPanel({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.inverseSurface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.admin_panel_settings_outlined, color: cs.onInverseSurface),
              const SizedBox(width: 12),
              Expanded(
                child: Text(Sesion.instancia.config.nombrePanel,
                    style: TextStyle(
                        color: cs.onInverseSurface,
                        fontWeight: FontWeight.w800,
                        fontSize: 16)),
              ),
              Icon(Icons.chevron_right, color: cs.onInverseSurface),
            ],
          ),
        ),
      ),
    );
  }
}

class _Titulo extends StatelessWidget {
  const _Titulo(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Text(texto,
          style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.primary)),
    );
  }
}

class _Grupo extends StatelessWidget {
  const _Grupo({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) items.add(const Divider(height: 1, indent: 56));
      items.add(children[i]);
    }
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(children: items),
    );
  }
}

class _Opcion extends StatelessWidget {
  const _Opcion({
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    this.onTap,
  });

  final IconData icono;
  final String titulo;
  final String subtitulo;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icono, color: Theme.of(context).colorScheme.primary),
      title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitulo, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: onTap == null ? null : const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

void _aviso(BuildContext context, String texto) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
}

InputDecoration _deco(String label, IconData icono, {String? ayuda}) =>
    InputDecoration(
      labelText: label,
      helperText: ayuda,
      prefixIcon: Icon(icono),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    );

// =====================================================================
// Mis datos
// =====================================================================
class PantallaMisDatos extends StatefulWidget {
  const PantallaMisDatos({super.key});

  @override
  State<PantallaMisDatos> createState() => _PantallaMisDatosState();
}

class _PantallaMisDatosState extends State<PantallaMisDatos> {
  final _form = GlobalKey<FormState>();
  late final Usuario? _u = Sesion.instancia.usuario;
  late final _nombre = TextEditingController(text: _u?.nombre);
  late final _correo = TextEditingController(text: _u?.correo);
  late final _telefono = TextEditingController(text: _u?.telefono);
  late final _cedula = TextEditingController(text: _u?.cedula);

  @override
  void dispose() {
    _nombre.dispose();
    _correo.dispose();
    _telefono.dispose();
    _cedula.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!(_form.currentState?.validate() ?? false)) return;
    final error = Sesion.instancia.actualizarDatos(
      nombre: _nombre.text,
      correo: _correo.text,
      telefono: _telefono.text,
      cedula: _cedula.text,
    );
    if (error != null) {
      _aviso(context, error);
      return;
    }
    final mensajero = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    mensajero.showSnackBar(const SnackBar(content: Text('Datos actualizados')));
  }

  @override
  Widget build(BuildContext context) {
    final u = _u;
    final cfg = Sesion.instancia.config;
    return Scaffold(
      appBar: AppBar(title: const Text('Mis datos')),
      body: u == null
          ? const Center(child: Text('Inicia sesión para ver tus datos.'))
          : Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  TextFormField(
                    controller: _nombre,
                    textCapitalization: TextCapitalization.words,
                    decoration: _deco('Nombre y apellido', Icons.person_outline),
                    validator: (v) => (v == null || v.trim().length < 3)
                        ? 'Escribe nombre y apellido'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _telefono,
                    keyboardType: TextInputType.phone,
                    decoration: _deco('Teléfono', Icons.phone_outlined),
                    validator: (v) =>
                        soloDigitos(v ?? '').length < 10 ? 'Teléfono no válido' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _correo,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _deco('Correo', Icons.alternate_email),
                    validator: (v) =>
                        Sesion.correoValido(v ?? '') ? null : 'Correo no válido',
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _cedula,
                    decoration: _deco(
                      cfg.pideCedula || cfg.pideMayorEdad ? 'Cédula' : 'Cédula (opcional)',
                      Icons.badge_outlined,
                    ),
                  ),
                  if (u.fechaNacimiento != null) ...[
                    const SizedBox(height: 14),
                    InputDecorator(
                      decoration: _deco('Fecha de nacimiento', Icons.cake_outlined,
                          ayuda: u.edad == null ? null : '${u.edad} años'),
                      child: Text(fechaCorta(u.fechaNacimiento!)),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                    onPressed: _guardar,
                    child: const Text('Guardar cambios'),
                  ),
                ],
              ),
            ),
    );
  }
}

// =====================================================================
// Direcciones
// =====================================================================
class PantallaDirecciones extends StatelessWidget {
  const PantallaDirecciones({super.key});

  Future<void> _editar(BuildContext context, [Direccion? d]) async {
    final etiqueta = TextEditingController(text: d?.etiqueta ?? 'Casa');
    final detalle = TextEditingController(text: d?.detalle);
    final referencia = TextEditingController(text: d?.referencia);
    final form = GlobalKey<FormState>();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 0, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(d == null ? 'Nueva dirección' : 'Editar dirección',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                children: [
                  for (final e in const ['Casa', 'Trabajo', 'Otra'])
                    ActionChip(
                      label: Text(e),
                      onPressed: () => etiqueta.text = e,
                    ),
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: etiqueta,
                decoration: _deco('Nombre (Casa, Trabajo…)', Icons.label_outline),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Ponle un nombre' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: detalle,
                maxLines: 2,
                minLines: 1,
                decoration: _deco('Dirección', Icons.location_on_outlined),
                validator: (v) => (v == null || v.trim().length < 5)
                    ? 'Escribe la dirección completa'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: referencia,
                decoration: _deco('Punto de referencia (opcional)', Icons.flag_outlined),
              ),
              const SizedBox(height: 18),
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                onPressed: () {
                  if (form.currentState?.validate() ?? false) Navigator.pop(ctx, true);
                },
                child: const Text('Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
    if (ok == true) {
      Sesion.instancia.guardarDireccion(
        existente: d,
        etiqueta: etiqueta.text,
        detalle: detalle.text,
        referencia: referencia.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = Sesion.instancia;
    return AnimatedBuilder(
      animation: s,
      builder: (context, _) {
        final lista = s.usuario?.direcciones ?? const <Direccion>[];
        return Scaffold(
          appBar: AppBar(title: const Text('Mis direcciones')),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _editar(context),
            icon: const Icon(Icons.add_location_alt_outlined),
            label: const Text('Agregar'),
          ),
          body: lista.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'Aún no tienes direcciones guardadas.\n'
                      'Agrega una para pedir más rápido.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                  itemCount: lista.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final d = lista[i];
                    final principal = i == 0;
                    return Card(
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        contentPadding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
                        leading: Icon(
                          d.etiqueta.toLowerCase().contains('trabajo')
                              ? Icons.work_outline
                              : Icons.home_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: Row(
                          children: [
                            Flexible(
                              child: Text(d.etiqueta,
                                  style: const TextStyle(fontWeight: FontWeight.w800)),
                            ),
                            if (principal) ...[
                              const SizedBox(width: 8),
                              const Chip(
                                label: Text('Principal'),
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ],
                          ],
                        ),
                        subtitle: Text(d.completa),
                        trailing: PopupMenuButton<String>(
                          onSelected: (op) {
                            if (op == 'editar') _editar(context, d);
                            if (op == 'principal') s.marcarPrincipal(d);
                            if (op == 'eliminar') s.eliminarDireccion(d);
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(value: 'editar', child: Text('Editar')),
                            if (!principal)
                              const PopupMenuItem(
                                  value: 'principal', child: Text('Usar como principal')),
                            const PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}

// =====================================================================
// Seguridad
// =====================================================================
class PantallaSeguridad extends StatefulWidget {
  const PantallaSeguridad({super.key});

  @override
  State<PantallaSeguridad> createState() => _PantallaSeguridadState();
}

class _PantallaSeguridadState extends State<PantallaSeguridad> {
  final _form = GlobalKey<FormState>();
  final _actual = TextEditingController();
  final _nueva = TextEditingController();
  final _repetir = TextEditingController();
  bool _ver = false;

  @override
  void dispose() {
    _actual.dispose();
    _nueva.dispose();
    _repetir.dispose();
    super.dispose();
  }

  void _cambiar() {
    if (!(_form.currentState?.validate() ?? false)) return;
    final error = Sesion.instancia.cambiarClave(_actual.text, _nueva.text);
    if (error != null) {
      _aviso(context, error);
      return;
    }
    _actual.clear();
    _nueva.clear();
    _repetir.clear();
    FocusScope.of(context).unfocus();
    _aviso(context, 'Contraseña actualizada');
  }

  Future<void> _eliminarCuenta() async {
    final clave = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded),
        title: const Text('Eliminar mi cuenta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Se borrarán tus datos, direcciones y puntos. '
                'Esta acción no se puede deshacer.'),
            const SizedBox(height: 14),
            TextField(
              controller: clave,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirma con tu contraseña',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error,
                foregroundColor: Theme.of(ctx).colorScheme.onError),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    final texto = clave.text;
    clave.dispose();
    if (ok != true || !mounted) return;
    final s = Sesion.instancia;
    final usuario = s.usuario;
    if (usuario == null) return;
    if (!usuario.claveEs(texto)) {
      _aviso(context, 'Contraseña incorrecta.');
      return;
    }
    Navigator.of(context).popUntil((r) => r.isFirst);
    final error = s.eliminarMiCuenta(texto);
    if (error != null && mounted) _aviso(context, error);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final u = Sesion.instancia.usuario;
    return Scaffold(
      appBar: AppBar(title: const Text('Seguridad')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const Text('Cambiar contraseña',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            TextFormField(
              controller: _actual,
              obscureText: !_ver,
              decoration: _deco('Contraseña actual', Icons.lock_outline),
              validator: (v) => (v == null || v.isEmpty) ? 'Requerida' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nueva,
              obscureText: !_ver,
              decoration: _deco('Nueva contraseña', Icons.lock_reset,
                  ayuda: 'Mínimo 6 caracteres'),
              validator: (v) =>
                  (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _repetir,
              obscureText: !_ver,
              decoration: _deco('Repite la nueva contraseña', Icons.lock_reset),
              validator: (v) => v != _nueva.text ? 'No coinciden' : null,
            ),
            CheckboxListTile(
              value: _ver,
              onChanged: (v) => setState(() => _ver = v ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('Mostrar contraseñas'),
            ),
            const SizedBox(height: 6),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              onPressed: _cambiar,
              child: const Text('Actualizar contraseña'),
            ),
            const SizedBox(height: 28),
            if (u != null && u.ultimoAcceso != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.devices_outlined),
                title: const Text('Sesión activa en este teléfono'),
                subtitle: Text('Desde ${fechaCorta(u.ultimoAcceso!)}'),
              ),
            const Divider(height: 32),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: cs.error,
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: _eliminarCuenta,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Eliminar mi cuenta'),
            ),
          ],
        ),
      ),
    );
  }
}
