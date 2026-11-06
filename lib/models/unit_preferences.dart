enum WeightUnit { kg, lb }

enum DistanceUnit { km, mi }

enum HeightUnit {
  cm('cm'),
  inches('in');

  const HeightUnit(this.jsonValue);

  final String jsonValue;
}

/// Unit choices persisted with the profile.
class UnitPreferences {
  const UnitPreferences({
    this.schemaVersion = 1,
    this.weightUnit = WeightUnit.kg,
    this.distanceUnit = DistanceUnit.km,
    this.heightUnit = HeightUnit.cm,
  });

  final int schemaVersion;
  final WeightUnit weightUnit;
  final DistanceUnit distanceUnit;
  final HeightUnit heightUnit;

  factory UnitPreferences.fromJson(Map<String, dynamic> json) {
    return UnitPreferences(
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
      weightUnit: WeightUnit.values.firstWhere(
        (unit) => unit.name == json['weightUnit'],
        orElse: () => WeightUnit.kg,
      ),
      distanceUnit: DistanceUnit.values.firstWhere(
        (unit) => unit.name == json['distanceUnit'],
        orElse: () => DistanceUnit.km,
      ),
      heightUnit: HeightUnit.values.firstWhere(
        (unit) => unit.jsonValue == json['heightUnit'],
        orElse: () => HeightUnit.cm,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'schemaVersion': schemaVersion,
      'weightUnit': weightUnit.name,
      'distanceUnit': distanceUnit.name,
      'heightUnit': heightUnit.jsonValue,
    };
  }

  UnitPreferences copyWith({
    int? schemaVersion,
    WeightUnit? weightUnit,
    DistanceUnit? distanceUnit,
    HeightUnit? heightUnit,
  }) {
    return UnitPreferences(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      weightUnit: weightUnit ?? this.weightUnit,
      distanceUnit: distanceUnit ?? this.distanceUnit,
      heightUnit: heightUnit ?? this.heightUnit,
    );
  }
}
