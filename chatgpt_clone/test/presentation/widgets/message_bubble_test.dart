import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chatgpt_clone/presentation/widgets/message_bubble.dart';

void main() {
  Widget createMessageBubble({required String text, required MessageBubbleSender sender}) {
    return MaterialApp(
      home: Scaffold(
        body: MessageBubble(text: text, sender: sender),
      ),
    );
  }

  testWidgets('MessageBubble renders user message correctly', (WidgetTester tester) async {
    const testMessage = 'Hello from user';
    await tester.pumpWidget(createMessageBubble(text: testMessage, sender: MessageBubbleSender.user));

    expect(find.text(testMessage), findsOneWidget);
    // Check for alignment (more complex, might involve finding specific Container properties or using a Key)
    // For simplicity, we're mainly checking text rendering.
    // User messages typically align to the right.
  });

  testWidgets('MessageBubble renders AI message correctly', (WidgetTester tester) async {
    const testMessage = 'Hello from AI';
    await tester.pumpWidget(createMessageBubble(text: testMessage, sender: MessageBubbleSender.ai));

    expect(find.text(testMessage), findsOneWidget);
    // AI messages typically align to the left.
  });
}
