import 'package:flutter/material.dart';

class AppTheme {
  // Primary Colors
  static const Color primaryColor = Color(0xFF4A5AEF);
  static const Color primaryVariantColor = Color(0xFF3A49DE); // Darker variant for contrast
  static const Color secondaryColor = Color(0xFF03DAC6);
  static const Color secondaryVariantColor = Color(0xFF018786); // Darker variant for secondary
  static const Color errorColor = Color(0xFFB00020);
  static const Color darkBackground = Color(0xFF121212);
  static const Color lightBackground = Color(0xFFF5F5F5);
  
  // Secondary Container Colors (with sufficient contrast for content)
  static const Color lightSecondaryContainer = Color(0xFFCEFAF5); // Light teal for light theme
  static const Color darkSecondaryContainer = Color(0xFF053E39); // Dark teal for dark theme
  
  // Light Theme
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      primaryContainer: Color(0xFFE0E4FF), // Light blue container
      secondary: secondaryColor,
      secondaryContainer: lightSecondaryContainer, // Ensuring contrast with secondary
      error: errorColor,
      surface: lightBackground,
      onPrimary: Colors.white,
      onPrimaryContainer: primaryColor,
      onSecondary: Colors.black,
      onSecondaryContainer: secondaryVariantColor, // Ensuring text is visible on container
      onSurface: Colors.black,
      onError: Colors.white,
      // Additional color scheme elements
      surfaceContainerHighest: Color(0xFFE4E4E4),
      onSurfaceVariant: Color(0xFF636363),
      outline: Color(0xFFDCDCDC),
      outlineVariant: Color(0xFFADADAD),
      shadow: Color(0x40000000),
      tertiary: Color(0xFF8B61FF), // Adding tertiary purple
      tertiaryContainer: Color(0xFFEEE5FF),
      onTertiary: Colors.white,
      onTertiaryContainer: Color(0xFF5D3DB8),
    ),
    
    // Typography
    fontFamily: 'Pretendard',
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
      displayMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
      displaySmall: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
      headlineMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black),
      bodyLarge: TextStyle(fontSize: 16, color: Colors.black87),
      bodyMedium: TextStyle(fontSize: 14, color: Colors.black87),
      bodySmall: TextStyle(fontSize: 12, color: Colors.black54),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
      labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black87),
      labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.black54),
    ),
    
    // Icon Theme
    iconTheme: const IconThemeData(
      color: Colors.black87,
      size: 24.0,
    ),
    
    // Primary Icon Theme (for AppBar, etc.)
    primaryIconTheme: const IconThemeData(
      color: Colors.white,
      size: 24.0,
    ),
    
    // Divider Theme
    dividerTheme: const DividerThemeData(
      color: Color(0xFFE0E0E0),
      thickness: 1,
      space: 1,
    ),
    
    // Chip Theme
    chipTheme: ChipThemeData(
      backgroundColor: Colors.grey.shade200,
      disabledColor: Colors.grey.shade300,
      selectedColor: primaryColor.withValues( alpha : 0.1),
      secondarySelectedColor: secondaryColor.withValues( alpha : 0.1),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      labelStyle: const TextStyle(color: Colors.black87),
      secondaryLabelStyle: const TextStyle(color: Colors.black87),
      brightness: Brightness.light,
    ),
    
    // Button Styles
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
      ),
    ),
    
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    
    // Tab Bar Theme
    tabBarTheme: const TabBarTheme(
      labelColor: primaryColor,
      unselectedLabelColor: Colors.black54,
      indicatorColor: primaryColor,
      labelStyle: TextStyle(fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
    ),
    
    // ListTile Theme
    listTileTheme: const ListTileThemeData(
      iconColor: primaryColor,
      textColor: Colors.black87,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    
    // Card Theme
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.white,
    ),
    
    // Input Decoration
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: errorColor),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    
    // AppBar Theme
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Colors.black),
      actionsIconTheme: IconThemeData(color: Colors.white),
    ),
    
    // Floating Action Button Theme
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 4,
      focusElevation: 6,
      hoverElevation: 8,
    ),
  );
  
  // Dark Theme
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      primaryContainer: Color(0xFF1F2C9A), // Darker blue container for dark theme
      secondary: secondaryColor,
      secondaryContainer: darkSecondaryContainer, // Dark teal with sufficient contrast
      error: errorColor,
      surface: Color(0xFF1E1E1E),
      onPrimary: Colors.white,
      onPrimaryContainer: Colors.white, // White text on dark blue container
      onSecondary: Colors.black,
      onSecondaryContainer: Colors.white, // White text on dark teal container
      onSurface: Colors.white,
      onError: Colors.white,
      // Additional color scheme elements
      surfaceContainerHighest: Color(0xFF2C2C2C),
      onSurfaceVariant: Color(0xFFE0E0E0),
      outline: Color(0xFF636363),
      outlineVariant: Color(0xFF454545),
      shadow: Color(0x40000000),
      tertiary: Color(0xFF9F7CFF), // Brighter purple for dark theme
      tertiaryContainer: Color(0xFF382A68), // Dark purple container
      onTertiary: Colors.white,
      onTertiaryContainer: Colors.white,
    ),
    
    // Typography
    fontFamily: 'Pretendard',
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
      displayMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
      displaySmall: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
      headlineMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
      bodyLarge: TextStyle(fontSize: 16, color: Colors.white70),
      bodyMedium: TextStyle(fontSize: 14, color: Colors.white70),
      bodySmall: TextStyle(fontSize: 12, color: Colors.white54),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white70),
      labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white70),
      labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.white54),
    ),
    
    // Icon Theme
    iconTheme: const IconThemeData(
      color: Colors.white70,
      size: 24.0,
    ),
    
    // Primary Icon Theme (for AppBar, etc.)
    primaryIconTheme: const IconThemeData(
      color: Colors.white,
      size: 24.0,
    ),
    
    // Divider Theme
    dividerTheme: const DividerThemeData(
      color: Color(0xFF3D3D3D),
      thickness: 1,
      space: 1,
    ),
    
    // Chip Theme
    chipTheme: ChipThemeData(
      backgroundColor: Colors.grey.shade800,
      disabledColor: Colors.grey.shade700,
      selectedColor: primaryColor.withValues( alpha : 0.3),
      secondarySelectedColor: secondaryColor.withValues( alpha : 0.3),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      labelStyle: const TextStyle(color: Colors.white70),
      secondaryLabelStyle: const TextStyle(color: Colors.white70),
      brightness: Brightness.dark,
    ),
    
    // Button Styles
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: secondaryColor,
      ),
    ),
    
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: secondaryColor,
        side: const BorderSide(color: secondaryColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    
    // Tab Bar Theme
    tabBarTheme: const TabBarTheme(
      labelColor: primaryColor,
      unselectedLabelColor: Colors.white54,
      indicatorColor: primaryColor,
      labelStyle: TextStyle(fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
    ),
    
    // ListTile Theme
    listTileTheme: const ListTileThemeData(
      iconColor: primaryColor,
      textColor: Colors.white70,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    
    // Card Theme
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: const Color(0xFF2C2C2C),
    ),
    
    // Input Decoration
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2C2C2C),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: errorColor),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    
    // AppBar Theme
    appBarTheme: const AppBarTheme(
      backgroundColor: darkBackground,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Colors.white),
      actionsIconTheme: IconThemeData(color: Colors.white),
    ),
    
    // Floating Action Button Theme
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 4,
      focusElevation: 6,
      hoverElevation: 8,
    ),
  );
  
  // Helper method to get container decoration based on theme
  static BoxDecoration getContainerDecoration(BuildContext context, {BorderRadius? borderRadius}) {
    final theme = Theme.of(context);
    return BoxDecoration(
      border: Border.all(color: theme.colorScheme.outline.withValues( alpha : 0.3)),
      borderRadius: borderRadius ?? BorderRadius.circular(12),
    );
  }
  
  // Helper method to get badge container decoration
  static BoxDecoration getBadgeDecoration(BuildContext context, {Color? bgColor}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return BoxDecoration(
      color: bgColor ?? colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: colorScheme.secondary.withValues( alpha : 0.2),
        width: 1,
      ),
    );
  }
  
  // Helper method to get icon container decoration
  static BoxDecoration getIconContainerDecoration(BuildContext context, {Color? bgColor}) {
    final theme = Theme.of(context);
    return BoxDecoration(
      color: bgColor ?? theme.colorScheme.primary.withValues( alpha : 0.1),
      borderRadius: BorderRadius.circular(8),
    );
  }
}