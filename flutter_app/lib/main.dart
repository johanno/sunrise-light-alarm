// main.dart
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
    return MaterialApp(
      title: 'Sunrise Light Alarm',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red, background: Colors.indigoAccent),
        useMaterial3: true,
      ),
      home: const MyHomePage(
        title: 'Sunrise Light Alarm',
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final ApiService apiService;
  String backendUrl = ''; // Track changes in backend URL
  List<Alarm> alarms = [];
  List<String> musicList = [];

  @override
  void initState() {
    super.initState();
    _reloadAlarms(); // Load alarms when the widget is initialized
    _fetchAvailableMusic();
    apiService = ApiService();
    backendUrl = apiService.baseUrl;
  }

  Future<void> _saveUpdatedBackendUrl(String newUrl) async {
    // TODO: Implement logic to save the updated backend URL
    // For simplicity, we will directly update it in the widget for now
    setState(() {
      backendUrl = newUrl;
    });
    // Also update the ApiService with the new URL
    apiService.updateBaseUrl(newUrl);
  }

  void _showErrDialog(String errorText) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Error'),
        content: Text(errorText),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the alert
            },
            child: const Text('OK'),
          ),
        ],
      );
    });
  }

  void _openSettings(BuildContext context) {
    print("open settings");
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Settings'),
          content: Column(
            children: [
              const Text('Backend URL:'),
              TextField(
                onChanged: (value) {
                  setState(() {
                  backendUrl = value;
                  });
                  },
                controller: TextEditingController(text: backendUrl),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the settings dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // Save the updated backend URL
                if (backendUrl.isNotEmpty) {
                  await _saveUpdatedBackendUrl(backendUrl);
                }
                Navigator.of(context).pop(); // Close the settings dialog
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAlarm(int alarmId) async {
    // Display confirmation dialog
    bool confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this alarm?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Cancel delete
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Confirm delete
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirmDelete) {
      try {
        await apiService.deleteAlarm(alarmId);
        await _reloadAlarms();
      } catch (error) {
        print('Error deleting alarm: $error');
        // Handle error or show error dialog
        _showErrDialog('Failed to delete alarm. Please try again.');
      }
    }
  }

  Future<void> _reloadAlarms() async {
    try {
      final List<Alarm> updatedAlarms = await apiService.getAlarms();
      setState(() {
        alarms = updatedAlarms;
      });
    } catch (error) {
      print('Error fetching alarms: $error');
      _showErrDialog('Failed to fetch alarms. Please try again.');
    }
  }

  Future<void> _fetchAvailableMusic() async {
    try {
      final List<String> musicList = await apiService.getMusicList();
      setState(() {
        this.musicList = musicList;
      });
    } catch (error) {
      print('Error fetching available music: $error');
      _showErrDialog("Failed to fetch available music. Please try again.");
      rethrow;
    }
  }

  Future<void> _openAddAlarmPopup(BuildContext context) async {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AddAlarmPopup(apiService: apiService, musicList: musicList);
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
            inputAlarm: alarm, musicList: musicList);
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
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () async {
              await _reloadAlarms();
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              _openSettings(context);
            },
          ),
        ],
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
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    _deleteAlarm(index);
                  },
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddAlarmPopup(context),
        tooltip: 'Add Alarm',
        child: const Icon(Icons.alarm_add),
      ),
    );
  }
}
