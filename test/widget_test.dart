import 'package:flutter_test/flutter_test.dart';
import 'package:zulu_buttons/main.dart';

void main() {
  testWidgets('App starts without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const PuneApp());
    expect(find.text('ZULU BUTTONS'), findsOneWidget);
  });
}
