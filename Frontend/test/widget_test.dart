import 'package:flutter_test/flutter_test.dart';
import 'package:klutchmaker_frontend/main.dart';

void main() {
  testWidgets('KlutchMaker app launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const KlutchMakerApp());
    expect(find.text('KlutchMaker'), findsNothing); // Just verifies no crash
  });
}
