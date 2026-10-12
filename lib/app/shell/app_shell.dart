import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/environment.dart';
import '../../core/data/providers.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../shared/widgets/ui.dart';
import '../theme/app_theme.dart';
import 'role_workspace.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.path, required this.child});
  final String path;
  final Widget child;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    if (session.isLoading) { return const Scaffold(body: Center(child: CircularProgressIndicator())); }
    if (session.hasError) { return Scaffold(body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('No se pudo cargar tu perfil. Verifica las migraciones y la conexión.'),
      TextButton(onPressed: () => ref.invalidate(sessionProvider), child: const Text('Reintentar')),
      TextButton(onPressed: () => logout(ref), child: const Text('Cerrar sesión')),
    ]))); }
    final user = session.asData?.value;
    if (user == null) return const SizedBox.shrink();
    ref.watch(realtimeProvider);
    final workspace = RoleWorkspace.forRole(user.role);
    final items = <WorkspaceLink>[
      ('/', 'Inicio', Icons.grid_view_rounded),
      ...workspace.links,
      ('/notifications', 'Notificaciones', Icons.notifications_none_rounded),
      ('/profile', 'Mi perfil', Icons.person_outline),
    ];
    Widget menu({bool drawer = false}) => Material(color: UnsaColors.darkGarnet, child: SafeArea(child: Column(children: [
      const Padding(padding: EdgeInsets.fromLTRB(24, 30, 20, 30), child: Brand(light: true)),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Align(alignment: Alignment.centerLeft, child: Text(workspace.title.toUpperCase(), style: const TextStyle(color: UnsaColors.gold, fontSize: 10, letterSpacing: 2)))),
      const SizedBox(height: 12), Expanded(child: ListView(padding: const EdgeInsets.symmetric(horizontal: 12), children: [
        for (final item in items) ...[
          if (item.$1 == '/notifications') const Padding(padding: EdgeInsets.fromLTRB(12, 18, 12, 12), child: Text('MI CUENTA', style: TextStyle(color: Colors.white60, fontSize: 10, letterSpacing: 2))),
          Padding(padding: const EdgeInsets.only(bottom: 5), child: ListTile(
          selected: path == item.$1, selectedTileColor: workspace.color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          leading: Icon(item.$3, size: 21, color: path == item.$1 ? UnsaColors.gold : Colors.white60),
          title: Text(item.$2, style: TextStyle(color: path == item.$1 ? Colors.white : Colors.white70, fontSize: 13)),
          onTap: () { if (drawer) Navigator.pop(context); context.go(item.$1); })),
        ],
      ])),
      Padding(padding: const EdgeInsets.all(16), child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .06), borderRadius: BorderRadius.circular(12)),
        child: const Text('Universidad Nacional de\nSan Agustín de Arequipa', style: TextStyle(color: Colors.white60, fontSize: 11, height: 1.7)))),
    ])));
    return LayoutBuilder(builder: (context, constraints) {
      final desktop = constraints.maxWidth >= 1100;
      return Scaffold(
        drawer: desktop ? null : Drawer(child: menu(drawer: true)),
        body: Row(children: [if (desktop) SizedBox(width: 246, child: menu()), Expanded(child: Column(children: [
          Material(color: Colors.white, child: SafeArea(bottom: false, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12), child: Row(children: [
            if (!desktop) Builder(builder: (context) => IconButton(tooltip: 'Abrir menú', onPressed: () => Scaffold.of(context).openDrawer(), icon: const Icon(Icons.menu))),
            Expanded(child: Text(workspace.title, style: TextStyle(fontWeight: FontWeight.w600, color: workspace.color))),
            IconButton(tooltip: 'Actualizar información', onPressed: () => ref.read(revisionProvider.notifier).refresh(), icon: const Icon(Icons.refresh, size: 20)),
            IconButton(tooltip: 'Notificaciones', onPressed: () => context.go('/notifications'), icon: const Icon(Icons.notifications_none)),
            if (constraints.maxWidth > 600) ...[const SizedBox(width: 12), Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(user.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)), Text(user.roleLabel, style: const TextStyle(fontSize: 11, color: UnsaColors.muted))]), const SizedBox(width: 12)],
            PopupMenuButton<String>(tooltip: 'Cuenta', onSelected: (v) async { if (v == 'logout') { await logout(ref); } else if (context.mounted) { context.go('/profile'); } },
              itemBuilder: (_) => [const PopupMenuItem(value: 'profile', child: Text('Mi perfil')), const PopupMenuItem(value: 'logout', child: Text('Cerrar sesión'))],
              child: CircleAvatar(backgroundColor: const Color(0xFFF2E7EB), foregroundColor: UnsaColors.garnet, radius: 19, child: Text(user.name.isEmpty ? 'U' : user.name[0]))),
          ])))),
          if (!Environment.configured) Container(width: double.infinity, color: const Color(0xFFFFF3DC), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6), child: const Text('DEMOSTRACIÓN · Datos ficticios, cambios temporales', style: TextStyle(fontSize: 11, color: Color(0xFF805C13)))),
          Expanded(child: child),
        ]))]),
      );
    });
  }
}
