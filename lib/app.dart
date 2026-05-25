import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'theme/clay_colors.dart'; // 黏土主题颜色
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
      systemNavigationBarColor: clayBg,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarDividerColor: clayBg,
      systemNavigationBarContrastEnforced: false, // 禁止系统在导航栏叠加对比度遮罩（根因：Bug3 底部到不了边）
    ));

    return MaterialApp(
      title: '差旅日历',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: clayPurple,
          brightness: Brightness.light,
          surface: claySurface,
          primary: clayPurple,
          onPrimary: Colors.white,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: clayBg,
        fontFamily: 'Roboto',
        cardTheme: CardThemeData(
          elevation: 0, // 阴影由 ClayContainer 接管
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(clayRadius)),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.transparent,
          foregroundColor: clayTextPrimary,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: clayPurple,
          foregroundColor: Colors.white,
          elevation: 0, // 阴影由 ClayContainer 接管
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: InputBorder.none,
          hintStyle: TextStyle(color: clayTextTertiary, fontSize: 13),
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.all(clayPurple),
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
        resizeToAvoidBottomInset: false, // 键盘弹起时不收缩 Scaffold，避免对话框背景出现"安全条纹"
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
                    decoration: const BoxDecoration(color: clayPurple, shape: BoxShape.circle),
                    child: Text('$unreadCount', style: const TextStyle(color: Colors.white, fontSize: 10)),
                  )),
              ],
            ),
            IconButton(
              icon: Icon(Icons.event_note, color: viewMode == ViewMode.year ? clayPurple : null),
              onPressed: () => context.read<CalendarProvider>().setViewMode(ViewMode.year),
            ),
            IconButton(
              icon: Icon(Icons.calendar_month, color: viewMode == ViewMode.month ? clayPurple : null),
              onPressed: () => context.read<CalendarProvider>().setViewMode(ViewMode.month),
            ),
          ],
        ),
        body: SafeArea(
          top: false,  // AppBar 自己处理顶部安全区
          bottom: false, // extendBody:true 已让内容延伸到底部，此处不设底部 padding
          child: Container(
            color: clayBg, // edgeToEdge 下填充导航栏背景色
            child: viewMode == ViewMode.year ? const YearView() : const MonthView(),
          ),
        ),
      ),
    );
  }
}
