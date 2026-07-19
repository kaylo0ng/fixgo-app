import 'package:fixgo/app/fixgo_app.dart';
import 'package:fixgo/infrastructure/services/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

void main() {
  setUpAll(() {
    setupDependencies();
  });

  tearDownAll(() {
    GetIt.instance.reset();
  });

  testWidgets('shows FixGo home screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('es'),
        home: FixGoApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('FixGo'), findsOneWidget);
    expect(
      find.text('Servicios del hogar con técnicos confiables'),
      findsOneWidget,
    );
    expect(find.text('Publicar solicitud'), findsOneWidget);
    expect(find.text('Categorías principales'), findsOneWidget);
  });

  testWidgets('buttons open their destination screens', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('es'),
        home: FixGoApp(),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Publicar solicitud'));
    await tester.pumpAndSettle();

    expect(find.text('Publicar solicitud'), findsWidgets);
    expect(find.text('Describe el trabajo que necesitas'), findsOneWidget);
  });
}