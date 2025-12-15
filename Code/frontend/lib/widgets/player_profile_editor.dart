import 'package:flutter/material.dart';
import 'dart:math';
import '../models/game_session.dart';
import '../utils/avatar_color_helper.dart';

class PlayerProfileEditor extends StatefulWidget {
  final Player player;
  final Function(String name, String avatarColor) onSave;

  const PlayerProfileEditor({
    Key? key,
    required this.player,
    required this.onSave,
  }) : super(key: key);

  @override
  State<PlayerProfileEditor> createState() => _PlayerProfileEditorState();
}

class _PlayerProfileEditorState extends State<PlayerProfileEditor> with TickerProviderStateMixin {
  late TextEditingController _nameController;
  late String _selectedAvatarColor;
  late AnimationController _animationController;

  static const List<Color> avatarColors = AvatarColorHelper.avatarColors;
  static const List<String> colorNames = AvatarColorHelper.colorNames;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.player.name);
    _selectedAvatarColor = widget.player.photoURL ?? 'blue';
    
    // Initialize animated gradient controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(PlayerProfileEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset form when player changes to ensure fresh state each time dialog opens
    if (oldWidget.player.id != widget.player.id || oldWidget.player.name != widget.player.name) {
      _nameController.text = widget.player.name;
      _selectedAvatarColor = widget.player.photoURL ?? 'blue';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  int _getColorIndex() {
    return colorNames.indexOf(_selectedAvatarColor);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 48),
      backgroundColor: Colors.transparent,
      child: SingleChildScrollView(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            final animValue = _animationController.value;
            final sineValue = (sin(animValue * 6.28) + 1) / 2;
            
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.lerp(
                      const Color(0xFF1A0B2E),
                      const Color(0xFF2D1B4E),
                      sineValue,
                    )!,
                    Color.lerp(
                      const Color(0xFF2D1B4E),
                      const Color(0xFF4A2C6D),
                      sineValue,
                    )!,
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFF9D4EDD).withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              constraints: const BoxConstraints(maxWidth: 340),
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Edit Your Profile',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Avatar preview
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF9D4EDD).withOpacity(0.3),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: avatarColors[_getColorIndex()],
                      child: Text(
                        _nameController.text.isNotEmpty
                            ? _nameController.text[0].toUpperCase()
                            : 'P',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Name input field
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'Enter your name',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: const Color(0xFFC77DFF).withOpacity(0.4),
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF9D4EDD),
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.08),
                      prefixIcon: const Icon(Icons.person, color: Color(0xFFC77DFF)),
                      labelText: 'Player Name',
                      labelStyle: const TextStyle(
                        color: Color(0xFFC77DFF),
                        fontWeight: FontWeight.w500,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 28),
                  // Avatar color selector
                  const Text(
                    'Choose Avatar Color',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: List.generate(avatarColors.length, (index) {
                      final isSelected = _selectedAvatarColor == colorNames[index];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedAvatarColor = colorNames[index];
                          });
                        },
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: avatarColors[index],
                            border: isSelected
                                ? Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  )
                                : Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 1,
                                  ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: avatarColors[index].withOpacity(0.5),
                                      blurRadius: 12,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 32,
                                  )
                                : null,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 36),
                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.12),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _nameController.text.trim().isNotEmpty
                              ? () {
                                  widget.onSave(
                                    _nameController.text.trim(),
                                    _selectedAvatarColor,
                                  );
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF9D4EDD),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.white.withOpacity(0.15),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Save',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
