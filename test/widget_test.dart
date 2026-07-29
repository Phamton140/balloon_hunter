// test/widget_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:balloon_hunter/main.dart';
import 'package:balloon_hunter/balloon_hunter_game.dart';

void main() {
  testWidgets('BalloonHunterApp smoke test', (WidgetTester tester) async {
    final game = BalloonHunterGame();
    await tester.pumpWidget(BalloonHunterApp(game: game));
    // Verifica que la app arranca sin errores
    expect(find.byType(BalloonHunterApp), findsOneWidget);
  });
}
