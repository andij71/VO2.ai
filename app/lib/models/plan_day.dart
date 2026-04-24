// lib/models/plan_day.dart

class PlanDayModel {
  final int week;
  final int dayOfWeek;
  final String sessionType;
  final String label;
  final double distanceKm;
  final String targetPace;
  final int effortZone;
  final String? notes;

  PlanDayModel({
    required this.week,
    required this.dayOfWeek,
    required this.sessionType,
    required this.label,
    required this.distanceKm,
    required this.targetPace,
    required this.effortZone,
    this.notes,
  });

  factory PlanDayModel.fromJson(Map<String, dynamic> json) {
    return PlanDayModel(
      week: json['week'] as int,
      dayOfWeek: json['dayOfWeek'] as int,
      sessionType: json['sessionType'] as String,
      label: json['label'] as String,
      distanceKm: (json['distanceKm'] as num).toDouble(),
      targetPace: json['targetPace'] as String,
      effortZone: json['effortZone'] as int,
      notes: json['notes'] as String?,
    );
  }
}
