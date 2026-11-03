import 'package:flutter/material.dart';

import 'modelos.dart';
import 'sesion.dart';

/// Pantalla de inicio de sesión / registro / invitado.
///
/// Se usa como pantalla inicial (dentro de [CuentasRaiz]) o se abre con
/// `Navigator.push` desde el perfil de un invitado: al entrar, se cierra sola.
class PantallaAcceso extends StatefulWidget {
  const PantallaAcceso({super.key, this.empezarEnRegistro = false});

  final bool empezarEnRegistro;

  @override
  State<PantallaAcceso> createState() => _PantallaAccesoState();
}

class _PantallaAccesoState extends State<PantallaAcceso> {
  late bool _registro = widget.empezarEnRegistro;
  final _formLogin = GlobalKey<FormState>();
  final _formRegistro = GlobalKey<FormState>();

  // Login
  final _usuario = TextEditingController();
  final _clave = TextEditingController();

  // Registro
  final _nombre = TextEditingController();
  final _correo = TextEditingController();
  final _telefono = TextEditingController();
  final _cedula = TextEditingController();
  final _direccion = TextEditingController();
  final _claveNueva = TextEditingController();
  final _claveRepetida = TextEditingController();
  DateTime? _nacimiento;
  bool _acepto = false;

  bool _verClave = false;
  bool _cargando = false;
  String? _error;

  Sesion get _s => Sesion.instancia;

