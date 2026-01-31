import 'package:flutter_test/flutter_test.dart';

import 'package:lead_sheet_maker/main.dart';

void main() {
  testWidgets('App launches and shows title', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const LeadSheetMakerApp());

    // Verify the app title is displayed.
    expect(find.text('LeadSheetMaker'), findsOneWidget);
  });
}
