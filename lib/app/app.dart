import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/auth_controller.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/dashboard/presentation/dashboard_page.dart';
import '../features/enrollment/presentation/catalog_page.dart';
import '../features/enrollment/presentation/enrollments_page.dart';
import '../features/curriculum/presentation/curriculum_page.dart';
import '../features/schedules/presentation/schedule_page.dart';
import '../features/requests/presentation/requests_page.dart';
import '../features/notifications/presentation/notifications_page.dart';
import '../features/profiles/presentation/profile_page.dart';
import '../features/administration/presentation/admin_page.dart';
import '../features/reports/presentation/reports_page.dart';
import 'theme/app_theme.dart';
import 'shell/app_shell.dart';
import '../shared/responsive/page_body.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  ref.listen(sessionProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);
  final router = GoRouter(initialLocation: '/', refreshListenable: refresh,
    redirect: (context, state) {
      final session = ref.read(sessionProvider);
      if (session.isLoading) return null;
      final user = session.asData?.value;
      if (state.uri.path == '/password') return null;
      if (user == null) return state.uri.path == '/login' ? null : '/login';
      if (user.role.name == 'student' && user.cui.isEmpty && state.uri.path != '/profile') return '/profile';
      if (state.uri.path == '/login') return '/';
      if (state.uri.path == '/admin' && !user.manages) return '/';
      if (state.uri.path == '/reports' && user.role.name == 'student') return '/';
      return null;
    }, routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
      GoRoute(path: '/password', builder: (_, _) => const LoginPage(passwordRecovery: true)),
      ShellRoute(builder: (_, state, child) => AppShell(path: state.uri.path, child: child), routes: [
        GoRoute(path: '/', builder: (_, _) => const PageBody(child: DashboardPage())),
        GoRoute(path: '/catalog', builder: (_, _) => const PageBody(child: CatalogPage())),
        GoRoute(path: '/enrollments', builder: (_, _) => const PageBody(child: EnrollmentsPage())),
        GoRoute(path: '/schedule', builder: (_, _) => const PageBody(child: SchedulePage())),
        GoRoute(path: '/curriculum', builder: (_, _) => const PageBody(child: CurriculumPage())),
        GoRoute(path: '/requests', builder: (_, _) => const PageBody(child: RequestsPage())),
        GoRoute(path: '/notifications', builder: (_, _) => const PageBody(child: NotificationsPage())),
        GoRoute(path: '/profile', builder: (_, _) => const PageBody(child: ProfilePage())),
        GoRoute(path: '/admin', builder: (_, _) => const PageBody(child: AdminPage())),
        GoRoute(path: '/reports', builder: (_, _) => const PageBody(child: ReportsPage())),
      ]),
    ], errorBuilder: (context, state) => Scaffold(body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Text('Página no encontrada'), TextButton(onPressed: () => context.go('/'), child: const Text('Volver al inicio'))]))));
  ref.onDispose(router.dispose);
  return router;
});

class LabApp extends ConsumerWidget {
  const LabApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    title: 'UNSA · LAB | Matrícula de laboratorios', debugShowCheckedModeBanner: false,
    theme: buildTheme(), routerConfig: ref.watch(routerProvider));
}
