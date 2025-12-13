import 'package:flutter/material.dart';
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

class _PlayerProfileEditorState extends State<PlayerProfileEditor> {
  late TextEditingController _nameController;
  late String _selectedAvatarColor;

  static const List<Color> avatarColors = AvatarColorHelper.avatarColors;
  static const List<String> colorNames = AvatarColorHelper.colorNames;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.player.name);
    _selectedAvatarColor = widget.player.photoURL ?? 'blue';
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
    super.dispose();
  }

  int _getColorIndex() {
    return colorNames.indexOf(_selectedAvatarColor);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 48),
      child: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.deepPurple.shade900, Colors.deepPurple.shade500],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          constraints: const BoxConstraints(maxWidth: 320),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Edit Your Profile',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              // Avatar preview
              CircleAvatar(
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
              const SizedBox(height: 24),
              // Name input field
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Enter your name',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  prefixIcon: const Icon(Icons.person, color: Colors.white),
                  labelText: 'Player Name',
                  labelStyle: const TextStyle(color: Colors.white),
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
              const SizedBox(height: 24),
              // Avatar color selector
              const Text(
                'Choose Avatar Color',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
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
                                width: 4,
                              )
                            : null,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.5),
                                  blurRadius: 8,
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
              const SizedBox(height: 32),
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _nameController.text.trim().isNotEmpty
                        ? () {
                            widget.onSave(
                              _nameController.text.trim(),
                              _selectedAvatarColor,
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.deepPurple,
                      disabledBackgroundColor: Colors.white.withOpacity(0.3),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
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
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
