import 'package:flutter/material.dart';

import 'modelos.dart';
import 'sesion.dart';

enum _Filtro { todos, clientes, personal, bloqueados }

/// Gestión de usuarios para el panel del negocio: clientes registrados,
/// personal (empleados y administradores), roles y bloqueos.
/// Los empleados pueden consultar; solo el administrador puede modificar.
class PantallaUsuarios extends StatefulWidget {
  const PantallaUsuarios({super.key});

  @override
  State<PantallaUsuarios> createState() => _PantallaUsuariosState();
}

class _PantallaUsuariosState extends State<PantallaUsuarios> {
  _Filtro _filtro = _Filtro.todos;
  String _busqueda = '';

  List<Usuario> _lista(Sesion s) {
    final q = _busqueda.trim().toLowerCase();
    final qDig = soloDigitos(q);
    final lista = s.usuarios.where((u) {
      final pasaFiltro = switch (_filtro) {
        _Filtro.todos => true,
        _Filtro.clientes => u.rol == Rol.cliente,
        _Filtro.personal => u.esPersonal,
        _Filtro.bloqueados => !u.activo,
      };
      if (!pasaFiltro) return false;
      if (q.isEmpty) return true;
      return u.nombre.toLowerCase().contains(q) ||
          u.correo.toLowerCase().contains(q) ||
          (qDig.length >= 3 && soloDigitos(u.telefono).contains(qDig));
    }).toList();
    lista.sort((a, b) {
      final r = b.rol.index.compareTo(a.rol.index);
      return r != 0 ? r : a.nombre.compareTo(b.nombre);
    });
    return lista;
  }

