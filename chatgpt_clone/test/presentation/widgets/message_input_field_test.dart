import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chatgpt_clone/presentation/widgets/message_input_field.dart';

void main() {
  Widget createMessageInputField({required Function(String) onSendMessage}) {
    return MaterialApp(
      home: Scaffold(
        body: MessageInputField(onSendMessage: onSendMessage),
      ),
    );
  }

  testWidgets('MessageInputField allows text input and sends message', (WidgetTester tester) async {
    String? sentMessage;
    await tester.pumpWidget(createMessageInputField(
      onSendMessage: (text) {
        sentMessage = text;
      },
    ));

    // Verify presence of TextField and IconButton
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byIcon(Icons.send), findsOneWidget);

    // Enter text and tap send
    const testMessage = 'This is a test message';
    await tester.enterText(find.byType(TextField), testMessage);
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump(); // Allow for state changes

    expect(sentMessage, testMessage);
    // TextField should be cleared after sending
    expect(find.widgetWithText(TextField, ''), findsOneWidget);
  });

  testWidgets('MessageInputField does not send empty message (trimmed)', (WidgetTester tester) async {
    String? sentMessage;
    bool messageSent = false;
    await tester.pumpWidget(createMessageInputField(
      onSendMessage: (text) {
        sentMessage = text;
        messageSent = true;
      },
    ));

    // Enter only spaces
    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();

    expect(messageSent, isFalse);
    expect(sentMessage, isNull);
    // TextField should still contain the spaces (or be empty if controller clears it regardless)
    expect(find.widgetWithText(TextField, '   '), findsOneWidget); 
  });
   testWidgets('MessageInputField sends message on text input submit action', (WidgetTester tester) async {
    String? sentMessage;
    await tester.pumpWidget(createMessageInputField(
      onSendMessage: (text) {
        sentMessage = text;
      },
    ));

    const testMessage = 'Submit action test';
    await tester.enterText(find.byType(TextField), testMessage);
    await tester.testTextInput.receiveAction(TextInputAction.done); // Or TextInputAction.send if that's what's set
    await tester.pump();

    expect(sentMessage, testMessage);
    expect(find.widgetWithText(TextField, ''), findsOneWidget); // Should clear
  });
}
