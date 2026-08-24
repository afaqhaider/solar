import 'package:flutter_test/flutter_test.dart';
import 'package:solar/models/appliance.dart';
import 'package:solar/models/project.dart';
import 'package:solar/services/project_export_service.dart';

void main() {
  const service = ProjectExportService();

  SolarProject sampleProject() {
    final p = SolarProject.create('Test Project');
    return p.copyWith(
      appliances: [
        Appliance(name: 'Fridge', wattage: 200, quantity: 1, usageHours: 24),
      ],
    );
  }

  test('export → import round-trips core fields', () {
    final original = sampleProject();
    final json = service.exportProjectToJsonString(original);
    final imported = service.importProjectFromJsonString(json);

    expect(imported.name, original.name);
    expect(imported.appliances.length, 1);
    expect(imported.appliances.first.name, 'Fridge');
    expect(imported.peakSunHours, original.peakSunHours);
  });

  test('rejects invalid JSON with a human-readable error, not a crash', () {
    expect(
      () => service.importProjectFromJsonString('not json at all {{{'),
      throwsA(isA<ProjectImportException>()),
    );
  });

  test('rejects a JSON document missing a schema version', () {
    expect(
      () => service.importProjectFromJsonString('{"project": {}}'),
      throwsA(isA<ProjectImportException>()),
    );
  });

  test('rejects an unsupported (future) schema version', () {
    expect(
      () => service.importProjectFromJsonString(
        '{"schemaVersion": 999, "project": {}}',
      ),
      throwsA(isA<ProjectImportException>()),
    );
  });

  test('rejects a project missing required fields', () {
    expect(
      () => service.importProjectFromJsonString(
        '{"schemaVersion": 1, "project": {"name": "X"}}',
      ),
      throwsA(isA<ProjectImportException>()),
    );
  });

  test(
    'rejects out-of-range numeric values rather than silently accepting them',
    () {
      final json =
          '{"schemaVersion": 1, "project": {"id": "abc", "name": "X", "peakSunHours": 999}}';
      expect(
        () => service.importProjectFromJsonString(json),
        throwsA(isA<ProjectImportException>()),
      );
    },
  );

  test('handles unicode project names and decimal values', () {
    final original = sampleProject().copyWith(
      name: 'Ösaka 太陽光 Rooftop ☀️',
      peakSunHours: 5.25,
    );
    final json = service.exportProjectToJsonString(original);
    final imported = service.importProjectFromJsonString(json);
    expect(imported.name, 'Ösaka 太陽光 Rooftop ☀️');
    expect(imported.peakSunHours, closeTo(5.25, 0.001));
  });

  test('handles a large appliance list without data loss', () {
    final many = List.generate(
      100,
      (i) => Appliance(
        name: 'Load $i',
        wattage: 10.0 + i,
        quantity: 1,
        usageHours: 1,
      ),
    );
    final original = sampleProject().copyWith(appliances: many);
    final json = service.exportProjectToJsonString(original);
    final imported = service.importProjectFromJsonString(json);
    expect(imported.appliances.length, 100);
  });
}
