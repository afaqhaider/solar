import 'package:flutter_test/flutter_test.dart';
import 'package:solar/models/equipment_specs.dart';
import 'package:solar/services/string_planning_service.dart';

void main() {
  const service = StringPlanningService();

  test('empty result when panel spec is empty or layout is zero', () {
    final result = service.computeStringPlan(
      panel: const PanelSpec(),
      panelsPerString: 4,
      parallelStrings: 2,
    );
    expect(result.totalPanels, 0);
  });

  test('computes string voltage, current and array power', () {
    const panel = PanelSpec(ratedPowerW: 400, vmp: 32, voc: 40, imp: 12.5);
    final result = service.computeStringPlan(
      panel: panel,
      panelsPerString: 10,
      parallelStrings: 2,
    );

    expect(result.totalPanels, 20);
    // String Vmp = 32 * 10 = 320V
    expect(result.stringVmp, closeTo(320, 0.001));
    // String Voc = 40 * 10 = 400V
    expect(result.stringVoc, closeTo(400, 0.001));
    // String current = Imp = 12.5A; total current with 2 parallel strings = 25A
    expect(result.stringCurrentA, closeTo(12.5, 0.001));
    expect(result.totalCurrentA, closeTo(25, 0.001));
    // Array power = 400W * 20 panels = 8000W
    expect(result.approximateArrayPowerW, closeTo(8000, 0.001));
  });

  test('boundary: a single panel, single string still computes correctly', () {
    const panel = PanelSpec(ratedPowerW: 300, vmp: 30, voc: 37, imp: 10);
    final result = service.computeStringPlan(
      panel: panel,
      panelsPerString: 1,
      parallelStrings: 1,
    );
    expect(result.totalPanels, 1);
    expect(result.stringVmp, closeTo(30, 0.001));
    expect(result.approximateArrayPowerW, closeTo(300, 0.001));
  });
}
