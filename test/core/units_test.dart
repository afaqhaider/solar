import 'package:flutter_test/flutter_test.dart';
import 'package:solar/core/units.dart';

void main() {
  test('watt <-> kilowatt conversions', () {
    expect(Units.wToKw(1500), closeTo(1.5, 0.001));
    expect(Units.kwToW(1.5), closeTo(1500, 0.001));
  });

  test('watt-hour <-> kilowatt-hour conversions', () {
    expect(Units.whToKwh(2500), closeTo(2.5, 0.001));
    expect(Units.kwhToWh(2.5), closeTo(2500, 0.001));
  });

  test('battery Ah to usable Wh accounts for voltage and DoD', () {
    // 100Ah * 12V * 50% DoD = 600 Wh
    expect(Units.ahToUsableWh(100, 12, 50), closeTo(600, 0.001));
  });

  test('formatWatts switches to kW at 1000W and rounds sensibly', () {
    expect(Units.formatWatts(999), '999 W');
    expect(Units.formatWatts(1000), '1.00 kW');
    expect(Units.formatWatts(4827), '4.83 kW');
  });

  test('formatWh switches to kWh at 1000Wh', () {
    expect(Units.formatWh(999), '999 Wh');
    expect(Units.formatWh(10236), '10.24 kWh');
  });

  test('boundary: zero and negative values format without throwing', () {
    expect(Units.formatWatts(0), '0 W');
    expect(Units.formatWh(0), '0 Wh');
    expect(() => Units.formatWatts(-500), returnsNormally);
  });
}
