import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:rxdart/rxdart.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_native_timezone/flutter_native_timezone.dart';

class NotificationsApi {
  static final _notifications = FlutterLocalNotificationsPlugin();
  static final oNnotifications = BehaviorSubject<String?>();

  static Future notificationsDetails() async {
    return   const NotificationDetails(
        android: AndroidNotificationDetails(
          "channel id",
          "channel name",
          importance: Importance.max,
          color: Colors.redAccent,
          subText: "to is holiday Enjoy of the Day",
          playSound: true,
        ),
        iOS: IOSNotificationDetails());
  }

  static Future init({bool initScheduled = false}) async {
    AndroidInitializationSettings android = const AndroidInitializationSettings("@mipmap/ic_launcher");
    IOSInitializationSettings iso = const IOSInitializationSettings();
    InitializationSettings setting = InitializationSettings(android: android, iOS: iso);
    await _notifications.initialize(setting, onSelectNotification: (payload) {
      oNnotifications.add(payload);
    }
    );
    if(initScheduled){
      tz.initializeTimeZones();
      final locationName=await FlutterNativeTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(locationName));
    }
  }

  static void showSchedulNotifaction(
          {int id = 0,
          String? title,
          String? body,
          String? payload,
          required DateTime scheduleDate}) async {
    print("currentdate:$scheduleDate");
    _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduleDate, tz.local),
      await notificationsDetails(),
      payload: payload,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation
          .absoluteTime,
      androidAllowWhileIdle: true,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}


