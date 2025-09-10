import 'package:flutter/material.dart';

class AppTheme {
  // Primary Colors
  static const Color primaryColor = Color(0xFF1976D2);
  static const Color primaryLight = Color(0xFF42A5F5);
  static const Color primaryDark = Color(0xFF1565C0);
  static const Color primaryVariant = Color(0xFF0D47A1);

  // Secondary Colors
  static const Color secondaryColor = Color(0xFFFF9800);
  static const Color secondaryLight = Color(0xFFFFB74D);
  static const Color secondaryDark = Color(0xFFF57C00);

  // Accent Colors
  static const Color accentColor = Color(0xFF4CAF50);
  static const Color accentLight = Color(0xFF81C784);
  static const Color accentDark = Color(0xFF388E3C);

  // Status Colors
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFF44336);
  static const Color infoColor = Color(0xFF2196F3);

  // Background Colors
  static const Color backgroundColor = Color(0xFFFAFAFA);
  static const Color surfaceColor = Colors.white;
  static const Color cardColor = Colors.white;

  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);

  // Border Colors
  static const Color borderColor = Color(0xFFE0E0E0);
  static const Color dividerColor = Color(0xFFBDBDBD);

  // Shadow Colors
  static const Color shadowColor = Color(0x1F000000);

  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // Border Radius
  static const double borderRadiusS = 4.0;
  static const double borderRadiusM = 8.0;
  static const double borderRadiusL = 12.0;
  static const double borderRadiusXL = 16.0;
  static const double borderRadiusXXL = 24.0;

  // Font Sizes
  static const double fontSizeXS = 12.0;
  static const double fontSizeS = 14.0;
  static const double fontSizeM = 16.0;
  static const double fontSizeL = 18.0;
  static const double fontSizeXL = 20.0;
  static const double fontSizeXXL = 24.0;
  static const double fontSizeXXXL = 32.0;

  // Font Weights
  static const FontWeight fontWeightLight = FontWeight.w300;
  static const FontWeight fontWeightRegular = FontWeight.w400;
  static const FontWeight fontWeightMedium = FontWeight.w500;
  static const FontWeight fontWeightSemiBold = FontWeight.w600;
  static const FontWeight fontWeightBold = FontWeight.w700;

  // Elevation
  static const double elevationS = 2.0;
  static const double elevationM = 4.0;
  static const double elevationL = 8.0;
  static const double elevationXL = 16.0;

  // Animation Duration
  static const Duration animationDurationFast = Duration(milliseconds: 150);
  static const Duration animationDurationNormal = Duration(milliseconds: 300);
  static const Duration animationDurationSlow = Duration(milliseconds: 500);

  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: primaryColor,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        primaryContainer: primaryLight,
        secondary: secondaryColor,
        secondaryContainer: secondaryLight,
        surface: surfaceColor,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onError: Colors.white,
      ),

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: elevationM,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: fontSizeXL,
          fontWeight: fontWeightSemiBold,
          color: Colors.white,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: elevationS,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusL),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: spacingM,
          vertical: spacingS,
        ),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: elevationS,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingL,
            vertical: spacingM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusM),
          ),
          textStyle: const TextStyle(
            fontSize: fontSizeM,
            fontWeight: fontWeightMedium,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 1.5),
          padding: const EdgeInsets.symmetric(
            horizontal: spacingL,
            vertical: spacingM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusM),
          ),
          textStyle: const TextStyle(
            fontSize: fontSizeM,
            fontWeight: fontWeightMedium,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingM,
            vertical: spacingS,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusM),
          ),
          textStyle: const TextStyle(
            fontSize: fontSizeM,
            fontWeight: fontWeightMedium,
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingM,
          vertical: spacingM,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusM),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusM),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusM),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusM),
          borderSide: const BorderSide(color: errorColor),
        ),
        labelStyle: const TextStyle(
          color: textSecondary,
          fontSize: fontSizeM,
        ),
        hintStyle: const TextStyle(
          color: textHint,
          fontSize: fontSizeM,
        ),
      ),

      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: fontSizeXXXL,
          fontWeight: fontWeightBold,
          color: textPrimary,
        ),
        displayMedium: TextStyle(
          fontSize: fontSizeXXL,
          fontWeight: fontWeightBold,
          color: textPrimary,
        ),
        displaySmall: TextStyle(
          fontSize: fontSizeXL,
          fontWeight: fontWeightSemiBold,
          color: textPrimary,
        ),
        headlineLarge: TextStyle(
          fontSize: fontSizeXL,
          fontWeight: fontWeightSemiBold,
          color: textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: fontSizeL,
          fontWeight: fontWeightSemiBold,
          color: textPrimary,
        ),
        headlineSmall: TextStyle(
          fontSize: fontSizeL,
          fontWeight: fontWeightMedium,
          color: textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: fontSizeL,
          fontWeight: fontWeightMedium,
          color: textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: fontSizeM,
          fontWeight: fontWeightMedium,
          color: textPrimary,
        ),
        titleSmall: TextStyle(
          fontSize: fontSizeM,
          fontWeight: fontWeightMedium,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: fontSizeM,
          fontWeight: fontWeightRegular,
          color: textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: fontSizeM,
          fontWeight: fontWeightRegular,
          color: textPrimary,
        ),
        bodySmall: TextStyle(
          fontSize: fontSizeS,
          fontWeight: fontWeightRegular,
          color: textSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: fontSizeM,
          fontWeight: fontWeightMedium,
          color: textPrimary,
        ),
        labelMedium: TextStyle(
          fontSize: fontSizeS,
          fontWeight: fontWeightMedium,
          color: textSecondary,
        ),
        labelSmall: TextStyle(
          fontSize: fontSizeXS,
          fontWeight: fontWeightMedium,
          color: textSecondary,
        ),
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: textSecondary,
        size: 24,
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: secondaryColor,
        foregroundColor: Colors.white,
        elevation: elevationM,
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: textSecondary,
        elevation: elevationL,
        type: BottomNavigationBarType.fixed,
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: spacingM,
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryColor,
        linearTrackColor: Color(0xFFE0E0E0),
      ),

      // SnackBar Theme
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Color(0xFF323232),
        contentTextStyle: TextStyle(color: Colors.white),
        actionTextColor: secondaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(borderRadiusM)),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        elevation: elevationL,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusL),
        ),
        titleTextStyle: const TextStyle(
          fontSize: fontSizeXL,
          fontWeight: fontWeightSemiBold,
          color: textPrimary,
        ),
        contentTextStyle: const TextStyle(
          fontSize: fontSizeM,
          color: textPrimary,
        ),
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceColor,
        elevation: elevationL,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(borderRadiusXL),
          ),
        ),
      ),

      // Tab Bar Theme
      tabBarTheme: const TabBarThemeData(
        labelColor: primaryColor,
        unselectedLabelColor: textSecondary,
        indicatorColor: primaryColor,
        indicatorSize: TabBarIndicatorSize.tab,
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey.shade100,
        selectedColor: primaryLight,
        checkmarkColor: Colors.white,
        deleteIconColor: Colors.grey.shade600,
        labelStyle: const TextStyle(
          color: textPrimary,
          fontSize: fontSizeS,
        ),
        secondaryLabelStyle: const TextStyle(
          color: Colors.white,
          fontSize: fontSizeS,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusXXL),
        ),
      ),

      // DataTable Theme
      dataTableTheme: const DataTableThemeData(
        headingRowColor: WidgetStatePropertyAll(primaryColor),
        headingTextStyle: TextStyle(
          color: Colors.white,
          fontWeight: fontWeightSemiBold,
        ),
        dataRowColor: WidgetStatePropertyAll(surfaceColor),
        dividerThickness: 1,
      ),

      // List Tile Theme
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(
          horizontal: spacingM,
          vertical: spacingS,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(borderRadiusM)),
        ),
      ),

      // Expansion Tile Theme
      expansionTileTheme: const ExpansionTileThemeData(
        backgroundColor: surfaceColor,
        collapsedBackgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(borderRadiusM)),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(borderRadiusM)),
        ),
      ),

      // Tooltip Theme
      tooltipTheme: const TooltipThemeData(
        decoration: BoxDecoration(
          color: Color(0xFF2A2A2A),
          borderRadius: BorderRadius.all(Radius.circular(borderRadiusS)),
        ),
        textStyle: TextStyle(
          color: Colors.white,
          fontSize: fontSizeS,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: spacingM,
          vertical: spacingS,
        ),
      ),

      // Page Transitions
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),

      // Visual Density
      visualDensity: VisualDensity.adaptivePlatformDensity,

      // Material Tap Target Size
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
  }

  // Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      colorScheme: const ColorScheme.dark(
        primary: primaryLight,
        primaryContainer: primaryColor,
        secondary: secondaryLight,
        secondaryContainer: secondaryColor,
        surface: Color(0xFF121212),
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        onError: Colors.white,
      ),

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: elevationM,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: fontSizeXL,
          fontWeight: fontWeightSemiBold,
          color: Colors.white,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: const Color(0xFF1E1E1E),
        elevation: elevationS,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusL),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: spacingM,
          vertical: spacingS,
        ),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: elevationS,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingL,
            vertical: spacingM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusM),
          ),
          textStyle: const TextStyle(
            fontSize: fontSizeM,
            fontWeight: fontWeightMedium,
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingM,
          vertical: spacingM,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusM),
          borderSide: const BorderSide(color: Color(0xFF404040)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusM),
          borderSide: const BorderSide(color: Color(0xFF404040)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusM),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusM),
          borderSide: const BorderSide(color: errorColor),
        ),
        labelStyle: const TextStyle(
          color: Color(0xFFB0B0B0),
          fontSize: fontSizeM,
        ),
        hintStyle: const TextStyle(
          color: Color(0xFF808080),
          fontSize: fontSizeM,
        ),
      ),

      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: fontSizeXXXL,
          fontWeight: fontWeightBold,
          color: Colors.white,
        ),
        displayMedium: TextStyle(
          fontSize: fontSizeXXL,
          fontWeight: fontWeightBold,
          color: Colors.white,
        ),
        displaySmall: TextStyle(
          fontSize: fontSizeXL,
          fontWeight: fontWeightSemiBold,
          color: Colors.white,
        ),
        headlineLarge: TextStyle(
          fontSize: fontSizeXL,
          fontWeight: fontWeightSemiBold,
          color: Colors.white,
        ),
        headlineMedium: TextStyle(
          fontSize: fontSizeL,
          fontWeight: fontWeightSemiBold,
          color: Colors.white,
        ),
        headlineSmall: TextStyle(
          fontSize: fontSizeL,
          fontWeight: fontWeightMedium,
          color: Colors.white,
        ),
        titleLarge: TextStyle(
          fontSize: fontSizeL,
          fontWeight: fontWeightMedium,
          color: Colors.white,
        ),
        titleMedium: TextStyle(
          fontSize: fontSizeM,
          fontWeight: fontWeightMedium,
          color: Colors.white,
        ),
        titleSmall: TextStyle(
          fontSize: fontSizeM,
          fontWeight: fontWeightMedium,
          color: Colors.white,
        ),
        bodyLarge: TextStyle(
          fontSize: fontSizeM,
          fontWeight: fontWeightRegular,
          color: Colors.white,
        ),
        bodyMedium: TextStyle(
          fontSize: fontSizeM,
          fontWeight: fontWeightRegular,
          color: Colors.white,
        ),
        bodySmall: TextStyle(
          fontSize: fontSizeS,
          fontWeight: fontWeightRegular,
          color: Color(0xFFB0B0B0),
        ),
        labelLarge: TextStyle(
          fontSize: fontSizeM,
          fontWeight: fontWeightMedium,
          color: Colors.white,
        ),
        labelMedium: TextStyle(
          fontSize: fontSizeS,
          fontWeight: fontWeightMedium,
          color: Color(0xFFB0B0B0),
        ),
        labelSmall: TextStyle(
          fontSize: fontSizeXS,
          fontWeight: fontWeightMedium,
          color: Color(0xFFB0B0B0),
        ),
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: Color(0xFFB0B0B0),
        size: 24,
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: secondaryColor,
        foregroundColor: Colors.white,
        elevation: elevationM,
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1E1E1E),
        selectedItemColor: primaryLight,
        unselectedItemColor: Color(0xFFB0B0B0),
        elevation: elevationL,
        type: BottomNavigationBarType.fixed,
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: Color(0xFF404040),
        thickness: 1,
        space: spacingM,
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryLight,
        linearTrackColor: Color(0xFF404040),
      ),

      // SnackBar Theme
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Color(0xFF2A2A2A),
        contentTextStyle: TextStyle(color: Colors.white),
        actionTextColor: secondaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(borderRadiusM)),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: elevationL,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusL),
        ),
        titleTextStyle: const TextStyle(
          fontSize: fontSizeXL,
          fontWeight: fontWeightSemiBold,
          color: Colors.white,
        ),
        contentTextStyle: const TextStyle(
          fontSize: fontSizeM,
          color: Colors.white,
        ),
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF1E1E1E),
        elevation: elevationL,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(borderRadiusXL),
          ),
        ),
      ),

      // Tab Bar Theme
      tabBarTheme: const TabBarThemeData(
        labelColor: primaryLight,
        unselectedLabelColor: Color(0xFFB0B0B0),
        indicatorColor: primaryLight,
        indicatorSize: TabBarIndicatorSize.tab,
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF2A2A2A),
        selectedColor: primaryColor,
        checkmarkColor: Colors.white,
        deleteIconColor: const Color(0xFFB0B0B0),
        labelStyle: const TextStyle(
          color: Colors.white,
          fontSize: fontSizeS,
        ),
        secondaryLabelStyle: const TextStyle(
          color: Colors.white,
          fontSize: fontSizeS,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusXXL),
        ),
      ),

      // DataTable Theme
      dataTableTheme: const DataTableThemeData(
        headingRowColor: WidgetStatePropertyAll(primaryColor),
        headingTextStyle: TextStyle(
          color: Colors.white,
          fontWeight: fontWeightSemiBold,
        ),
        dataRowColor: WidgetStatePropertyAll(Color(0xFF1E1E1E)),
        dividerThickness: 1,
      ),

      // List Tile Theme
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(
          horizontal: spacingM,
          vertical: spacingS,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(borderRadiusM)),
        ),
      ),

      // Expansion Tile Theme
      expansionTileTheme: const ExpansionTileThemeData(
        backgroundColor: Color(0xFF1E1E1E),
        collapsedBackgroundColor: Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(borderRadiusM)),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(borderRadiusM)),
        ),
      ),

      // Tooltip Theme
      tooltipTheme: const TooltipThemeData(
        decoration: BoxDecoration(
          color: Color(0xFF2A2A2A),
          borderRadius: BorderRadius.all(Radius.circular(borderRadiusS)),
        ),
        textStyle: TextStyle(
          color: Colors.white,
          fontSize: fontSizeS,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: spacingM,
          vertical: spacingS,
        ),
      ),

      // Page Transitions
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),

      // Visual Density
      visualDensity: VisualDensity.adaptivePlatformDensity,

      // Material Tap Target Size
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
  }

  // Custom Components
  static Widget buildLoadingIndicator({String? message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: spacingM),
            Text(
              message,
              style: const TextStyle(
                fontSize: fontSizeM,
                color: textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static Widget buildErrorWidget(String error, {VoidCallback? onRetry}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: errorColor,
          ),
          const SizedBox(height: spacingM),
          const Text(
            'Error',
            style: TextStyle(
              fontSize: fontSizeXL,
              fontWeight: fontWeightSemiBold,
              color: errorColor,
            ),
          ),
          const SizedBox(height: spacingS),
          Text(
            error,
            style: const TextStyle(
              fontSize: fontSizeM,
              color: textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: spacingL),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }

  static Widget buildEmptyState({
    required String title,
    required String message,
    required IconData icon,
    VoidCallback? onAction,
    String? actionText,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: textHint,
          ),
          const SizedBox(height: spacingM),
          Text(
            title,
            style: const TextStyle(
              fontSize: fontSizeXL,
              fontWeight: fontWeightSemiBold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: spacingS),
          Text(
            message,
            style: const TextStyle(
              fontSize: fontSizeM,
              color: textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (onAction != null && actionText != null) ...[
            const SizedBox(height: spacingL),
            ElevatedButton(
              onPressed: onAction,
              child: Text(actionText),
            ),
          ],
        ],
      ),
    );
  }

  static Widget buildResponsiveContainer({
    required BuildContext context,
    required Widget child,
    double maxWidth = 1200,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: spacingM),
  }) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: padding,
      child: child,
    );
  }

  static double getResponsiveFontSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 360) return baseSize * 0.8; // Small phones
    if (screenWidth < 480) return baseSize * 0.9; // Normal phones
    if (screenWidth < 768) return baseSize; // Large phones/Tablets
    return baseSize * 1.1; // Tablets/Large screens
  }

  static EdgeInsets getResponsivePadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 360) return const EdgeInsets.all(spacingS);
    if (screenWidth < 480) return const EdgeInsets.all(spacingM);
    return const EdgeInsets.all(spacingL);
  }

  static double getResponsiveSpacing(BuildContext context, double baseSpacing) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 360) return baseSpacing * 0.8;
    if (screenWidth < 480) return baseSpacing * 0.9;
    return baseSpacing;
  }
}