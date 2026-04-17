import 'package:flutter/material.dart';

class AppGradients extends ThemeExtension<AppGradients> {
  final LinearGradient? primaryGradient;
  final LinearGradient? secondaryGradient;

  const AppGradients({this.primaryGradient, this.secondaryGradient});

  @override
  ThemeExtension<AppGradients> copyWith({
    LinearGradient? primaryGradient,
    LinearGradient? secondaryGradient,
  }) {
    return AppGradients(
      primaryGradient: primaryGradient ?? this.primaryGradient,
      secondaryGradient: secondaryGradient ?? this.secondaryGradient,
    );
  }

  @override
  AppGradients lerp(ThemeExtension<AppGradients>? other, double t) {
    if (other is! AppGradients) return this;
    return AppGradients(
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
