import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackdock/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our app title is present
    expect(find.text('Read It Later'), findsOneWidget);
    
    // Verify that we show "No articles found" initially (since no API call mocking here yet)
    // Note: In a real test we would mock the API service.
    // For now just checking if the app builds without crashing.
  });
}
