import 'package:flutter/material.dart';

class MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final void Function(String) onSend;
  final bool isDrawer;

  const MessageInput({Key? key, required this.controller, required this.onSend, this.isDrawer = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final viewInsetsBottom = MediaQuery.of(context).viewInsets.bottom;

    if (isDrawer) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          border: Border(
            top: BorderSide(
              color: Colors.grey.shade300,
              width: 1,
            ),
          ),
        ),
        padding: EdgeInsets.only(
          left: 12,
          right: 12,
          top: 8,
          bottom: 8 + viewInsetsBottom,
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, color: Colors.grey.shade500, size: 20),
              const SizedBox(width: 8),
              Text(
                'Drawer cannot chat',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
      ),
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: 8 + viewInsetsBottom,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: Colors.grey.shade300,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: Colors.grey.shade300,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(
                    color: Colors.deepPurple,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.deepPurple.shade500,
                  Colors.deepPurple.shade600,
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  onSend(controller.text);
                }
              },
              icon: const Icon(Icons.send, color: Colors.white),
              iconSize: 20,
              padding: const EdgeInsets.all(8),
            ),
          ),
        ],
      ),
    );
  }
}
