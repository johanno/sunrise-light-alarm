// api_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:encrypt_shared_pref/pref_service.dart';
import 'package:http/http.dart' as http;
import 'alarm.dart';

const String apiUrlKey = "api_url";
const String defaultUrl = "http://localhost:8080";

class ApiService {
  late Future<String> _baseUrl;
  final SecureStorage secureStorage = SecureStorage();

  ApiService() {
    _baseUrl = _loadBaseUrl();
  }

  Future<String> get baseUrl async => await _baseUrl;

  Future<String> updateBaseUrl(String newUrl) async {
    _baseUrl = Future(() => newUrl);
    await _saveBaseUrl(newUrl);
    return newUrl;
  }

  Future<void> _saveBaseUrl(String apiUrl) async {
    await secureStorage.writeString(key: apiUrlKey, value: apiUrl, isEncrypted: false);
  }

  Future<String> _loadBaseUrl() async {
    final loadedUrl = await secureStorage.readString(key: apiUrlKey, isEncrypted: false);
    return loadedUrl ?? defaultUrl;
  }

  Future<List<String>> getMusicList() async {
    try {
      String baseUrl = await _baseUrl;
      final response = await http.get(Uri.parse('$baseUrl/list_music_files'));

      if (response.statusCode == 200) {
        final List<dynamic> musicData =
            json.decode(response.body)['music_files'];
        return musicData.map((music) => music as String).toList();
      } else {
        throw Exception('Failed to load music list');
      }
    } catch (e) {
      throw Exception('Error fetching music list: $e');
    }
  }

  Future<bool> testConnection() async {
    try {
      String baseUrl = await _baseUrl;
      final response = await http.get(Uri.parse('$baseUrl/test_con'));
      // print("Test: $response");
      return response.statusCode == 200;
    } catch (e) {
      print("Couldn't connect to $baseUrl: $e");
      return false;
    }
  }

  Future<void> addAlarm(
      String timeOfDay, Set<String> daysOfWeek, String music) async {
    String baseUrl = await _baseUrl;
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
    String baseUrl = await _baseUrl;
    const maxRetries = 3;
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        final response = await http.get(Uri.parse('$baseUrl/get_alarms'));

        if (response.statusCode == 200) {
          final List<dynamic> alarmsData = json.decode(response.body)['alarms'];
          return alarmsData.map((data) {
            return Alarm.fromJson(data);
          }).toList();
        } else {
          var errmsg =
              "Failed to load alarms with status: ${response.statusCode}";
          print(errmsg);
          // If the response status is not 200, consider it an error and retry
          retryCount++;
          if (retryCount >= maxRetries) {
            return [
              Alarm(timeOfDay: errmsg, music: "", daysOfWeek: {""})
            ];
          }
          await Future.delayed(const Duration(seconds: 1));
          print('Retrying...');
        }
      } catch (e) {
        print('Error fetching alarms: $e');
        retryCount++;
        await Future.delayed(const Duration(seconds: 2));
        print('Retrying...');
      }
    }
    // If max retries reached and still unsuccessful, throw an exception or handle accordingly
    throw Exception('Max retries reached. Unable to fetch alarms.');
  }

  Future<void> updateAlarm(
      int alarmId, String timeOfDay, Set<String> daysOfWeek, String music,
      {bool enabled = true}) async {
    String baseUrl = await _baseUrl;
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

  Future<void> deleteAlarm(int alarmId) async {
    try {
      String baseUrl = await _baseUrl;
      final response = await http.get(
        Uri.parse('$baseUrl/remove?alarm_id=$alarmId'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['status'] == 'OK') {
          // Success, alarm deleted
        } else {
          throw Exception('Failed to delete alarm: ${responseData['status']}');
        }
      } else {
        throw Exception(
            'Failed to delete alarm with status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting alarm: $e');
    }
  }
}
