import '../core/units.dart';
import '../models/compatibility_result.dart';
import '../models/equipment_specs.dart';

/// Purely mathematical compatibility checks between user-entered equipment
/// specifications. Never claims certification, safety, or a guarantee.
class EquipmentCompatibilityService {
  const EquipmentCompatibilityService();

  List<CompatibilityCheck> checkPanelsAgainstInverter(
    PanelSpec panel,
    InverterSpec inverter,
  ) {
    final checks = <CompatibilityCheck>[];

    // Array power vs. inverter's maximum PV input.
    if (panel.ratedPowerW > 0 &&
        inverter.maxPvInputW != null &&
        inverter.maxPvInputW! > 0) {
      final arrayW = panel.totalRatedPowerW;
      final withinLimit = arrayW <= inverter.maxPvInputW!;
      checks.add(
        CompatibilityCheck(
          title: 'Array power vs. maximum PV input',
          status: withinLimit
              ? CompatibilityStatus.withinEnteredLimits
              : CompatibilityStatus.outsideEnteredLimits,
          detail:
              '${Units.formatWatts(arrayW)} array vs. ${Units.formatWatts(inverter.maxPvInputW!)} max PV input',
        ),
      );
    } else {
      checks.add(
        const CompatibilityCheck(
          title: 'Array power vs. maximum PV input',
          status: CompatibilityStatus.insufficientData,
          detail:
              'Enter panel rated power and the inverter\'s maximum PV input power to check this.',
        ),
      );
    }

    // Panel Voc vs. inverter's maximum PV voltage (single-panel check; the
    // String Planner covers full string Voc).
    if (panel.voc != null &&
        panel.voc! > 0 &&
        inverter.maxPvVoltage != null &&
        inverter.maxPvVoltage! > 0) {
      final withinLimit = panel.voc! <= inverter.maxPvVoltage!;
      checks.add(
        CompatibilityCheck(
          title: 'Panel Voc vs. maximum PV voltage',
          status: withinLimit
              ? CompatibilityStatus.withinEnteredLimits
              : CompatibilityStatus.outsideEnteredLimits,
          detail:
              '${panel.voc!.toStringAsFixed(1)}V panel Voc vs. ${inverter.maxPvVoltage!.toStringAsFixed(1)}V max — use the String Planner for full-string voltage.',
        ),
      );
    } else {
      checks.add(
        const CompatibilityCheck(
          title: 'Panel Voc vs. maximum PV voltage',
          status: CompatibilityStatus.insufficientData,
          detail:
              'Enter panel Voc and the inverter\'s maximum PV voltage to check this.',
        ),
      );
    }

    return checks;
  }

  CompatibilityCheck checkBatteryAgainstInverter(
    BatteryEquipmentSpec battery,
    InverterSpec inverter,
  ) {
    if (battery.isEmpty ||
        inverter.dcInputVoltage == null ||
        inverter.dcInputVoltage! <= 0) {
      return const CompatibilityCheck(
        title: 'Battery bank voltage vs. inverter DC input',
        status: CompatibilityStatus.insufficientData,
        detail:
            'Enter battery bank voltage and the inverter\'s DC input voltage to check this.',
      );
    }

    final bankV = battery.bankVoltage;
    final targetV = inverter.dcInputVoltage!;
    // Allow a small entered-tolerance band rather than requiring an exact match.
    final withinLimit = (bankV - targetV).abs() <= targetV * 0.1;

    return CompatibilityCheck(
      title: 'Battery bank voltage vs. inverter DC input',
      status: withinLimit
          ? CompatibilityStatus.withinEnteredLimits
          : CompatibilityStatus.outsideEnteredLimits,
      detail:
          '${bankV.toStringAsFixed(0)}V bank vs. ${targetV.toStringAsFixed(0)}V inverter DC input',
    );
  }
}
