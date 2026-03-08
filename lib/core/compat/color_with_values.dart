import 'dart:ui' show Color;

extension ColorWithValuesCompat on Color {
  /// Compat shim for newer Flutter API `Color.withValues(...)`.
  ///
  /// The project only uses the `alpha` named parameter, so we map it to
  /// `withOpacity` available in older Flutter versions.
  Color withValues({double? alpha}) {
    if (alpha == null) return this;
    final normalized = alpha.clamp(0.0, 1.0).toDouble();
    return withOpacity(normalized);
  }
}
