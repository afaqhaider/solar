import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solar/state/project_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<ProjectProvider> readyProvider() async {
    final provider = ProjectProvider();
    // Wait for the async init to finish loading from (mocked) SharedPreferences.
    var attempts = 0;
    while (provider.isLoading && attempts < 50) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      attempts++;
    }
    return provider;
  }

  test(
    'rejects negative and out-of-range field values with a human-readable message',
    () async {
      final provider = await readyProvider();
      await provider.createProject('Test');

      await provider.updateSettingField('peakSunHours', '-5');
      expect(provider.fieldErrors['peakSunHours'], isNotNull);

      await provider.updateSettingField('batteryDoD', '150');
      expect(provider.fieldErrors['batteryDoD'], isNotNull);

      await provider.updateSettingField('panelWattage', '0');
      expect(provider.fieldErrors['panelWattage'], isNotNull);
    },
  );

  test(
    'rejects non-numeric, NaN-shaped, and infinite-looking input without crashing',
    () async {
      final provider = await readyProvider();
      await provider.createProject('Test');

      await provider.updateSettingField('peakSunHours', 'abc');
      expect(provider.fieldErrors['peakSunHours'], isNotNull);

      await provider.updateSettingField(
        'backupHours',
        '1e999',
      ); // parses to Infinity
      expect(provider.fieldErrors['backupHours'], isNotNull);
    },
  );

  test('valid input clears the field error', () async {
    final provider = await readyProvider();
    await provider.createProject('Test');

    await provider.updateSettingField('peakSunHours', '-1');
    expect(provider.fieldErrors['peakSunHours'], isNotNull);

    await provider.updateSettingField('peakSunHours', '5');
    expect(provider.fieldErrors['peakSunHours'], isNull);
  });

  test('battery series/parallel counters never go below 1', () async {
    final provider = await readyProvider();
    final project = await provider.createProject('Test');
    expect(project.batterySeriesCount, 1);

    await provider.updateBatteryBankCount('batterySeriesCount', -5);
    expect(provider.activeProject!.batterySeriesCount, 1);

    await provider.updateBatteryBankCount('batteryParallelCount', -5);
    expect(provider.activeProject!.batteryParallelCount, 1);
  });

  test(
    'creating a project with an empty name falls back to a default name',
    () async {
      final provider = await readyProvider();
      final project = await provider.createProject('   ');
      expect(project.name, 'Untitled Project');
    },
  );
}
