import 'package:flutter/material.dart';

class AvatarColorHelper {
  static const List<String> colorNames = [
    'red',
    'pink',
    'orange',
    'yellow',
    'green',
    'blue',
    'indigo',
    'purple',
  ];

  static const List<Color> avatarColors = [
    Colors.red,
    Colors.pink,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.indigo,
    Colors.purple,
  ];

  static Color getColorFromName(String? colorName) {
    if (colorName == null) return Colors.blue;
    final index = colorNames.indexOf(colorName);
    return index >= 0 ? avatarColors[index] : Colors.blue;
  }

  static String getColorNameFromColor(Color color) {
    for (int i = 0; i < avatarColors.length; i++) {
      if (avatarColors[i] == color) {
        return colorNames[i];
      }
    }
    return 'blue';
  }

  static Color getColorForId(String id) {
    if (id.isEmpty) return Colors.blue;
    // Hash the ID to a consistent color
    final hashCode = id.hashCode.abs();
    final index = hashCode % avatarColors.length;
    return avatarColors[index];
  }
}
