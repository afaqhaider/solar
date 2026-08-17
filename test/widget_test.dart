import 'package:flutter_test/flutter_test.dart';
import 'package:solar/main.dart';
import 'package:provider/provider.dart';
import 'package:solar/logic/solar_provider.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => SolarProvider(),
        child: const SolarCalculatorApp(),
      ),
    );

    expect(find.text('Solar Calculator'), findsOneWidget);
    expect(find.text('1. ELECTRICAL LOAD'), findsOneWidget);
  });
}
