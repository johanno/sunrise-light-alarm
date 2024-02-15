class Alarm {
  final String timeOfDay; // Updated property name
  final String music;
  final Set<String> daysOfWeek;
  final bool enabled;

  Alarm(
      {required this.timeOfDay,
      required this.music,
      required this.daysOfWeek,
      this.enabled = true});

  // Factory method to create an Alarm object from JSON
  factory Alarm.fromJson(Map<String, dynamic> json) {
    return Alarm(
        timeOfDay: json['time_of_day'] as String,
        music: json['music'] as String,
        daysOfWeek: (json['days_of_week'] as List).cast<String>().toSet(),
        enabled: json['enabled'] as bool);
  }

  // Define the copyWith method
  Alarm copyWith({
    String? timeOfDay,
    String? music,
    Set<String>? daysOfWeek,
    bool? enabled,
  }) {
    return Alarm(
      timeOfDay: timeOfDay ?? this.timeOfDay,
      music: music ?? this.music,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      enabled: enabled ?? this.enabled,
    );
  }
}
