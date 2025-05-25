import 'package:flutter/material.dart';

// RENAMED ENUM
enum MessageBubbleSender { user, ai } 

class MessageBubble extends StatelessWidget {
  final String text;
  final MessageBubbleSender sender; // Use renamed enum
  final Key? key;

  const MessageBubble({
    required this.text,
    required this.sender,
    this.key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use MessageBubbleSender.user for comparison
    final isUser = sender == MessageBubbleSender.user; 
    final alignment = isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    // ... rest of the build method remains the same
    final color = isUser ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.secondary;
    final textColor = isUser ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSecondary;

    return Column(
      crossAxisAlignment: alignment,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 14.0),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16.0),
              topRight: const Radius.circular(16.0),
              bottomLeft: isUser ? const Radius.circular(16.0) : Radius.zero,
              bottomRight: isUser ? Radius.zero : const Radius.circular(16.0),
            ),
          ),
          child: Text(
            text,
            style: TextStyle(color: textColor),
          ),
        ),
      ],
    );
  }
}
