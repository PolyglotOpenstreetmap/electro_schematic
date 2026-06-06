import 'package:flutter_test/flutter_test.dart';
import 'package:schematic_designer_example/main.dart';

void main() {
  testWidgets('designer example smoke test', (tester) async {
    await tester.pumpWidget(const DesignerExampleApp());
    expect(find.text('Schematic Designer — 3-phase motor symbol'), findsOneWidget);
  });
}
