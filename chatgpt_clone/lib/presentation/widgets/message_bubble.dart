// In chatgpt_clone/lib/presentation/widgets/message_bubble.dart
import 'package:flutter/material.dart';

enum MessageBubbleSender { user, ai }

class MessageBubble extends StatelessWidget {
  final String text;
  final MessageBubbleSender sender;
  final Key? key;
  final bool showRegenerateButton; // New flag
  final VoidCallback? onRegenerate; // New callback

  const MessageBubble({
    required this.text,
    required this.sender,
    this.key,
    this.showRegenerateButton = false, // Default to false
    this.onRegenerate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isUser = sender == MessageBubbleSender.user;
    final alignment = isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final color = isUser ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.secondaryContainer; // Slightly different color for AI
    final textColor = isUser ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSecondaryContainer;

    return Column(
      crossAxisAlignment: alignment,
      children: [
        Row( // Use Row to align bubble and potential button for AI messages
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          // AI messages on left, User messages on right (handled by Column's crossAxisAlignment)
          children: [
            if (!isUser && showRegenerateButton && onRegenerate != null) // Button before bubble for AI
              Padding(
                padding: const EdgeInsets.only(top: 4.0, right: 0), // Adjust padding as needed
                child: IconButton(
                  icon: Icon(Icons.refresh, size: 18, color: Theme.of(context).iconTheme.color?.withOpacity(0.7)),
                  tooltip: 'Regenerate response',
                  onPressed: onRegenerate,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            Flexible( // Flexible allows bubble to take available space
              child: Container(
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
            ),
            // If you want button after bubble for user (not typical for regenerate)
            // if (isUser && showRegenerateButton && onRegenerate != null) ...
          ],
        ),
      ],
    );
  }
}
