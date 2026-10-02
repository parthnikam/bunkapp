import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('FractionallySizedBox test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Container(
              width: 300,
              height: 10,
              color: Colors.grey,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: 0.5,
                child: Container(
                  key: const Key('inner'),
                  color: Colors.red,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final innerContainer = tester.getSize(find.byKey(const Key('inner')));
    print('Inner container size: $innerContainer');
  });
}
