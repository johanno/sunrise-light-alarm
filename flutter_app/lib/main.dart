// main.dart
import 'dart:convert'; // for json.decode
import 'package:flutter/material.dart';
import 'alarm.dart';
import 'alarm_popup.dart';
import 'api_service.dart';

void main() {
  runApp(const SunriseApp());
}

class SunriseApp extends StatelessWidget {
  const SunriseApp({super.key});

  @override
  Widget build(BuildContext context) {
    const backendUrl = "http://localhost:8080";
    return MaterialApp(
      title: 'Sunrise Light Alarm',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red, background: Colors.indigoAccent),
        useMaterial3: true,
      ),
      home: const MyHomePage(
        title: 'Sunrise Light Alarm',
        backendUrl: backendUrl,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title, required this.backendUrl});

  final String title;
  final String backendUrl;

  @override
  State<MyHomePage> createState() => _MyHomePageState(backendUrl: backendUrl);
}

class _MyHomePageState extends State<MyHomePage> {
  final ApiService apiService;

  _MyHomePageState({required String backendUrl})
      : apiService = ApiService(backendUrl);
  List<Alarm> alarms = [];

  @override
  void initState() {
    super.initState();
    _reloadAlarms(); // Load alarms when the widget is initialized
  }

  Future<void> _reloadAlarms() async {
    try {
      final List<Alarm> updatedAlarms = await apiService.getAlarms();
      setState(() {
        alarms = updatedAlarms;
      });
    } catch (error) {
      print(error);
    }
  }

  Future<void> _openAddAlarmPopup() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddAlarmPopup(apiService: apiService);
      },
    ).whenComplete(() async => await _reloadAlarms());
  }

  Future<void> _openEditAlarmPopup(
      BuildContext context, int alarmId, Alarm alarm) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddAlarmPopup(
            apiService: apiService,
            alarmId: alarmId,
            isEdit: true,
            inputAlarm: alarm);
      },
    ).whenComplete(() async => await _reloadAlarms());
  }

  Future<void> _toggleAlarmEnabled(int alarmId, bool isEnabled) async {
    final updatedAlarm = alarms[alarmId].copyWith(enabled: isEnabled);
    setState(() {
      alarms[alarmId] = updatedAlarm;
    });
    await apiService.updateAlarm(
      alarmId,
      updatedAlarm.timeOfDay,
      updatedAlarm.daysOfWeek,
      updatedAlarm.music,
      enabled: isEnabled,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: ListView.builder(
        itemCount: alarms.length,
        itemBuilder: (context, index) {
          final alarm = alarms[index];
          return ListTile(
            title: Row(
              children: [
                Checkbox(
                  value: alarm.enabled,
                  onChanged: (value) {
                    _toggleAlarmEnabled(index, value ?? false);
                    },
                ),
                GestureDetector(
                  onTap: () {
                    _openEditAlarmPopup(context, index, alarm);
                  },
                  child: Text(
                    '${alarm.timeOfDay} - ${alarm.daysOfWeek.join(', ')} - ${alarm.music}',
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddAlarmPopup,
        tooltip: 'Add Alarm',
        child: const Icon(Icons.alarm_add),
      ),
    );
  }
}
