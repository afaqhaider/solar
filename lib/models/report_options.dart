/// Which optional sections to include when generating a report. Core
/// technical assumptions and the disclaimer are always included and are
/// not represented here as togglable.
class ReportOptions {
  final bool includeAppliances;
  final bool includeEquipment;
  final bool includeScenarios;
  final bool includeCost;
  final bool includeNotes;

  const ReportOptions({
    this.includeAppliances = true,
    this.includeEquipment = true,
    this.includeScenarios = false,
    this.includeCost = true,
    this.includeNotes = true,
  });

  ReportOptions copyWith({
    bool? includeAppliances,
    bool? includeEquipment,
    bool? includeScenarios,
    bool? includeCost,
    bool? includeNotes,
  }) => ReportOptions(
    includeAppliances: includeAppliances ?? this.includeAppliances,
    includeEquipment: includeEquipment ?? this.includeEquipment,
    includeScenarios: includeScenarios ?? this.includeScenarios,
    includeCost: includeCost ?? this.includeCost,
    includeNotes: includeNotes ?? this.includeNotes,
  );
}