  @override
  void dispose() {
    for (final c in [
      _usuario,
      _clave,
      _nombre,
      _correo,
      _telefono,
      _cedula,
      _direccion,
      _claveNueva,
      _claveRepetida,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _cerrarSiEsRuta() {
    final nav = Navigator.of(context);
    if (nav.canPop()) nav.pop();
  }

  Future<void> _entrar() async {
    setState(() => _error = null);
    if (!(_formLogin.currentState?.validate() ?? false)) return;
    setState(() => _cargando = true);
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    final error = _s.iniciarSesion(_usuario.text, _clave.text);
    setState(() {
      _cargando = false;
      _error = error;
    });
    if (error == null) _cerrarSiEsRuta();
  }

  Future<void> _crearCuenta() async {
    setState(() => _error = null);
    if (!(_formRegistro.currentState?.validate() ?? false)) return;
    if (!_acepto) {
      setState(() => _error = 'Debes aceptar los términos para continuar.');
      return;
    }
    setState(() => _cargando = true);
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    final error = _s.registrar(
      nombre: _nombre.text,
      correo: _correo.text,
      telefono: _telefono.text,
      clave: _claveNueva.text,
      cedula: _cedula.text,
      fechaNacimiento: _nacimiento,
      direccion: _direccion.text,
    );
    setState(() {
      _cargando = false;
      _error = error;
    });
    if (error == null) {
      final m = ScaffoldMessenger.maybeOf(context);
      _cerrarSiEsRuta();
      m?.showSnackBar(SnackBar(
        content: Text('¡Bienvenido! Te regalamos 50 ${_s.config.programaPuntos}.'),
      ));
    }
  }

  void _invitado() {
    _s.entrarComoInvitado();
    _cerrarSiEsRuta();
  }

  Future<void> _olvideClave() async {
    final ctrl = TextEditingController(text: _usuario.text);
    final dato = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Recuperar contraseña'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Escribe el correo o teléfono de tu cuenta y te '
                'enviaremos un enlace para crear una contraseña nueva.'),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Correo o teléfono',
                prefixIcon: Icon(Icons.alternate_email),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text),
              child: const Text('Enviar enlace')),
        ],
      ),
    );
    ctrl.dispose();
    if (dato == null || dato.trim().isEmpty || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_s.recuperarClave(dato))),
    );
  }

  Future<void> _elegirNacimiento() async {
    final hoy = DateTime.now();
    final f = await showDatePicker(
      context: context,
      initialDate: _nacimiento ?? DateTime(hoy.year - 25, hoy.month, hoy.day),
      firstDate: DateTime(hoy.year - 100),
      lastDate: hoy,
      helpText: 'Fecha de nacimiento',
    );
    if (f != null) setState(() => _nacimiento = f);
  }

  void _usarCuentaDemo(String correo, String clave) {
    setState(() {
      _registro = false;
      _usuario.text = correo;
      _clave.text = clave;
      _error = null;
    });
  }

  // ---------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------
  InputDecoration _deco(String label, IconData icono, {String? ayuda, Widget? sufijo}) {
    return InputDecoration(
      labelText: label,
      helperText: ayuda,
      prefixIcon: Icon(icono),
      suffixIcon: sufijo,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final cs = tema.colorScheme;
    final cfg = _s.config;
    final esRuta = Navigator.of(context).canPop();

    return Scaffold(
      appBar: esRuta ? AppBar() : null,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: cs.primary,
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: Icon(cfg.icono, size: 46, color: cs.onPrimary),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    cfg.nombreNegocio,
                    textAlign: TextAlign.center,
                    style: tema.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  if (cfg.eslogan.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(cfg.eslogan,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: cs.onSurfaceVariant)),
                  ],
                  const SizedBox(height: 24),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                          value: false,
                          label: Text('Iniciar sesión'),
                          icon: Icon(Icons.login)),
                      ButtonSegment(
                          value: true,
                          label: Text('Crear cuenta'),
                          icon: Icon(Icons.person_add_alt)),
                    ],
                    selected: {_registro},
                    showSelectedIcon: false,
                    onSelectionChanged: (v) => setState(() {
                      _registro = v.first;
                      _error = null;
                    }),
                  ),
                  const SizedBox(height: 20),
                  if (_registro) _formularioRegistro(cfg) else _formularioLogin(),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cs.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: cs.onErrorContainer),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(_error!,
                                style: TextStyle(color: cs.onErrorContainer)),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 54,
                    child: FilledButton(
                      onPressed: _cargando
                          ? null
                          : (_registro ? _crearCuenta : _entrar),
                      child: _cargando
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.5))
                          : Text(_registro ? 'Crear mi cuenta' : 'Entrar',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _cargando ? null : _invitado,
                      icon: const Icon(Icons.storefront_outlined),
                      label: const Text('Ver la tienda como invitado'),
                    ),
                  ),
                  const SizedBox(height: 22),
                  _CuentasDemo(onUsar: _usarCuentaDemo),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _formularioLogin() {
    return Form(
      key: _formLogin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _usuario,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email, AutofillHints.telephoneNumber],
            decoration: _deco('Correo o teléfono', Icons.alternate_email),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Escribe tu correo o teléfono' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _clave,
            obscureText: !_verClave,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            onFieldSubmitted: (_) => _entrar(),
            decoration: _deco(
              'Contraseña',
              Icons.lock_outline,
              sufijo: IconButton(
                tooltip: _verClave ? 'Ocultar' : 'Mostrar',
                icon: Icon(_verClave ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _verClave = !_verClave),
              ),
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'Escribe tu contraseña' : null,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _olvideClave,
              child: const Text('¿Olvidaste tu contraseña?'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _formularioRegistro(CuentasConfig cfg) {
    final cs = Theme.of(context).colorScheme;
    return Form(
      key: _formRegistro,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _nombre,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: _deco('Nombre y apellido', Icons.person_outline),
            validator: (v) =>
                (v == null || v.trim().length < 3) ? 'Escribe tu nombre y apellido' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _telefono,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            decoration: _deco('Teléfono', Icons.phone_outlined, ayuda: 'Ej. 0414-123-4567'),
            validator: (v) =>
                soloDigitos(v ?? '').length < 10 ? 'Teléfono no válido' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _correo,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: _deco('Correo electrónico', Icons.alternate_email),
            validator: (v) =>
                Sesion.correoValido(v ?? '') ? null : 'Correo no válido',
          ),
          if (cfg.pideCedula || cfg.pideMayorEdad) ...[
            const SizedBox(height: 14),
            TextFormField(
              controller: _cedula,
              textInputAction: TextInputAction.next,
              decoration: _deco('Cédula', Icons.badge_outlined, ayuda: 'Ej. V-12345678'),
              validator: (v) => (v == null || soloDigitos(v).length < 6)
                  ? 'Escribe tu cédula'
                  : null,
            ),
          ],
          if (cfg.pideMayorEdad) ...[
            const SizedBox(height: 14),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _elegirNacimiento,
              child: InputDecorator(
                decoration: _deco(
                  'Fecha de nacimiento',
                  Icons.cake_outlined,
                  ayuda: 'Solo mayores de 18 años',
                ),
                child: Text(
                  _nacimiento == null ? 'Toca para elegir' : fechaCorta(_nacimiento!),
                  style: TextStyle(
                      color: _nacimiento == null ? cs.onSurfaceVariant : null),
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          TextFormField(
            controller: _direccion,
            textInputAction: TextInputAction.next,
            maxLines: 2,
            minLines: 1,
            decoration: _deco('Dirección de entrega (opcional)', Icons.location_on_outlined),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _claveNueva,
            obscureText: !_verClave,
            textInputAction: TextInputAction.next,
            decoration: _deco(
              'Contraseña',
              Icons.lock_outline,
              ayuda: 'Mínimo 6 caracteres',
              sufijo: IconButton(
                tooltip: _verClave ? 'Ocultar' : 'Mostrar',
                icon: Icon(_verClave ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _verClave = !_verClave),
              ),
            ),
            validator: (v) =>
                (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _claveRepetida,
            obscureText: !_verClave,
            decoration: _deco('Repite la contraseña', Icons.lock_reset),
            validator: (v) =>
                v != _claveNueva.text ? 'Las contraseñas no coinciden' : null,
          ),
          const SizedBox(height: 6),
          CheckboxListTile(
            value: _acepto,
            onChanged: (v) => setState(() => _acepto = v ?? false),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(
              cfg.pideMayorEdad
                  ? 'Confirmo que soy mayor de 18 años y acepto los términos y la política de privacidad.'
                  : 'Acepto los términos de uso y la política de privacidad.',
              style: const TextStyle(fontSize: 13.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// Atajos para la presentación: llenan el formulario con una cuenta demo.
class _CuentasDemo extends StatelessWidget {
  const _CuentasDemo({required this.onUsar});

  final void Function(String correo, String clave) onUsar;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.primary.withAlpha(22),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              const Text('Cuentas de demostración',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 4),
          Text('Toca una para llenar el formulario.',
              style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                avatar: const Icon(Icons.person_outline, size: 18),
                label: const Text('Cliente'),
                onPressed: () => onUsar('cliente@demo.com', 'cliente123'),
              ),
              ActionChip(
                avatar: const Icon(Icons.badge_outlined, size: 18),
                label: const Text('Empleado'),
                onPressed: () => onUsar('empleado@demo.com', 'empleado123'),
              ),
              ActionChip(
                avatar: const Icon(Icons.admin_panel_settings_outlined, size: 18),
                label: const Text('Administrador'),
                onPressed: () => onUsar('admin@demo.com', 'admin123'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
