import 'package:flutter_test/flutter_test.dart';
import 'package:tap_tide/main.dart';

void main() {
  testWidgets('Tap Tide loads', (WidgetTester tester) async {
    await tester.pumpWidget(const TapTideApp());

    expect(find.text('Tap Tide'), findsOneWidget);
    expect(find.text('Start Game'), findsOneWidget);
  });
}