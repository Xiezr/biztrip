import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    // 启用边到边显示
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    // 设置系统导航栏全透明，让 Scaffold 背景色自然填充到底
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
    ));

    return MaterialApp(
      title: '差旅日历',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF007AFF),
          brightness: Brightness.light,
          surface: const Color(0xFFF9F5F0),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF9F5F0),
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
    final viewMode = context.select<CalendarProvider, ViewMode>((p) => p.viewMode);
    final unreadCount = context.select<NotificationService, int>((n) => n.unreadCount);

    // 用 PopScope 拦截返回键：退到桌面而非退出进程
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          SystemNavigator.pop(); // 退回桌面（不杀进程）
        }
      },
      child: Scaffold(
        extendBody: true, // 内容延伸到屏幕底部（圆角屏适配）
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
                if (unreadCount > 0)
                  Positioned(right: 6, top: 6, child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: Text('$unreadCount', style: const TextStyle(color: Colors.white, fontSize: 10)),
                  )),
              ],
            ),
            IconButton(
              icon: Icon(Icons.event_note, color: viewMode == ViewMode.year ? Theme.of(context).colorScheme.primary : null),
              onPressed: () => context.read<CalendarProvider>().setViewMode(ViewMode.year),
            ),
            IconButton(
              icon: Icon(Icons.calendar_month, color: viewMode == ViewMode.month ? Theme.of(context).colorScheme.primary : null),
              onPressed: () => context.read<CalendarProvider>().setViewMode(ViewMode.month),
            ),
          ],
        ),
        body: SafeArea(
          top: false,  // AppBar 自己处理顶部安全区
          bottom: true, // 底部留出导航栏空间
          child: viewMode == ViewMode.year ? const YearView() : const MonthView(),
        ),
      ),
    );
  }
}
