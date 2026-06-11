/// Mirrors the FastAPI response schemas in backend/app/schemas.py.

class Thresholds {
  final double moistureMin;
  final double moistureMax;
  final double tempMinC;
  final double tempMaxC;
  final int pumpDurationS;

  const Thresholds({
    required this.moistureMin,
    required this.moistureMax,
    required this.tempMinC,
    required this.tempMaxC,
    required this.pumpDurationS,
  });

  factory Thresholds.fromJson(Map<String, dynamic> json) => Thresholds(
        moistureMin: (json['moisture_min'] as num).toDouble(),
        moistureMax: (json['moisture_max'] as num).toDouble(),
        tempMinC: (json['temp_min_c'] as num).toDouble(),
        tempMaxC: (json['temp_max_c'] as num).toDouble(),
        pumpDurationS: json['pump_duration_s'] as int,
      );
}

class Reading {
  final double? soilMoisture;
  final int? soilRaw;
  final double? temperatureC;
  final bool pumpTriggered;
  final int? pumpDurationS;
  final DateTime recordedAt;

  const Reading({
    required this.soilMoisture,
    required this.soilRaw,
    required this.temperatureC,
    required this.pumpTriggered,
    required this.pumpDurationS,
    required this.recordedAt,
  });

  factory Reading.fromJson(Map<String, dynamic> json) => Reading(
        soilMoisture: (json['soil_moisture'] as num?)?.toDouble(),
        soilRaw: json['soil_raw'] as int?,
        temperatureC: (json['temperature_c'] as num?)?.toDouble(),
        pumpTriggered: json['pump_triggered'] as bool,
        pumpDurationS: json['pump_duration_s'] as int?,
        recordedAt: DateTime.parse(json['recorded_at'] as String).toLocal(),
      );
}

enum PlantStatus { healthy, dry, wet, hot, cold, unknown }

PlantStatus statusFromString(String value) {
  switch (value) {
    case 'healthy':
      return PlantStatus.healthy;
    case 'dry':
      return PlantStatus.dry;
    case 'wet':
      return PlantStatus.wet;
    case 'hot':
      return PlantStatus.hot;
    case 'cold':
      return PlantStatus.cold;
    default:
      return PlantStatus.unknown;
  }
}

class PlantSummary {
  final String id;
  final String name;
  final String? species;
  final String? location;
  final String deviceId;
  final Thresholds thresholds;
  final PlantStatus status;
  final Reading? latest;

  const PlantSummary({
    required this.id,
    required this.name,
    required this.species,
    required this.location,
    required this.deviceId,
    required this.thresholds,
    required this.status,
    required this.latest,
  });

  factory PlantSummary.fromJson(Map<String, dynamic> json) => PlantSummary(
        id: json['id'] as String,
        name: json['name'] as String,
        species: json['species'] as String?,
        location: json['location'] as String?,
        deviceId: json['device_id'] as String,
        thresholds:
            Thresholds.fromJson(json['thresholds'] as Map<String, dynamic>),
        status: statusFromString(json['status'] as String),
        latest: json['latest'] == null
            ? null
            : Reading.fromJson(json['latest'] as Map<String, dynamic>),
      );
}

class PlantHistory {
  final String plantId;
  final int hours;
  final List<Reading> readings;

  const PlantHistory({
    required this.plantId,
    required this.hours,
    required this.readings,
  });

  factory PlantHistory.fromJson(Map<String, dynamic> json) => PlantHistory(
        plantId: json['plant_id'] as String,
        hours: json['hours'] as int,
        readings: (json['readings'] as List)
            .map((r) => Reading.fromJson(r as Map<String, dynamic>))
            .toList(),
      );
}
