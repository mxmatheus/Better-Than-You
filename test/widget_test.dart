import 'package:flutter_test/flutter_test.dart';
import 'package:better_than_you/domain/auth/auth_state.dart';
import 'package:better_than_you/domain/auth/auth_user.dart';
import 'package:better_than_you/domain/auth/local_auth_repository.dart';
import 'package:better_than_you/domain/profile/player_profile.dart';
import 'package:better_than_you/main.dart';

void main() {
  testWidgets('App renders Home screen with brand text and ranked card', (
    WidgetTester tester,
  ) async {
    final repo = LocalAuthRepository(
      initialState: const AuthAuthenticated(
        user: AuthUser(id: 'user_1', email: 'player@example.com'),
        profile: PlayerProfile(id: 'user_1', username: 'CHALLENGER', mmr: 1000),
      ),
    );

    await tester.pumpWidget(BetterThanYouApp(authRepository: repo));
    await tester.pumpAndSettle();

    expect(find.text('BETTER\nTHAN YOU'), findsOneWidget);
    expect(find.text('PROVE IT.'), findsOneWidget);
    expect(find.text('RANKED 1V1'), findsOneWidget);
    expect(find.text('DAILY CHALLENGE'), findsWidgets);
  });
}
