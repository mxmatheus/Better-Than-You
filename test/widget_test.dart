import 'package:flutter_test/flutter_test.dart';
import 'package:better_than_you/main.dart';

void main() {
  testWidgets('App renders Home screen with brand text and ranked card',
      (WidgetTester tester) async {
    await tester.pumpWidget(const BetterThanYouApp());

    expect(find.text('BETTER\nTHAN YOU'), findsOneWidget);
    expect(find.text('PROVE IT.'), findsOneWidget);
    expect(find.text('RANKED 1V1'), findsOneWidget);
    expect(find.text('DAILY CHALLENGE'), findsOneWidget);
  });
}
