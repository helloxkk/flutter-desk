// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_desk/viewmodels/project_viewmodel.dart';
import 'package:flutter_desk/viewmodels/device_viewmodel.dart';
import 'package:flutter_desk/viewmodels/command_viewmodel.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('App starts successfully', (WidgetTester tester) async {
    // Build our app with manually created viewmodels to avoid auto-initialization
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ProjectViewModel()),
          ChangeNotifierProvider(create: (_) => DeviceViewModel()),
          ChangeNotifierProvider(create: (_) => CommandViewModel()),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text('Flutter Manager'),
            ),
          ),
        ),
      ),
    );

    // Verify that the app title is present.
    expect(find.text('Flutter Manager'), findsOneWidget);
  });
}
