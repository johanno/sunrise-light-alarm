// api_service.dart
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'alarm.dart';

class ApiService {
  final String baseUrl;

  const ApiService(this.baseUrl);

  Future<void> addAlarm(String timeOfDay, Set<String> daysOfWeek,
      String music) async {
    final daysOfWeekStr =
    daysOfWeek.map((selected) => selected.toString()).join(",");
    final response = await http.get(Uri.parse(
        '$baseUrl/add_alarm?time_of_day=$timeOfDay&days_of_week=$daysOfWeekStr&music=$music'));

    if (response.statusCode == 200) {
      // Handle success, if needed
    } else {
      // Handle error, if needed
      print('Failed to add alarm: ${response.body}');
    }
  }

  Future<List<Alarm>> getAlarms() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/get_alarms'));

      if (response.statusCode == 200) {
        final List<dynamic> alarmsData = json.decode(response.body)['alarms'];
        return alarmsData.map((data) {
          return Alarm.fromJson(data);
        }).toList();
      } else {
        throw Exception('Failed to load alarms');
      }
    } catch (e) {
      throw Exception('Error fetching alarms: $e');
    }
  }

  Future<void> updateAlarm(int alarmId, String timeOfDay, Set<String> daysOfWeek, String music, {bool enabled=true}) async {
    final daysOfWeekStr =
    daysOfWeek.map((selected) => selected.toString()).join(",");
    final response = await http.get(Uri.parse(
        '$baseUrl/update_alarm?alarm_id=$alarmId&time_of_day=$timeOfDay&days_of_week=$daysOfWeekStr&music=$music&enabled=$enabled'));

    if (response.statusCode == 200) {
      // Handle success, if needed
    } else {
      // Handle error, if needed
      print('Failed to add alarm: ${response.body}');
    }
  }
}
