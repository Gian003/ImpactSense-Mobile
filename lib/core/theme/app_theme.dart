import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_gradients.dart';

class AppTheme {
  static ThemeData light = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.backgroundLight,

    colorScheme: ColorScheme.light(
      primary: AppColors.primaryColor,
      secondary: AppColors.secondaryColor,
    ),

    extensions: [
      const AppGradients(
        primaryGradient: LinearGradient(
          colors: [
            Color.fromARGB(255, 25, 44, 52),
            Color.fromARGB(255, 17, 84, 113),
          ],
        ),
        secondaryGradient: LinearGradient(
          colors: [
            Color.fromARGB(255, 17, 84, 113),
            Color.fromARGB(255, 25, 44, 52),
          ],
        ),
      ),
    ],
  );

  static ThemeData dark = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.backgroundDark,

    colorScheme: const ColorScheme.dark(),

    extensions: [
      const AppGradients(
        primaryGradient: LinearGradient(
          colors: [
            Color.fromARGB(255, 25, 44, 52),
            Color.fromARGB(255, 17, 84, 113),
          ],
        ),
        secondaryGradient: LinearGradient(
          colors: [
            Color.fromARGB(255, 17, 84, 113),
            Color.fromARGB(255, 25, 44, 52),
          ],
        ),
      ),
    ],
  );
}
