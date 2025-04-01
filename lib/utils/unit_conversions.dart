class UnitConversions {
  /// Converts a distance from meters to feet.
  /// [meters] is the value to convert.
  /// [decimalPlaces] is the number of decimal places for the result (defaults to 2).
  static double metersToFeet(double meters, {int decimalPlaces = 2}) {
    const double metersToFeet = 3.28084;
    final feet = meters * metersToFeet;
    return double.parse(feet.toStringAsFixed(decimalPlaces));
  }
}