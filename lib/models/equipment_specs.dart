/// Equipment specifications a user is considering for their project.
/// Every identifying field is optional — a fully generic/unbranded
/// configuration must remain usable.
library;

class PanelSpec {
  final String manufacturer;
  final String model;
  final double ratedPowerW;
  final double? voc;
  final double? vmp;
  final double? isc;
  final double? imp;
  final double? efficiencyPercent;
  final int quantity;

  const PanelSpec({
    this.manufacturer = '',
    this.model = '',
    this.ratedPowerW = 0,
    this.voc,
    this.vmp,
    this.isc,
    this.imp,
    this.efficiencyPercent,
    this.quantity = 1,
  });

  bool get isEmpty => ratedPowerW <= 0;
  double get totalRatedPowerW => ratedPowerW * quantity;

  PanelSpec copyWith({
    String? manufacturer,
    String? model,
    double? ratedPowerW,
    double? voc,
    bool clearVoc = false,
    double? vmp,
    bool clearVmp = false,
    double? isc,
    bool clearIsc = false,
    double? imp,
    bool clearImp = false,
    double? efficiencyPercent,
    bool clearEfficiency = false,
    int? quantity,
  }) => PanelSpec(
    manufacturer: manufacturer ?? this.manufacturer,
    model: model ?? this.model,
    ratedPowerW: ratedPowerW ?? this.ratedPowerW,
    voc: clearVoc ? null : (voc ?? this.voc),
    vmp: clearVmp ? null : (vmp ?? this.vmp),
    isc: clearIsc ? null : (isc ?? this.isc),
    imp: clearImp ? null : (imp ?? this.imp),
    efficiencyPercent: clearEfficiency
        ? null
        : (efficiencyPercent ?? this.efficiencyPercent),
    quantity: quantity ?? this.quantity,
  );

  Map<String, dynamic> toJson() => {
    'manufacturer': manufacturer,
    'model': model,
    'ratedPowerW': ratedPowerW,
    'voc': voc,
    'vmp': vmp,
    'isc': isc,
    'imp': imp,
    'efficiencyPercent': efficiencyPercent,
    'quantity': quantity,
  };

  factory PanelSpec.fromJson(Map<String, dynamic> json) => PanelSpec(
    manufacturer: json['manufacturer'] as String? ?? '',
    model: json['model'] as String? ?? '',
    ratedPowerW: (json['ratedPowerW'] as num?)?.toDouble() ?? 0,
    voc: (json['voc'] as num?)?.toDouble(),
    vmp: (json['vmp'] as num?)?.toDouble(),
    isc: (json['isc'] as num?)?.toDouble(),
    imp: (json['imp'] as num?)?.toDouble(),
    efficiencyPercent: (json['efficiencyPercent'] as num?)?.toDouble(),
    quantity: (json['quantity'] as num?)?.toInt() ?? 1,
  );
}

class InverterSpec {
  final String manufacturer;
  final String model;
  final double ratedOutputW;
  final double? surgeRatingW;
  final double? dcInputVoltage;
  final double? maxPvInputW;
  final double? mpptMinV;
  final double? mpptMaxV;
  final double? maxPvVoltage;
  final double? efficiencyPercent;

  const InverterSpec({
    this.manufacturer = '',
    this.model = '',
    this.ratedOutputW = 0,
    this.surgeRatingW,
    this.dcInputVoltage,
    this.maxPvInputW,
    this.mpptMinV,
    this.mpptMaxV,
    this.maxPvVoltage,
    this.efficiencyPercent,
  });

  bool get isEmpty => ratedOutputW <= 0;

  InverterSpec copyWith({
    String? manufacturer,
    String? model,
    double? ratedOutputW,
    double? surgeRatingW,
    bool clearSurge = false,
    double? dcInputVoltage,
    bool clearDcInput = false,
    double? maxPvInputW,
    bool clearMaxPvInput = false,
    double? mpptMinV,
    bool clearMpptMin = false,
    double? mpptMaxV,
    bool clearMpptMax = false,
    double? maxPvVoltage,
    bool clearMaxPvVoltage = false,
    double? efficiencyPercent,
    bool clearEfficiency = false,
  }) => InverterSpec(
    manufacturer: manufacturer ?? this.manufacturer,
    model: model ?? this.model,
    ratedOutputW: ratedOutputW ?? this.ratedOutputW,
    surgeRatingW: clearSurge ? null : (surgeRatingW ?? this.surgeRatingW),
    dcInputVoltage: clearDcInput
        ? null
        : (dcInputVoltage ?? this.dcInputVoltage),
    maxPvInputW: clearMaxPvInput ? null : (maxPvInputW ?? this.maxPvInputW),
    mpptMinV: clearMpptMin ? null : (mpptMinV ?? this.mpptMinV),
    mpptMaxV: clearMpptMax ? null : (mpptMaxV ?? this.mpptMaxV),
    maxPvVoltage: clearMaxPvVoltage
        ? null
        : (maxPvVoltage ?? this.maxPvVoltage),
    efficiencyPercent: clearEfficiency
        ? null
        : (efficiencyPercent ?? this.efficiencyPercent),
  );

