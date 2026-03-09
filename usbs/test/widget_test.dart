import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:usbs/features/auth/screens/login_screen.dart';

void main() {
  testWidgets('Login screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    expect(find.text('Login with Google'), findsOneWidget);
    expect(find.text('Login with Email'), findsOneWidget);
    expect(find.text('Continue as Guest'), findsOneWidget);
  });
}
