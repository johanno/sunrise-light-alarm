import 'package:flutter/material.dart';
import 'alarm.dart';
import 'api_service.dart';

class AddAlarmPopup extends StatefulWidget {
  final ApiService apiService;
  final bool isEdit;
  final int alarmId;
  final Alarm? inputAlarm;

  AddAlarmPopup(
      {required this.apiService,
      this.alarmId = -1,
      this.isEdit = false,
      this.inputAlarm});

  @override
  _AddAlarmPopupState createState() => _AddAlarmPopupState();
}

class _AddAlarmPopupState extends State<AddAlarmPopup> {
  TimeOfDay selectedTime = TimeOfDay.now();
  Set<String> selectedDays = {};
  String selectedMusic = 'Default Music';

  @override
  Widget build(BuildContext context) {
    if (widget.inputAlarm != null) {
      Alarm inputAlarm = widget.inputAlarm as Alarm;
      var timelist = inputAlarm.timeOfDay.split(":");
      int hours = int.parse(timelist.first);
      int minutes = int.parse(timelist.last);
      setState(() {
        selectedTime = TimeOfDay(hour: hours, minute: minutes);
        selectedDays = inputAlarm.daysOfWeek;
        selectedMusic = inputAlarm.music;
      });
    }
    return AlertDialog(
      title: const Text('Add Alarm'),
      content: StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  title: const Text('Select Time'),
                  subtitle: Text(selectedTime.format(context)),
                  onTap: () async {
                    final TimeOfDay? pickedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay(
                        hour: selectedTime.hour,
                        minute: selectedTime.minute,
                      ),
                      builder:(BuildContext context, Widget? child) {
                        return MediaQuery(
                          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                          child: child!,
                        );
                      }
                    );
                    if (pickedTime != null && pickedTime != selectedTime) {
                      setState(() {
                        selectedTime = pickedTime;
                      });
                    }
                  },
                ),
                const Divider(),
                ListTile(
                  title: const Text('Select Days of the Week'),
                  subtitle: Text(
                      selectedDays.where((day) => day.isNotEmpty).join(', ')),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        // Local variable to track selected days
                        Set<String> localSelectedDays = Set.from(selectedDays);
                        return AlertDialog(
                          title: const Text('Select Days of the Week'),
                          content: StatefulBuilder(
                            builder:
                                (BuildContext context, StateSetter setState) {
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: List.generate(7, (index) {
                                  final dayName = getDayName(index);
                                  return CheckboxListTile(
                                    title: Text(dayName),
                                    value: localSelectedDays.contains(dayName),
                                    onChanged: (value) {
                                      setState(() {
                                        if (value!) {
                                          localSelectedDays.add(dayName);
                                        } else {
                                          localSelectedDays.remove(dayName);
                                        }
                                      });
                                    },
                                  );
                                }),
                              );
                            },
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                // Sort the selected days before updating the state
                                var list = localSelectedDays.toList();
                                list.sort((a, b) =>
                                    getDayIndex(a).compareTo(getDayIndex(b)));
                                // Update the selectedDays state after "Done" is clicked
                                setState(() {
                                  selectedDays = Set.from(list);
                                });
                                Navigator.of(context).pop();
                              },
                              child: const Text('Done'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  title: const Text('Select Music'),
                  subtitle: Text(selectedMusic),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('Select Music'),
                          content: DropdownButton<String>(
                            value: selectedMusic,
                            onChanged: (value) {
                              setState(() {
                                selectedMusic = value!;
                              });
                              Navigator.of(context).pop();
                            },
                            items: ['Default Music', 'Music 1', 'Music 2']
                                .map((music) => DropdownMenuItem<String>(
                                      value: music,
                                      child: Text(music),
                                    ))
                                .toList(),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () {
            if (widget.isEdit) {
              widget.apiService.updateAlarm(
                widget.alarmId,
                selectedTime.format(context),
                selectedDays,
                selectedMusic,
              );
            } else {
              // Implement logic to add the alarm
              widget.apiService.addAlarm(
                selectedTime.format(context),
                selectedDays,
                selectedMusic,
              );
            }
            Navigator.of(context).pop();
          },
          child: const Text('OK'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  final daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  String getDayName(int dayIndex) {
    return daysOfWeek[dayIndex];
  }

  int getDayIndex(String dayName) {
    return daysOfWeek.indexOf(dayName);
  }
}
