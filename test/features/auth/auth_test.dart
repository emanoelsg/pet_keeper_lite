// test/features/auth_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_keeper_lite/features/auth/screens/login_screen.dart';
import 'package:pet_keeper_lite/features/auth/providers/auth_provider.dart';
import 'package:pet_keeper_lite/features/auth/services/auth_service.dart';

void main() {
  testWidgets('LoginScreen: login flow test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authServiceProvider.overrideWithValue(AuthService())],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Entrar'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'teste@teste.com');
    await tester.enterText(find.byType(TextFormField).last, '123456');

    await tester.tap(find.text('Entrar'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
