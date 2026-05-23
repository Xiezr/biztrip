import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'providers/calendar_provider.dart';
import 'providers/location_provider.dart';
import 'providers/mark_provider.dart';
import 'services/notification_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CalendarProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()..load()),
        ChangeNotifierProvider(create: (_) => MarkProvider()..load()),
        ChangeNotifierProvider(create: (_) => NotificationService()),
      ],
      child: const BizTripApp(),
    ),
  );
}
