// This is a basic Flutter widget test.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:marketmove_app/main.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MarketMoveApp());

    // Verificar que se carga la pantalla de login
    expect(find.text('MarketMove'), findsOneWidget);
  });
}
