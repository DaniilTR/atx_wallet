import 'dart:ui' show Color;

extension ColorWithValuesCompat on Color {
  /// Compat shim for newer Flutter API `Color.withValues(...)`.
  ///
  /// In this project we only rely on the `alpha` named parameter.
  /// Map it to `withOpacity`, which exists in older Flutter versions.
  Color withValues({double? alpha}) {
    if (alpha == null) return this;
    final normalized = alpha.clamp(0.0, 1.0).toDouble();
    return withOpacity(normalized);
  }
}
