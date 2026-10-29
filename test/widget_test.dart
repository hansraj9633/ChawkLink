import 'package:flutter_test/flutter_test.dart';
import 'package:majdoor_setu/main.dart';

void main() {
  testWidgets('Majdoor Setu splash and get started screens load', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MajdoorSetuApp());

    expect(find.text('Majdoor Setu'), findsOneWidget);

    // Splash screen timer: 3 seconds
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to\nMajdoor Setu'), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}
