class BMICalculator {
  static double calculate({
    required double weightKg,
    required double heightCm,
  }) {
    final heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }

  static String category(double bmi) {
    if (bmi < 18.5) return "Underweight";
    if (bmi < 25) return "Normal";
    if (bmi < 30) return "Overweight";
    return "Obese";
  }
}
