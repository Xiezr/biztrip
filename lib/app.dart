import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/calendar_provider.dart';
import 'providers/mark_provider.dart';
import 'providers/location_provider.dart';
import 'services/notification_service.dart';
import 'screens/year_view.dart';
import 'screens/month_view.dart';
import 'screens/notification_list_page.dart';

class BizTripApp extends StatelessWidget {
  const BizTripApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '差旅日历',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A56DB),
          brightness: Brightness.light,
          surface: const Color(0xFFF8FAFC),
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
        cardTheme: CardThemeData(
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.transparent,
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _initialEvalDone = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialEvalDone) {
      _initialEvalDone = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _evalNow());
    }
  }

  void _evalNow() {
    final m = context.read<MarkProvider>().marks;
    final locMap = {for (final l in context.read<LocationProvider>().locations) l.id!: l};
    context.read<NotificationService>().evaluate(marks: m, locationMap: locMap);
  }

  @override
  Widget build(BuildContext context) {
    final calendarProvider = context.watch<CalendarProvider>();
    final notifService = context.watch<NotificationService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('差旅日历'),
        centerTitle: true,
        elevation: 0,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  _evalNow();
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationListPage()));
                },
              ),
              if (notifService.unreadCount > 0)
                Positioned(right: 6, top: 6, child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  child: Text('${notifService.unreadCount}', style: const TextStyle(color: Colors.white, fontSize: 10)),
                )),
            ],
          ),
          IconButton(
            icon: Icon(Icons.event_note, color: calendarProvider.viewMode == ViewMode.year ? Theme.of(context).colorScheme.primary : null),
            onPressed: () => calendarProvider.setViewMode(ViewMode.year),
          ),
          IconButton(
            icon: Icon(Icons.calendar_month, color: calendarProvider.viewMode == ViewMode.month ? Theme.of(context).colorScheme.primary : null),
            onPressed: () => calendarProvider.setViewMode(ViewMode.month),
          ),
        ],
      ),
      body: calendarProvider.viewMode == ViewMode.year ? const YearView() : const MonthView(),
    );
  }
}
