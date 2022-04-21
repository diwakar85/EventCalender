import 'package:event_calender/notifaction/notifaction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  await NotificationsApi.init();
  NotificationsApi.oNnotifications;
  NotificationsApi.notificationsDetails();
  initializeDateFormatting().then((_) => runApp(const GetMaterialApp(
        debugShowCheckedModeBanner: false,
        home: MyApp(),
      )));
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  CalendarFormat format = CalendarFormat.week;
  DateTime selectedDate = DateTime.now();
  late Map<String, List<String>> arrSelectedEvents = {};
  List<String> arrEvents = [];
  TimeOfDay selectedTime = TimeOfDay.now();
  List selectedEventDates(DateTime date) {
    String day = DateFormat("yyyy-MM-dd").format(date);
    return arrSelectedEvents[day] ?? [];
  }

  TextEditingController controller = TextEditingController();
  @override
  void initState() {
    super.initState();
    fetchAllEvents();
    onlistionNotifaction();
  }

  onlistionNotifaction() {
    NotificationsApi.oNnotifications.stream.listen((event) {
      "hello";
    });
  }

  RefreshController refreshController =
      RefreshController(initialRefresh: false);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Calendar Weekly"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 0,
            child: TableCalendar(
              focusedDay: selectedDate,
              firstDay: DateTime(2000),
              lastDay: DateTime(2030),
              calendarFormat: format,
              startingDayOfWeek: StartingDayOfWeek.sunday,
              daysOfWeekVisible: true,
              onFormatChanged: (CalendarFormat _format) {
                setState(() {
                  format = _format;
                });
              },
              onDaySelected: (selectDay, focusDay) {
                setState(() {
                  selectedDate = selectDay;
                  getEvents(selectedDate);
                });
              },
              selectedDayPredicate: (date) {
                return isSameDay(selectedDate, date);
              },
              eventLoader: selectedEventDates,
            ),
          ),
          Expanded(
            child: ListView.builder(
                padding: const EdgeInsets.only(left: 5, right: 100),
                shrinkWrap: true,
                itemCount: arrEvents.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Container(
                      alignment: Alignment.center,
                      height: MediaQuery.of(context).size.height / 15,
                      width: MediaQuery.of(context).size.width / 2,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          color: Colors.white24,
                          border: Border.all(color: Colors.redAccent)),
                      child: Column(
                        children: [
                          Text(
                            arrEvents[index],
                            style: const TextStyle(
                                color: Colors.blue,
                                fontSize: 20,
                                fontWeight: FontWeight.bold),
                          ),
                          Text("$selectedTime"),
                        ],
                      ),
                    ),
                  );
                }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Add Event"),
            content: Column(
              children: [
                TextFormField(
                  controller: controller,
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () {
                    selectTime(context);
                  },
                  child: const Text("Set the Time")
              ),
              TextButton(
                  child: const Text("Cancel"),
                  onPressed: () {
                    Navigator.pop(context);
                  }),
              TextButton(
                child: const Text("Done"),
                onPressed: () async {
                  if (controller.text.isNotEmpty) {
                    saveEvent(date: selectedDate, eventName: controller.text);
                    Navigator.pop(context);
                    return;
                  } else {
                    //Alert Message
                  }
                },
              ),
            ],
          ),
        ),
        label: const Text("Add Event"),
        icon: const Icon(Icons.add),
      ),
    );
  }

  String? key;
  String? time;
  fetchAllEvents() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> arrEventDates = prefs.getStringList("eventDates") ?? [];
    for (String eventDay in arrEventDates) {
      List<String> dayEvents = prefs.getStringList(eventDay) ?? [];
      arrSelectedEvents[eventDay] = dayEvents;
    }
    getEvents(selectedDate);
  }

  getEvents(DateTime date) async {
    String day = DateFormat("yyyy-MM-dd").format(date);
    arrEvents = arrSelectedEvents[day] ?? [];
    setState(() {});
  }

  saveEvent({required DateTime date, required String eventName}) async {
    String day = DateFormat("yyyy-MM-dd").format(date);
    final prefs = await SharedPreferences.getInstance();
    List<String> listEvents = prefs.getStringList(day) ?? [];
    listEvents.add(eventName);
    prefs.setStringList(day, listEvents);
    controller.clear();

    //Notification Date
    DateTime notificationDate = DateFormat("yyyy-MM-dd").parse(day);
    notificationDate = notificationDate.add(Duration(hours: selectedTime.hour, minutes: selectedTime.minute));

    //message Alert
    NotificationsApi.showSchedulNotifaction(
        title: eventName,
        body: "today is holiday",
        scheduleDate: notificationDate);
    //All Dates
    List<String> listDates = prefs.getStringList("eventDates") ?? [];
    if (!listDates.contains(day)) {
      listDates.add(day);
    }
    prefs.setStringList("eventDates", listDates);

    //Refresh All Events
    fetchAllEvents();
  }

  selectTime(BuildContext context) async {
    final TimeOfDay? timeOfDay = await showTimePicker(
      context: context,
      initialTime: selectedTime,
      initialEntryMode: TimePickerEntryMode.dial,
    );
    if (timeOfDay != null && timeOfDay != selectedTime) {
      setState(() {
        selectedTime = timeOfDay;
        print("Time=$selectedTime");
      });
    }
  }
}
