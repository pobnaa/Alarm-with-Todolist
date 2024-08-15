import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alarm & To-Do List',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeScreen(),
    );
  }
}

class ToDoItem {
  String task;
  DateTime? time;

  ToDoItem({required this.task, this.time});
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ToDoItem> toDoList = [];
  List<DateTime> alarmList = [];

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    initializeNotifications();
  }

  void initializeNotifications() async {
    tz.initializeTimeZones();
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('app_icon');
    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> scheduleAlarm(DateTime scheduledNotificationDateTime) async {
    var androidPlatformChannelSpecifics = const AndroidNotificationDetails(
      'alarm_channel',
      'Alarm Channel',
      channelDescription: 'Channel for Alarm notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('alarm_sound'),
    );

    var platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      'Alarm',
      'Your alarm is ringing!',
      tz.TZDateTime.from(scheduledNotificationDateTime, tz.local),
      platformChannelSpecifics,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  void _addToDoItem(ToDoItem item) {
    setState(() {
      toDoList.add(item);
    });
  }

  void _deleteToDoItem(int index) {
    setState(() {
      toDoList.removeAt(index);
    });
  }

  void _addAlarm(DateTime dateTime) {
    setState(() {
      alarmList.add(dateTime);
      scheduleAlarm(dateTime);
    });
  }

  void _deleteAlarm(int index) {
    setState(() {
      alarmList.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Alarm & To-Do List'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.alarm), text: 'Alarm'),
            Tab(icon: Icon(Icons.list), text: 'To-Do List'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          AlarmPage(
            alarmList: alarmList,
            addAlarm: _addAlarm,
            deleteAlarm: _deleteAlarm,
          ),
          ToDoListPage(
            toDoList: toDoList,
            addToDoItem: _addToDoItem,
            deleteToDoItem: _deleteToDoItem,
          ),
        ],
      ),
    );
  }
}

class AlarmPage extends StatefulWidget {
  final List<DateTime> alarmList;
  final Function(DateTime) addAlarm;
  final Function(int) deleteAlarm;

  AlarmPage({
    required this.alarmList,
    required this.addAlarm,
    required this.deleteAlarm,
  });

  @override
  _AlarmPageState createState() => _AlarmPageState();
}

class _AlarmPageState extends State<AlarmPage> {
  TimeOfDay? _selectedTime;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () async {
              final TimeOfDay? time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );
              if (time != null) {
                final now = DateTime.now();
                final selectedDateTime = DateTime(
                  now.year,
                  now.month,
                  now.day,
                  time.hour,
                  time.minute,
                );
                widget.addAlarm(selectedDateTime);
                setState(() {
                  _selectedTime = time;
                });
              }
            },
            child: Text('Select Time & Set Alarm'),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: widget.alarmList.length,
            itemBuilder: (context, index) {
              final alarm = widget.alarmList[index];
              return ListTile(
                title: Text('${alarm.hour}:${alarm.minute}'),
                trailing: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () => widget.deleteAlarm(index),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class ToDoListPage extends StatelessWidget {
  final List<ToDoItem> toDoList;
  final Function(ToDoItem) addToDoItem;
  final Function(int) deleteToDoItem;

  ToDoListPage({
    required this.toDoList,
    required this.addToDoItem,
    required this.deleteToDoItem,
  });

  @override
  Widget build(BuildContext context) {
    TextEditingController _controller = TextEditingController();
    TimeOfDay? _selectedTime;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: 'Add a task',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            TimeOfDay? timeOfDay = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.now(),
            );
            if (timeOfDay != null) {
              _selectedTime = timeOfDay;
            }
          },
          child: Text('Pick Time'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_controller.text.isNotEmpty) {
              final now = DateTime.now();
              final selectedDateTime = DateTime(
                now.year,
                now.month,
                now.day,
                _selectedTime?.hour ?? now.hour,
                _selectedTime?.minute ?? now.minute,
              );
              addToDoItem(ToDoItem(task: _controller.text, time: selectedDateTime));
              _controller.clear();
            }
          },
          child: Text('Add'),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: toDoList.length,
            itemBuilder: (context, index) {
              final item = toDoList[index];
              return ListTile(
                title: Text(item.task),
                subtitle: item.time != null ? Text('${item.time!.hour}:${item.time!.minute}') : null,
                trailing: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () => deleteToDoItem(index),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
