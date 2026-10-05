import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_finances/app.dart';

void main() {
  testWidgets('GestionFinancesApp builds smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: GestionFinancesApp(),
      ),
    );

    // Initial frame renders successfully
    expect(find.byType(GestionFinancesApp), findsOneWidget);
  });
}