  @override
  Widget build(BuildContext context) {
    final s = Sesion.instancia;
    return AnimatedBuilder(
      animation: s,
      builder: (context, _) {
        final lista = _lista(s);
        return Scaffold(
          appBar: AppBar(title: const Text('Usuarios y clientes')),
          floatingActionButton: s.esAdmin
              ? FloatingActionButton.extended(
                  onPressed: () => _nuevoUsuario(context),
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Nuevo usuario'),
                )
              : null,
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              Row(
                children: [
                  _Indicador(
                      titulo: 'Clientes',
                      valor: '${s.clientes.length}',
                      icono: Icons.people_outline),
                  const SizedBox(width: 10),
                  _Indicador(
                      titulo: 'Nuevos del mes',
                      valor: '${s.nuevosEsteMes}',
                      icono: Icons.trending_up),
                  const SizedBox(width: 10),
                  _Indicador(
                      titulo: 'Personal',
                      valor: '${s.personal.length}',
                      icono: Icons.badge_outlined),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                onChanged: (v) => setState(() => _busqueda = v),
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre, correo o teléfono',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final f in _Filtro.values)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(_etiquetaFiltro(f, s)),
                          selected: _filtro == f,
                          onSelected: (_) => setState(() => _filtro = f),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              if (!s.esAdmin)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    'Modo consulta: solo un administrador puede crear, bloquear '
                    'o cambiar el rol de los usuarios.',
                    style: TextStyle(
                        fontSize: 12.5,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ),
              if (lista.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: Text('No hay usuarios con ese filtro.')),
                ),
              for (final u in lista)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    onTap: () => _detalle(context, u),
                    leading: CircleAvatar(
                      backgroundColor: u.activo
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).colorScheme.errorContainer,
                      child: Text(u.iniciales),
                    ),
                    title: Text(u.nombre,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          decoration: u.activo ? null : TextDecoration.lineThrough,
                        )),
                    subtitle: Text(
                      u.esPersonal
                          ? '${u.rol.etiqueta} · ${u.correo}'
                          : '${u.pedidos} pedidos · \$${u.gastado.toStringAsFixed(2)} · ${u.telefono}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Icon(
                      u.activo ? u.rol.icono : Icons.block,
                      color: u.activo
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _etiquetaFiltro(_Filtro f, Sesion s) {
    switch (f) {
      case _Filtro.todos:
        return 'Todos (${s.usuarios.length})';
      case _Filtro.clientes:
        return 'Clientes (${s.clientes.length})';
      case _Filtro.personal:
        return 'Personal (${s.personal.length})';
      case _Filtro.bloqueados:
        return 'Bloqueados (${s.bloqueados})';
    }
  }

  void _aviso(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _detalle(BuildContext context, Usuario u) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _DetalleUsuario(usuario: u, onAviso: _aviso),
    );
  }

  Future<void> _nuevoUsuario(BuildContext context) async {
    final nombre = TextEditingController();
    final correo = TextEditingController();
    final telefono = TextEditingController();
    final clave = TextEditingController(text: 'clave123');
    var rol = Rol.empleado;
    final form = GlobalKey<FormState>();

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 0, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Form(
            key: form,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Nuevo usuario',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 14),
                  SegmentedButton<Rol>(
                    segments: [
                      for (final r in Rol.values)
                        ButtonSegment(value: r, label: Text(r.etiqueta)),
                    ],
                    selected: {rol},
                    showSelectedIcon: false,
                    onSelectionChanged: (v) => setLocal(() => rol = v.first),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: nombre,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                        labelText: 'Nombre y apellido', border: OutlineInputBorder()),
                    validator: (v) =>
                        (v == null || v.trim().length < 3) ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: correo,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                        labelText: 'Correo', border: OutlineInputBorder()),
                    validator: (v) =>
                        Sesion.correoValido(v ?? '') ? null : 'Correo no válido',
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: telefono,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                        labelText: 'Teléfono', border: OutlineInputBorder()),
                    validator: (v) =>
                        soloDigitos(v ?? '').length < 10 ? 'Teléfono no válido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: clave,
                    decoration: const InputDecoration(
                        labelText: 'Contraseña inicial',
                        helperText: 'El usuario podrá cambiarla en Seguridad',
                        border: OutlineInputBorder()),
                    validator: (v) =>
                        (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
                  ),
                  const SizedBox(height: 18),
                  FilledButton(
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                    onPressed: () {
                      if (form.currentState?.validate() ?? false) {
                        Navigator.pop(ctx, true);
                      }
                    },
                    child: const Text('Crear usuario'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (ok != true) return;
    final error = Sesion.instancia.crearUsuario(
      nombre: nombre.text,
      correo: correo.text,
      telefono: telefono.text,
      clave: clave.text,
      rol: rol,
    );
    if (!mounted) return;
    _aviso(error ?? 'Usuario creado: ${correo.text.trim()} / ${clave.text}');
  }
}

class _DetalleUsuario extends StatelessWidget {
  const _DetalleUsuario({required this.usuario, required this.onAviso});

  final Usuario usuario;
  final void Function(String) onAviso;

  @override
  Widget build(BuildContext context) {
    final s = Sesion.instancia;
    final cs = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: s,
      builder: (context, _) {
        final u = usuario;
        final yo = u.id == s.usuario?.id;
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: cs.primaryContainer,
                      child: Text(u.iniciales,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(u.nombre + (yo ? ' (tú)' : ''),
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w800)),
                          Text(u.activo ? u.rol.etiqueta : '${u.rol.etiqueta} · Bloqueado',
                              style: TextStyle(
                                  color: u.activo ? cs.primary : cs.error,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _Dato(Icons.alternate_email, 'Correo', u.correo),
                _Dato(Icons.phone_outlined, 'Teléfono', u.telefono),
                if (u.cedula.isNotEmpty) _Dato(Icons.badge_outlined, 'Cédula', u.cedula),
                if (u.edad != null) _Dato(Icons.cake_outlined, 'Edad', '${u.edad} años'),
                _Dato(Icons.event_outlined, 'Registrado', fechaCorta(u.registrado)),
                if (u.ultimoAcceso != null)
                  _Dato(Icons.login, 'Último acceso', fechaCorta(u.ultimoAcceso!)),
                if (!u.esPersonal) ...[
                  _Dato(Icons.receipt_long_outlined, 'Pedidos',
                      '${u.pedidos} · \$${u.gastado.toStringAsFixed(2)} en compras'),
                  _Dato(Icons.workspace_premium_outlined, s.config.programaPuntos,
                      '${u.puntos}'),
                  for (final d in u.direcciones)
                    _Dato(Icons.location_on_outlined, d.etiqueta, d.completa),
                ],
                if (s.esAdmin) ...[
                  const SizedBox(height: 16),
                  const Text('Rol', style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  SegmentedButton<Rol>(
                    segments: [
                      for (final r in Rol.values)
                        ButtonSegment(value: r, label: Text(r.etiqueta)),
                    ],
                    selected: {u.rol},
                    showSelectedIcon: false,
                    onSelectionChanged: (v) {
                      final error = s.cambiarRol(u, v.first);
                      if (error != null) onAviso(error);
                    },
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      OutlinedButton.icon(
                        onPressed: yo
                            ? null
                            : () {
                                final error = s.alternarActivo(u);
                                if (error != null) onAviso(error);
                              },
                        icon: Icon(u.activo ? Icons.block : Icons.check_circle_outline),
                        label: Text(u.activo ? 'Bloquear' : 'Desbloquear'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          final temporal = s.restablecerClave(u);
                          if (temporal != null) {
                            onAviso('Contraseña temporal de ${u.primerNombre}: $temporal');
                          }
                        },
                        icon: const Icon(Icons.lock_reset),
                        label: const Text('Restablecer clave'),
                      ),
                      if (!yo)
                        TextButton.icon(
                          style: TextButton.styleFrom(foregroundColor: cs.error),
                          onPressed: () async {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Eliminar usuario'),
                                content: Text('¿Eliminar la cuenta de ${u.nombre}?'),
                                actions: [
                                  TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: const Text('Cancelar')),
                                  FilledButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('Eliminar')),
                                ],
                              ),
                            );
                            if (ok != true) return;
                            final error = s.eliminarUsuario(u);
                            if (error != null) {
                              onAviso(error);
                            } else if (context.mounted) {
                              Navigator.pop(context);
                              onAviso('Usuario eliminado');
                            }
                          },
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Eliminar'),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato(this.icono, this.titulo, this.valor);

  final IconData icono;
  final String titulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icono, size: 20),
      title: Text(titulo,
          style: TextStyle(
              fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      subtitle: Text(valor,
          style: TextStyle(
              fontSize: 15, color: Theme.of(context).colorScheme.onSurface)),
    );
  }
}

class _Indicador extends StatelessWidget {
  const _Indicador({required this.titulo, required this.valor, required this.icono});

  final String titulo;
  final String valor;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icono, color: cs.primary, size: 20),
              const SizedBox(height: 6),
              Text(valor,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              Text(titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}
