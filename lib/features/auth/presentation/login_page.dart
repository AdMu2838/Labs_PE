import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../shared/widgets/ui.dart';
import '../domain/session.dart';
import 'auth_controller.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key, this.passwordRecovery = false});
  final bool passwordRecovery;
  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}
class _LoginPageState extends ConsumerState<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController(), _password = TextEditingController(), _name = TextEditingController(), _cui = TextEditingController();
  bool _register = false, _busy = false, _obscure = true;
  String? _error, _message;
  @override
  void dispose() { _email.dispose(); _password.dispose(); _name.dispose(); _cui.dispose(); super.dispose(); }
  Future<void> _google() async {
    setState(() { _busy = true; _error = null; _message = null; });
    try {
      await ref.read(authRepositoryProvider)!.signInWithGoogle();
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().contains('not enabled')
          ? 'El acceso con Google todavía no está habilitado en Supabase.' : errorLabel(e));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
  Future<void> _submit({bool reset = false}) async {
    if (reset ? !_email.text.contains('@') : !_form.currentState!.validate()) return;
    setState(() { _busy = true; _error = null; _message = null; });
    try {
      final repo = ref.read(authRepositoryProvider)!;
      if (widget.passwordRecovery) {
        await repo.updatePassword(_password.text);
        _message = 'Contraseña actualizada. Puedes volver a ingresar.';
      } else if (reset) {
        await repo.resetPassword(_email.text.trim()); _message = 'Revisa tu correo para restablecer tu contraseña.';
      } else if (_register) {
        await repo.signUp(_email.text.trim(), _password.text, _name.text.trim(), _cui.text.trim());
        _message = 'Cuenta creada. Revisa tu correo para confirmar el registro.';
      } else { await repo.signIn(_email.text.trim(), _password.text); }
    } catch (e) { _error = errorLabel(e); }
    finally { if (mounted) setState(() => _busy = false); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(body: LayoutBuilder(builder: (context, constraints) {
     final wide = constraints.maxWidth >= 900 && constraints.maxHeight >= 700;
    final form = Center(child: SingleChildScrollView(padding: EdgeInsets.all(wide ? 48 : 24), child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (!wide) ...[const SizedBox(width: 260, child: Brand()), const SizedBox(height: 42)],
        const StatusChip('ESCUELA PROFESIONAL · EPIS'), const SizedBox(height: 22),
        Text(widget.passwordRecovery ? 'Nueva contraseña' : _register ? 'Únete a UNSA · LAB' : 'Bienvenido, agustino', style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 12), const Text('Organiza tus laboratorios y construye tu próximo semestre.', style: TextStyle(color: UnsaColors.muted, height: 1.6)),
        const SizedBox(height: 30),
        if (ref.watch(authRepositoryProvider) == null) ...[
          const Panel(child: Text('Modo demostración\nExplora la plataforma con datos ficticios. Para usar cuentas reales, configura las credenciales de Supabase.')),
          const SizedBox(height: 20),
          for (final role in AppRole.values) Padding(padding: const EdgeInsets.only(bottom: 12), child: SizedBox(width: double.infinity,
            child: FilledButton.tonalIcon(onPressed: () => ref.read(demoSessionProvider.notifier).enter(role), icon: Icon(role == AppRole.student ? Icons.school_outlined : role == AppRole.admin ? Icons.admin_panel_settings_outlined : Icons.person_outline),
              label: Text('Explorar como ${presentationLabel(role.name).toLowerCase()}')))),
         ] else Form(key: _form, child: Column(children: [
          if (!widget.passwordRecovery) ...[
            SizedBox(width: double.infinity, child: OutlinedButton.icon(
              onPressed: _busy ? null : _google,
              icon: const Text('G', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700, color: Color(0xFF4285F4))),
              label: const Text('Continuar con Google'),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18)),
            )),
            const SizedBox(height: 18),
            const Row(children: [Expanded(child: Divider()), Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('o con tu correo')), Expanded(child: Divider())]),
            const SizedBox(height: 18),
          ],
          if (_register) ...[
            TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Nombres y apellidos'), validator: (v) => (v ?? '').trim().length < 3 ? 'Ingresa tu nombre completo' : null), const SizedBox(height: 16),
            TextFormField(controller: _cui, decoration: const InputDecoration(labelText: 'CUI'), validator: (v) => !RegExp(r'^\d{8}$').hasMatch(v ?? '') ? 'Ingresa un CUI de 8 dígitos' : null), const SizedBox(height: 16),
          ],
          if (!widget.passwordRecovery) ...[
            TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Correo electrónico', prefixIcon: Icon(Icons.mail_outline)),
              validator: (v) => !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v ?? '') ? 'Ingresa un correo válido' : null), const SizedBox(height: 16),
          ],
          TextFormField(controller: _password, obscureText: _obscure, onFieldSubmitted: (_) { if (!_busy) _submit(); },
            decoration: InputDecoration(labelText: 'Contraseña', prefixIcon: const Icon(Icons.lock_outline), suffixIcon: IconButton(tooltip: 'Mostrar u ocultar contraseña', onPressed: () => setState(() => _obscure = !_obscure), icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined))),
            validator: (v) => (v ?? '').length < 8 ? 'Usa al menos 8 caracteres' : null),
          if (_error != null) Padding(padding: const EdgeInsets.only(top: 16), child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
          if (_message != null) Padding(padding: const EdgeInsets.only(top: 16), child: Text(_message!)),
          const SizedBox(height: 24), SizedBox(width: double.infinity, child: FilledButton(onPressed: _busy ? null : _submit,
            child: Text(_busy ? 'Procesando…' : widget.passwordRecovery ? 'Guardar contraseña' : _register ? 'Crear cuenta' : 'Ingresar a la plataforma'))),
          if (!widget.passwordRecovery) ...[
            TextButton(onPressed: _busy ? null : () => _submit(reset: true), child: const Text('¿Olvidaste tu contraseña?')),
            TextButton(onPressed: _busy ? null : () => setState(() { _register = !_register; _error = null; }), child: Text(_register ? 'Ya tengo una cuenta' : 'Crear una cuenta de estudiante')),
          ] else TextButton(onPressed: () { ref.invalidate(sessionProvider); context.go('/'); }, child: const Text('Volver a la plataforma')),
        ])),
        const SizedBox(height: 32), const Text('Universidad Nacional de San Agustín de Arequipa\nFacultad de Ingeniería de Producción y Servicios', style: TextStyle(color: UnsaColors.muted, fontSize: 12, height: 1.7)),
      ]))));
    return Row(children: [if (wide) Expanded(child: Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [UnsaColors.garnet, UnsaColors.darkGarnet])),
      child: Padding(padding: const EdgeInsets.all(56), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const SizedBox(width: 280, child: Brand(light: true)),
        const Spacer(), const Icon(Icons.science_outlined, size: 92, color: UnsaColors.gold), const SizedBox(height: 30),
        const Text('Menos filas.\nMás posibilidades.', style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w800, height: 1.15)), const SizedBox(height: 24),
        const Text('Tu espacio para elegir, organizar y matricularte\nen los laboratorios de Ingeniería de Sistemas.', style: TextStyle(color: Colors.white70, height: 1.8, fontSize: 16)),
        const Spacer(), const Text('CIENCIA · INNOVACIÓN · COMUNIDAD', style: TextStyle(color: UnsaColors.gold, letterSpacing: 2, fontSize: 11)),
      ])))), Expanded(child: form)]);
  }));
}
