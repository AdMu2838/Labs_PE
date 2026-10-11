import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unsa_laboratorios/app/app.dart';
import 'package:unsa_laboratorios/core/data/demo_lab_repository.dart';
import 'package:unsa_laboratorios/core/data/providers.dart';
import 'package:unsa_laboratorios/features/auth/domain/auth_repository.dart';
import 'package:unsa_laboratorios/features/auth/domain/session.dart';
import 'package:unsa_laboratorios/features/auth/presentation/auth_controller.dart';

class FakeAuth implements AuthRepository {
  final events = StreamController<AppSession?>.broadcast();
  String? signedEmail;
  bool googleRequested = false;
  AppSession? session;
  @override
  Stream<AppSession?> get sessions => events.stream;
  @override
  Future<AppSession?> current() async => session;
  @override
  Future<void> signIn(String email, String password) async {
    signedEmail = email;
    session = const AppSession(id: 'demo', name: 'Alex Agustino', email: 'alex@unsa.edu.pe', role: AppRole.student, cui: '20250001');
    events.add(session);
  }
  @override
  Future<void> signInWithGoogle() async { googleRequested = true; }
  @override
  Future<void> signUp(String email, String password, String name, String cui) async {}
  @override
  Future<void> resetPassword(String email) async {}
  @override
  Future<void> updatePassword(String password) async {}
  @override
  Future<void> signOut() async { session = null; events.add(null); }
}

void main() {
  testWidgets('Cuenta OAuth sin CUI se dirige a completar perfil', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final auth = FakeAuth();
    auth.session = const AppSession(id: 'demo', name: 'Alex Agustino', email: 'alex@unsa.edu.pe', role: AppRole.student);
    final repository = DemoLabRepository();
    await repository.save('profiles', {'id': 'demo', 'cui': null});
    addTearDown(auth.events.close);
    await tester.pumpWidget(ProviderScope(overrides: [
      authRepositoryProvider.overrideWithValue(auth),
      labRepositoryProvider.overrideWithValue(repository),
    ], child: const LabApp()));
    await tester.pumpAndSettle();
    expect(find.text('Completa tu CUI'), findsOneWidget);
    final container = ProviderScope.containerOf(tester.element(find.byType(LabApp)));
    container.read(routerProvider).go('/catalog');
    await tester.pumpAndSettle();
    expect(find.text('Completa tu CUI'), findsOneWidget);
    await tester.ensureVisible(find.text('Editar datos personales'));
    await tester.tap(find.text('Editar datos personales'));
    await tester.pumpAndSettle();
    expect(find.text('CUI (8 dígitos)'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(1), '123');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('Ingresa un CUI de 8 dígitos'), findsOneWidget);
  });
  testWidgets('Login con credenciales y rutas administrativas protegidas', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final auth = FakeAuth();
    addTearDown(auth.events.close);
    await tester.pumpWidget(ProviderScope(overrides: [authRepositoryProvider.overrideWithValue(auth)], child: const LabApp()));
    await tester.pumpAndSettle();
    expect(find.text('Ingresar a la plataforma'), findsOneWidget);
    expect(find.text('Continuar con Google'), findsOneWidget);
    await tester.ensureVisible(find.text('Continuar con Google'));
    await tester.tap(find.text('Continuar con Google'));
    await tester.pumpAndSettle();
    expect(auth.googleRequested, isTrue);
    await tester.enterText(find.byType(TextFormField).at(0), 'alex@unsa.edu.pe');
    await tester.enterText(find.byType(TextFormField).at(1), 'password-test');
    await tester.ensureVisible(find.text('Ingresar a la plataforma'));
    await tester.tap(find.text('Ingresar a la plataforma'));
    await tester.pumpAndSettle();
    expect(auth.signedEmail, 'alex@unsa.edu.pe');
    expect(find.text('Hola, Alex 👋'), findsOneWidget);
    final container = ProviderScope.containerOf(tester.element(find.byType(LabApp)));
    container.read(routerProvider).go('/admin');
    await tester.pumpAndSettle();
    expect(find.text('Hola, Alex 👋'), findsOneWidget);
    await auth.signOut();
    await tester.pumpAndSettle();
    expect(find.text('Ingresar a la plataforma'), findsOneWidget);
  });
}
