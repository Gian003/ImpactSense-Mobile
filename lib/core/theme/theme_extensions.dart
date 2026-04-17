import 'package:flutter/material.dart';
import 'app_gradients.dart';

extension ThemeExtensions on BuildContext {
  AppGradients get appGradients => Theme.of(this).extension<AppGradients>()!;
}
