/// Result of a basic PV string plan. Temperature effects on Voc are not
/// modeled — callers must surface that limitation explicitly.
class StringPlanningResult {
  final int panelsPerString;
  final int parallelStrings;
  final int totalPanels;
  final double stringVmp;
  final double stringVoc;
  final double stringCurrentA;
  final double totalCurrentA;
  final double approximateArrayPowerW;

  const StringPlanningResult({
    this.panelsPerString = 0,
    this.parallelStrings = 0,
    this.totalPanels = 0,
    this.stringVmp = 0,
    this.stringVoc = 0,
    this.stringCurrentA = 0,
    this.totalCurrentA = 0,
    this.approximateArrayPowerW = 0,
  });

  static const empty = StringPlanningResult();

  static const temperatureDisclaimer =
      'Temperature-adjusted Voc is not calculated here — actual string design must account for '
      'temperature effects on open-circuit voltage before final installation.';
}
