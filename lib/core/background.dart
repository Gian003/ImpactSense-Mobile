import 'package:flutter/material.dart';

class Background {
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color.fromARGB(255, 25, 44, 52), Color.fromARGB(255, 17, 84, 113)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

class GradientTheme extends ThemeExtension<GradientTheme> {
  final LinearGradient? primaryGradient;
  final LinearGradient? secondaryGradient;

  const GradientTheme({this.primaryGradient, this.secondaryGradient});

  @override
  ThemeExtension<GradientTheme> copyWith({
    LinearGradient? primaryGradient,
    LinearGradient? secondaryGradient,
  }) {
    return GradientTheme(
      primaryGradient: primaryGradient ?? this.primaryGradient,
      secondaryGradient: secondaryGradient ?? this.secondaryGradient,
    );
  }

  @override
  GradientTheme lerp(ThemeExtension<GradientTheme>? other, double t) {
    if (other is! GradientTheme) return this;
    return GradientTheme(
      primaryGradient: LinearGradient.lerp(
        primaryGradient,
        other.primaryGradient,
        t,
      ),
      secondaryGradient: LinearGradient.lerp(
        secondaryGradient,
        other.secondaryGradient,
        t,
      ),
    );
  }
}
