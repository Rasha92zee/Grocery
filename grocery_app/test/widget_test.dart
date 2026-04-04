import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:grocery_app/main.dart';
import 'package:grocery_app/theme_provider.dart';

void main() {
  testWidgets('App loads without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: const BerryBasketApp(),
      ),
    );

    expect(find.byType(BerryBasketApp), findsOneWidget);
  });
}