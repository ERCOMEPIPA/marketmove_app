// This is a basic Flutter widget test.
import 'package:flutter_test/flutter_test.dart';

import 'package:marketmove_app/main.dart';
import 'package:marketmove_app/src/shared/services/theme_service.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    final themeService = ThemeService();
    await tester.pumpWidget(MarketMoveApp(themeService: themeService));

    // Verificar que se carga la pantalla de login
    expect(find.text('MarketMove'), findsOneWidget);
  });
}
