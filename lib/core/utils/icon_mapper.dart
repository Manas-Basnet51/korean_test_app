import 'package:flutter/material.dart';

class IconMapper {
  static IconData getIconFromString(String iconName) {
    // Map string names to specific IconData
    switch (iconName) {
      case 'book':
        return Icons.book;
      case 'school':
        return Icons.school;
      // Add more mappings as needed
      default:
        return Icons.help_outline; // Default icon
    }
  }
  
  static String getStringFromIcon(IconData icon) {
    // Reverse mapping
    if (icon == Icons.book) return 'book';
    if (icon == Icons.school) return 'school';
    // Add more mappings as needed
    return 'unknown';
  }
}