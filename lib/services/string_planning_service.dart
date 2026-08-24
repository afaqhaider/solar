import '../models/equipment_specs.dart';
import '../models/string_planning_result.dart';

/// Basic PV string arithmetic from a panel spec and a proposed string
/// layout. Does not model temperature effects on Voc — callers must show
/// [StringPlanningResult.temperatureDisclaimer].
class StringPlanningService {
  const StringPlanningService();

  StringPlanningResult computeStringPlan({
    required PanelSpec panel,
    required int panelsPerString,
    required int parallelStrings,
  }) {
    if (panel.isEmpty || panelsPerString <= 0 || parallelStrings <= 0) {
      return StringPlanningResult.empty;
    }

    final totalPanels = panelsPerString * parallelStrings;
    final stringVmp = (panel.vmp ?? 0) * panelsPerString;
    final stringVoc = (panel.voc ?? 0) * panelsPerString;
    final stringCurrentA = panel.imp ?? 0;
    final totalCurrentA = stringCurrentA * parallelStrings;
    final approximateArrayPowerW = panel.ratedPowerW * totalPanels;

    return StringPlanningResult(
      panelsPerString: panelsPerString,
      parallelStrings: parallelStrings,
      totalPanels: totalPanels,
      stringVmp: stringVmp,
      stringVoc: stringVoc,
      stringCurrentA: stringCurrentA,
      totalCurrentA: totalCurrentA,
      approximateArrayPowerW: approximateArrayPowerW,
    );
  }
}
