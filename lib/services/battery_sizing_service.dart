import '../models/design_status.dart';
import '../models/results.dart';

/// Sizes and evaluates a battery bank against an essential-load backup
/// requirement.
///
/// Series wiring increases bank voltage while Ah stays the same; parallel
/// wiring increases bank Ah while voltage stays the same. This service
/// always reports both the requirement and the configured bank so a
/// shortfall/surplus is shown as an actual number, never just "Good/Bad".
class BatterySizingService {
  const BatterySizingService();

  BatteryBankSizing computeBankSizing({
    required double essentialLoadW,
    required double backupHours,
    required double unitVoltage,
    required double unitAh,
    required int seriesCount,
    required int parallelCount,
    required double dodPercent,
    required double batteryEfficiencyPercent,
    double designReservePercent = 0,
  }) {
    final backupEnabled = backupHours > 0;
    final validUnit =
        unitVoltage > 0 && unitAh > 0 && seriesCount > 0 && parallelCount > 0;

    final bankVoltage = validUnit ? unitVoltage * seriesCount : 0.0;
    final bankAh = validUnit ? unitAh * parallelCount : 0.0;
    final nominalBankWh = bankVoltage * bankAh;

    final dodFactor = (dodPercent.clamp(0, 100)) / 100.0;
    final efficiencyFactor = (batteryEfficiencyPercent.clamp(0, 100)) / 100.0;
    final usableBankWh = nominalBankWh * dodFactor * efficiencyFactor;

    if (!backupEnabled) {
      return BatteryBankSizing(
        backupEnabled: false,
        unitVoltage: unitVoltage,
        unitAh: unitAh,
        seriesCount: seriesCount,
        parallelCount: parallelCount,
        bankVoltage: bankVoltage,
        bankAh: bankAh,
        nominalBankWh: nominalBankWh,
        usableBankWh: usableBankWh,
        status: DesignStatus.configurationIncomplete,
      );
    }

    // Energy the essential load actually needs at the wall for the target
    // backup duration, plus the user's design reserve margin.
    final requiredUsableWh =
        essentialLoadW * backupHours * (1 + designReservePercent / 100.0);

    // Nominal capacity needed to deliver that usable energy after DoD and
    // round-trip efficiency losses.
    final requiredNominalWh = (dodFactor > 0 && efficiencyFactor > 0)
        ? requiredUsableWh / dodFactor / efficiencyFactor
        : 0.0;

    final recommendedParallelCount =
        (unitVoltage > 0 && unitAh > 0 && seriesCount > 0)
        ? (requiredNominalWh / (unitVoltage * seriesCount * unitAh))
              .ceil()
              .clamp(1, 1 << 20)
        : 0;

    final surplusUsableWh = usableBankWh - requiredUsableWh;
    final estimatedRuntimeHours = essentialLoadW > 0
        ? usableBankWh / essentialLoadW
        : 0.0;

    DesignStatus status;
    if (requiredUsableWh <= 0 || !validUnit) {
      status = DesignStatus.configurationIncomplete;
    } else if (usableBankWh < requiredUsableWh) {
      status = DesignStatus.capacityShortfall;
    } else if (usableBankWh <= requiredUsableWh * 1.15) {
      status = DesignStatus.meetsSelectedTarget;
    } else {
      status = DesignStatus.additionalReserveAvailable;
    }

    return BatteryBankSizing(
      backupEnabled: true,
      backupHours: backupHours,
      unitVoltage: unitVoltage,
      unitAh: unitAh,
      seriesCount: seriesCount,
      parallelCount: parallelCount,
      bankVoltage: bankVoltage,
      bankAh: bankAh,
      nominalBankWh: nominalBankWh,
      usableBankWh: usableBankWh,
      requiredUsableWh: requiredUsableWh,
      requiredNominalWh: requiredNominalWh,
      recommendedParallelCount: recommendedParallelCount,
      surplusUsableWh: surplusUsableWh,
      estimatedRuntimeHours: estimatedRuntimeHours,
      status: status,
    );
  }
}
