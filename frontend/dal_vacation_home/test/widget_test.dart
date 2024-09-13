// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.
import 'package:dal_vacation_home/provider/app_provider.dart';
import 'package:dal_vacation_home/provider/chat_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dal_vacation_home/main.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('Launch smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: const MyApp(),
    ));

    // Verify that the login screen is displayed
    expect(find.text('DAL Vacation Home'), findsAtLeastNWidgets(1));
  });
}