  Map<String, dynamic> toJson() => {
    'manufacturer': manufacturer,
    'model': model,
    'ratedOutputW': ratedOutputW,
    'surgeRatingW': surgeRatingW,
    'dcInputVoltage': dcInputVoltage,
    'maxPvInputW': maxPvInputW,
    'mpptMinV': mpptMinV,
    'mpptMaxV': mpptMaxV,
    'maxPvVoltage': maxPvVoltage,
    'efficiencyPercent': efficiencyPercent,
  };

  factory InverterSpec.fromJson(Map<String, dynamic> json) => InverterSpec(
    manufacturer: json['manufacturer'] as String? ?? '',
    model: json['model'] as String? ?? '',
    ratedOutputW: (json['ratedOutputW'] as num?)?.toDouble() ?? 0,
    surgeRatingW: (json['surgeRatingW'] as num?)?.toDouble(),
    dcInputVoltage: (json['dcInputVoltage'] as num?)?.toDouble(),
    maxPvInputW: (json['maxPvInputW'] as num?)?.toDouble(),
    mpptMinV: (json['mpptMinV'] as num?)?.toDouble(),
    mpptMaxV: (json['mpptMaxV'] as num?)?.toDouble(),
    maxPvVoltage: (json['maxPvVoltage'] as num?)?.toDouble(),
    efficiencyPercent: (json['efficiencyPercent'] as num?)?.toDouble(),
  );
}

class BatteryEquipmentSpec {
  final String manufacturer;
  final String model;
  final String
  chemistry; // BatteryChemistry.name, kept as a string to avoid a circular import
  final double nominalVoltage;
  final double capacityAh;
  final double? recommendedDoDPercent;
  final int quantity;
  final int seriesCount;
  final int parallelCount;

  const BatteryEquipmentSpec({
    this.manufacturer = '',
    this.model = '',
    this.chemistry = 'leadAcid',
    this.nominalVoltage = 0,
    this.capacityAh = 0,
    this.recommendedDoDPercent,
    this.quantity = 1,
    this.seriesCount = 1,
    this.parallelCount = 1,
  });

  bool get isEmpty => nominalVoltage <= 0 || capacityAh <= 0;
  double get bankVoltage => nominalVoltage * seriesCount;
  double get bankAh => capacityAh * parallelCount;
  double get bankNominalWh => bankVoltage * bankAh;

  BatteryEquipmentSpec copyWith({
    String? manufacturer,
    String? model,
    String? chemistry,
    double? nominalVoltage,
    double? capacityAh,
    double? recommendedDoDPercent,
    bool clearDoD = false,
    int? quantity,
    int? seriesCount,
    int? parallelCount,
  }) => BatteryEquipmentSpec(
    manufacturer: manufacturer ?? this.manufacturer,
    model: model ?? this.model,
    chemistry: chemistry ?? this.chemistry,
    nominalVoltage: nominalVoltage ?? this.nominalVoltage,
    capacityAh: capacityAh ?? this.capacityAh,
    recommendedDoDPercent: clearDoD
        ? null
        : (recommendedDoDPercent ?? this.recommendedDoDPercent),
    quantity: quantity ?? this.quantity,
    seriesCount: seriesCount ?? this.seriesCount,
    parallelCount: parallelCount ?? this.parallelCount,
  );

  Map<String, dynamic> toJson() => {
    'manufacturer': manufacturer,
    'model': model,
    'chemistry': chemistry,
    'nominalVoltage': nominalVoltage,
    'capacityAh': capacityAh,
    'recommendedDoDPercent': recommendedDoDPercent,
    'quantity': quantity,
    'seriesCount': seriesCount,
    'parallelCount': parallelCount,
  };

  factory BatteryEquipmentSpec.fromJson(Map<String, dynamic> json) =>
      BatteryEquipmentSpec(
        manufacturer: json['manufacturer'] as String? ?? '',
        model: json['model'] as String? ?? '',
        chemistry: json['chemistry'] as String? ?? 'leadAcid',
        nominalVoltage: (json['nominalVoltage'] as num?)?.toDouble() ?? 0,
        capacityAh: (json['capacityAh'] as num?)?.toDouble() ?? 0,
        recommendedDoDPercent: (json['recommendedDoDPercent'] as num?)
            ?.toDouble(),
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
        seriesCount: (json['seriesCount'] as num?)?.toInt() ?? 1,
        parallelCount: (json['parallelCount'] as num?)?.toInt() ?? 1,
      );
}
