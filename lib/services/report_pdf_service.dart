import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../core/units.dart';
import '../models/project.dart';
import '../models/report_options.dart';
import '../models/system_recommendation.dart';

/// Builds a professional Solar Planning Report PDF entirely on-device, from
/// structured domain data ([SystemRecommendation]) — never by capturing or
/// scraping UI widgets/screenshots.
class ReportPdfService {
  const ReportPdfService();

  Future<Uint8List> buildReport({
    required SystemRecommendation rec,
    required SolarProject project,
    required ReportOptions options,
  }) async {
    final doc = pw.Document();
    final accent = PdfColor.fromInt(0xFFF59E0B);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.fromLTRB(36, 48, 36, 40),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Solar System Planning Report',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: accent,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(rec.projectName, style: const pw.TextStyle(fontSize: 12)),
            pw.Divider(color: PdfColors.grey400),
          ],
        ),
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Generated ${_formatDate(rec.generatedAt)}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
            pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
          ],
        ),
        build: (context) => [
          _overviewSection(project, rec, accent),
          pw.SizedBox(height: 12),
          if (options.includeAppliances) ...[
            _loadProfileSection(rec, accent),
            pw.SizedBox(height: 12),
          ],
          _energySummarySection(rec, accent),
          pw.SizedBox(height: 12),
          _solarSection(rec, accent),
          pw.SizedBox(height: 12),
          _batterySection(rec, accent),
          pw.SizedBox(height: 12),
          _inverterSection(rec, accent),
          pw.SizedBox(height: 12),
          if (options.includeEquipment && _hasEquipment(project)) ...[
            _equipmentSection(project, accent),
            pw.SizedBox(height: 12),
          ],
          _energyBalanceSection(rec, accent),
          pw.SizedBox(height: 12),
          if (options.includeCost && rec.tariffEstimate.configured) ...[
            _costSection(rec, accent),
            pw.SizedBox(height: 12),
          ],
          if (options.includeScenarios && project.scenarios.isNotEmpty) ...[
            _scenariosSection(project, accent),
            pw.SizedBox(height: 12),
          ],
          _assumptionsSection(rec, accent),
          pw.SizedBox(height: 12),
          if (options.includeNotes && project.notes.trim().isNotEmpty) ...[
            _notesSection(project, accent),
            pw.SizedBox(height: 12),
          ],
          _disclaimerSection(accent),
        ],
      ),
    );

    return doc.save();
  }

  bool _hasEquipment(SolarProject p) =>
      p.selectedPanel != null ||
      p.selectedBattery != null ||
      p.selectedInverter != null;

  pw.Widget _heading(String title, PdfColor accent) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 6),
    child: pw.Text(
      title.toUpperCase(),
      style: pw.TextStyle(
        fontSize: 11,
        fontWeight: pw.FontWeight.bold,
        color: accent,
        letterSpacing: 1,
      ),
    ),
  );

  pw.Widget _kvRow(String label, String value) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 2),
    child: pw.Row(
      children: [
        pw.SizedBox(
          width: 200,
          child: pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
        ),
        pw.Expanded(
          child: pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
        ),
      ],
    ),
  );

  pw.Widget _overviewSection(
    SolarProject project,
    SystemRecommendation rec,
    PdfColor accent,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _heading('Project Overview', accent),
        if (project.description.trim().isNotEmpty)
          pw.Text(project.description, style: const pw.TextStyle(fontSize: 10)),
        pw.SizedBox(height: 4),
        _kvRow('System type', rec.assumptions.systemType.label),
        _kvRow('Currency', project.currencyLabel),
        _kvRow('Generated', _formatDate(rec.generatedAt)),
        if (rec.scenarioName != null) _kvRow('Scenario', rec.scenarioName!),
      ],
    );
  }

  pw.Widget _loadProfileSection(SystemRecommendation rec, PdfColor accent) {
    final rows = rec.appliances
        .map(
          (a) => [
            a.name,
            '${a.quantity}',
            '${a.wattage.toStringAsFixed(0)} W',
            '${a.usageHours.toStringAsFixed(1)} h/day',
            Units.formatWh(a.averageDailyWh),
            a.backupRequired ? 'Yes' : 'No',
          ],
        )
        .toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _heading('Load Profile', accent),
        if (rows.isEmpty)
          pw.Text(
            'No appliances configured.',
            style: const pw.TextStyle(fontSize: 10),
          )
        else
          pw.TableHelper.fromTextArray(
            headers: [
              'Appliance',
              'Qty',
              'Watts',
              'Daily use',
              'Daily energy',
              'Essential',
            ],
            data: rows,
            headerStyle: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: pw.BoxDecoration(color: accent),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellHeight: 20,
            columnWidths: {
              0: const pw.FlexColumnWidth(2.4),
              1: const pw.FlexColumnWidth(0.8),
              2: const pw.FlexColumnWidth(1.2),
              3: const pw.FlexColumnWidth(1.3),
              4: const pw.FlexColumnWidth(1.4),
              5: const pw.FlexColumnWidth(1.0),
            },
          ),
      ],
    );
  }

  pw.Widget _energySummarySection(SystemRecommendation rec, PdfColor accent) {
    final load = rec.loadProfile;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _heading('Energy Summary', accent),
        _kvRow('Connected load', Units.formatWatts(load.connectedLoadW)),
        _kvRow('Running load', Units.formatWatts(load.runningLoadW)),
        _kvRow(
          'Peak / surge estimate',
          Units.formatWatts(load.conservativePeakLoadW),
        ),
        _kvRow('Daily energy', Units.formatWh(load.dailyEnergyWh)),
        _kvRow('Monthly energy', Units.formatKwh(load.monthlyEnergyKWh)),
        if (rec.essentialLoadProfile.enabledApplianceCount > 0)
          _kvRow(
            'Essential backup load',
            Units.formatWatts(rec.essentialLoadProfile.runningLoadW),
          ),
      ],
    );
  }

  pw.Widget _solarSection(SystemRecommendation rec, PdfColor accent) {
    final a = rec.solarArraySizing;
    final i = rec.assumptions;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _heading('Solar Recommendation', accent),
        _kvRow('Peak sun hours', '${i.peakSunHours} h/day'),
        _kvRow('System efficiency', '${i.systemEfficiencyPercent}%'),
        _kvRow('Calculated minimum array', Units.formatWatts(a.requiredArrayW)),
        _kvRow(
          'Recommended planning array',
          Units.formatWatts(a.recommendedArrayW),
        ),
        _kvRow('Panel wattage', '${a.panelWattage.toStringAsFixed(0)} W'),
        _kvRow('Estimated panel count', '${a.panelCount}'),
        _kvRow(
          'Estimated generation',
          '${Units.formatKwh(a.estimatedMonthlyGenerationKWh)}/month',
        ),
      ],
    );
  }

  pw.Widget _batterySection(SystemRecommendation rec, PdfColor accent) {
    final b = rec.batterySizing;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _heading('Battery Recommendation', accent),
        _kvRow('Chemistry', rec.assumptions.batteryChemistry.label),
        if (!b.backupEnabled)
          pw.Text('Not configured.', style: const pw.TextStyle(fontSize: 10))
        else ...[
          _kvRow(
            'System (bank) voltage',
            '${b.bankVoltage.toStringAsFixed(0)} V',
          ),
          _kvRow('Backup target', '${b.backupHours.toStringAsFixed(0)} h'),
          _kvRow(
            'Required storage (usable)',
            Units.formatWh(b.requiredUsableWh),
          ),
          _kvRow(
            'Required storage (nominal)',
            Units.formatWh(b.requiredNominalWh),
          ),
          _kvRow(
            'Nominal storage (configured)',
            Units.formatWh(b.nominalBankWh),
          ),
          _kvRow('Usable storage (configured)', Units.formatWh(b.usableBankWh)),
          _kvRow(
            'Proposed configuration',
            '${b.seriesCount}S${b.parallelCount}P @ ${b.unitVoltage.toStringAsFixed(0)}V/${b.unitAh.toStringAsFixed(0)}Ah',
          ),
          _kvRow(
            'Estimated autonomy',
            '${b.estimatedRuntimeHours.toStringAsFixed(1)} h',
          ),
          _kvRow('Status', b.status.label),
        ],
      ],
    );
  }

  pw.Widget _inverterSection(SystemRecommendation rec, PdfColor accent) {
    final inv = rec.inverterSizing;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _heading('Inverter Recommendation', accent),
        _kvRow('Running requirement', Units.formatWatts(inv.runningLoadW)),
        _kvRow('Surge requirement', Units.formatWatts(inv.surgeLoadW)),
        _kvRow('Headroom', '${inv.headroomPercent.toStringAsFixed(0)}%'),
        _kvRow('Calculated minimum', Units.formatWatts(inv.minInverterW)),
        _kvRow(
          'Planning capacity',
          Units.formatWatts(inv.recommendedInverterW),
        ),
      ],
    );
  }

  pw.Widget _equipmentSection(SolarProject p, PdfColor accent) {
    final rows = <pw.Widget>[];
    if (p.selectedPanel != null) {
      final s = p.selectedPanel!;
      rows.add(
        pw.Text(
          'Panel',
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        ),
      );
      rows.add(
        _kvRow(
          'Manufacturer / model',
          [s.manufacturer, s.model].where((e) => e.isNotEmpty).join(' '),
        ),
      );
      rows.add(
        _kvRow(
          'Rated power',
          '${s.ratedPowerW.toStringAsFixed(0)} W x ${s.quantity}',
        ),
      );
      if (s.vmp != null) {
        rows.add(_kvRow('Vmp', '${s.vmp!.toStringAsFixed(1)} V'));
      }
      if (s.voc != null) {
        rows.add(_kvRow('Voc', '${s.voc!.toStringAsFixed(1)} V'));
      }
    }
    if (p.selectedBattery != null) {
      final s = p.selectedBattery!;
      rows.add(pw.SizedBox(height: 6));
      rows.add(
        pw.Text(
          'Battery',
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        ),
      );
      rows.add(
        _kvRow(
          'Manufacturer / model',
          [s.manufacturer, s.model].where((e) => e.isNotEmpty).join(' '),
        ),
      );
      rows.add(
        _kvRow(
          'Nominal spec',
          '${s.nominalVoltage.toStringAsFixed(0)}V ${s.capacityAh.toStringAsFixed(0)}Ah x ${s.quantity}',
        ),
      );
    }
    if (p.selectedInverter != null) {
      final s = p.selectedInverter!;
      rows.add(pw.SizedBox(height: 6));
      rows.add(
        pw.Text(
          'Inverter',
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        ),
      );
      rows.add(
        _kvRow(
          'Manufacturer / model',
          [s.manufacturer, s.model].where((e) => e.isNotEmpty).join(' '),
        ),
      );
      rows.add(
        _kvRow('Rated output', '${s.ratedOutputW.toStringAsFixed(0)} W'),
      );
    }
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [_heading('Equipment', accent), ...rows],
    );
  }

  pw.Widget _energyBalanceSection(SystemRecommendation rec, PdfColor accent) {
    final bal = rec.energyBalance;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _heading('Energy Balance', accent),
        _kvRow('Daily consumption', Units.formatWh(bal.dailyConsumptionWh)),
        _kvRow(
          'Estimated daily generation',
          Units.formatWh(bal.dailyGenerationWh),
        ),
        _kvRow(
          'Coverage of consumption',
          '${bal.coveragePercent.toStringAsFixed(0)}%',
        ),
        _kvRow(
          bal.surplusWh >= 0 ? 'Estimated surplus' : 'Estimated shortfall',
          Units.formatWh(bal.surplusWh.abs()),
        ),
      ],
    );
  }

  pw.Widget _costSection(SystemRecommendation rec, PdfColor accent) {
    final t = rec.tariffEstimate;
    final pay = rec.paybackEstimate;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _heading('Estimated Electricity Savings', accent),
        _kvRow(
          'Estimated current monthly cost',
          '${t.currencyLabel}${t.estimatedCurrentMonthlyCost.toStringAsFixed(2)}',
        ),
        _kvRow(
          'Estimated solar offset',
          Units.formatKwh(t.estimatedSolarOffsetKWhPerMonth),
        ),
        _kvRow(
          'Estimated potential savings/mo',
          '${t.currencyLabel}${t.estimatedPotentialMonthlySavings.toStringAsFixed(2)}',
        ),
        if (pay.configured)
          _kvRow(
            'Simple payback estimate',
            pay.estimatedPaybackYears != null
                ? '${pay.estimatedPaybackYears!.toStringAsFixed(1)} years'
                : 'N/A',
          ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Estimated Potential Savings — not a guarantee. This simple estimate does not account for '
          'financing, maintenance, degradation, tariff changes, taxes, incentives, or opportunity cost.',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
        ),
      ],
    );
  }

  pw.Widget _scenariosSection(SolarProject p, PdfColor accent) {
    final rows = p.scenarios
        .map(
          (s) => [
            s.name,
            '${s.inputs.peakSunHours} h',
            '${s.inputs.panelWattage.toStringAsFixed(0)} W',
            '${s.inputs.backupHours.toStringAsFixed(0)} h',
          ],
        )
        .toList();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _heading('Design Scenarios', accent),
        pw.TableHelper.fromTextArray(
          headers: ['Scenario', 'Sun hours', 'Panel W', 'Backup'],
          data: rows,
          headerStyle: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
          ),
          headerDecoration: pw.BoxDecoration(color: accent),
          cellStyle: const pw.TextStyle(fontSize: 9),
        ),
      ],
    );
  }

  pw.Widget _assumptionsSection(SystemRecommendation rec, PdfColor accent) {
    final i = rec.assumptions;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _heading('Assumptions', accent),
        _kvRow(
          'Peak sun hours',
          '${i.peakSunHours} h/day (example default unless edited)',
        ),
        _kvRow('System efficiency', '${i.systemEfficiencyPercent}%'),
        _kvRow('Design reserve', '${i.designReservePercent}%'),
        _kvRow('Battery DoD', '${i.batteryDoD}%'),
        _kvRow('Battery efficiency', '${i.batteryEfficiencyPercent}%'),
        _kvRow('Inverter headroom', '${i.inverterHeadroomPercent}%'),
      ],
    );
  }

  pw.Widget _notesSection(SolarProject p, PdfColor accent) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _heading('Notes', accent),
        pw.Text(p.notes, style: const pw.TextStyle(fontSize: 10)),
      ],
    );
  }

  pw.Widget _disclaimerSection(PdfColor accent) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'DISCLAIMER',
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: accent,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            SystemRecommendation.disclaimer,
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
