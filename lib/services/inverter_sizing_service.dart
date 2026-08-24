import '../models/results.dart';
import '../models/surge_mode.dart';

/// Sizes an inverter with a headroom margin above running load, and checks
/// it also clears the site's surge load under the selected [SurgeMode].
class InverterSizingService {
  const InverterSizingService();

  InverterSizing computeInverterSizing({
    required double runningLoadW,
    required double standardPeakLoadW,
    required double conservativePeakLoadW,
    required SurgeMode surgeMode,
    double headroomPercent = 20,
  }) {
    if (runningLoadW <= 0) return InverterSizing.empty;

    final surgeLoadW = surgeMode == SurgeMode.conservative
        ? conservativePeakLoadW
        : standardPeakLoadW;

    final headroomFactor = 1 - (headroomPercent.clamp(0, 95) / 100.0);
    final minInverterW = headroomFactor > 0
        ? runningLoadW / headroomFactor
        : runningLoadW;

    final surgeCoverageW = headroomFactor > 0
        ? surgeLoadW / headroomFactor
        : surgeLoadW;
    final recommendedInverterW = minInverterW > surgeCoverageW
        ? minInverterW
        : surgeCoverageW;

    return InverterSizing(
      runningLoadW: runningLoadW,
      surgeLoadW: surgeLoadW,
      headroomPercent: headroomPercent,
      minInverterW: minInverterW,
      recommendedInverterW: recommendedInverterW,
    );
  }
}
