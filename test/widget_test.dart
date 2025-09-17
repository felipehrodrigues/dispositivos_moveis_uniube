import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gerenciador_tarefas/main.dart';

void main() {
  testWidgets('Smoke test MeuApp', (WidgetTester tester) async {
    // Build our app
    await tester.pumpWidget(const MeuApp());

    // Apenas exemplo: verifica se o widget inicial existe
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
