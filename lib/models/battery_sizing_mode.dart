/// Battery Storage Planner mode: size a bank from requirements, or evaluate
/// a user-specified bank against requirements.
enum BatterySizingMode {
  automatic,
  manual;

  static BatterySizingMode fromName(String? name) {
    return BatterySizingMode.values.firstWhere(
      (m) => m.name == name,
      orElse: () => BatterySizingMode.automatic,
    );
  }
}
