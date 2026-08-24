import 'package:flutter_test/flutter_test.dart';
import 'package:solar/models/surge_mode.dart';
import 'package:solar/services/inverter_sizing_service.dart';

void main() {
  const service = InverterSizingService();

  test('returns empty result for zero running load', () {
    final result = service.computeInverterSizing(
      runningLoadW: 0,
      standardPeakLoadW: 0,
      conservativePeakLoadW: 0,
      surgeMode: SurgeMode.standard,
    );
    expect(result.minInverterW, 0);
  });

  test('applies 20% headroom by default to running load', () {
    final result = service.computeInverterSizing(
      runningLoadW: 800,
      standardPeakLoadW: 800,
      conservativePeakLoadW: 800,
      surgeMode: SurgeMode.standard,
    );
    // 800 / 0.8 = 1000 W
    expect(result.minInverterW, closeTo(1000, 0.001));
  });

  test('recommended inverter also covers the surge load with headroom', () {
    final result = service.computeInverterSizing(
      runningLoadW: 500,
      standardPeakLoadW: 2000,
      conservativePeakLoadW: 2000,
      surgeMode: SurgeMode.standard,
    );
    // min = 500/0.8 = 625; surge coverage = 2000/0.8 = 2500 -> recommended = 2500
    expect(result.minInverterW, closeTo(625, 0.001));
    expect(result.recommendedInverterW, closeTo(2500, 0.001));
  });

  test(
    'standard mode uses the standard peak, conservative mode uses the conservative peak',
    () {
      final standard = service.computeInverterSizing(
        runningLoadW: 500,
        standardPeakLoadW: 900,
        conservativePeakLoadW: 1500,
        surgeMode: SurgeMode.standard,
      );
      final conservative = service.computeInverterSizing(
        runningLoadW: 500,
        standardPeakLoadW: 900,
        conservativePeakLoadW: 1500,
        surgeMode: SurgeMode.conservative,
      );
      expect(standard.surgeLoadW, 900);
      expect(conservative.surgeLoadW, 1500);
      expect(
        conservative.recommendedInverterW,
        greaterThan(standard.recommendedInverterW),
      );
    },
  );

  test('custom headroom changes the minimum capacity', () {
    final low = service.computeInverterSizing(
      runningLoadW: 1000,
      standardPeakLoadW: 1000,
      conservativePeakLoadW: 1000,
      surgeMode: SurgeMode.standard,
      headroomPercent: 10,
    );
    final high = service.computeInverterSizing(
      runningLoadW: 1000,
      standardPeakLoadW: 1000,
      conservativePeakLoadW: 1000,
      surgeMode: SurgeMode.standard,
      headroomPercent: 30,
    );
    expect(high.minInverterW, greaterThan(low.minInverterW));
  });
}
