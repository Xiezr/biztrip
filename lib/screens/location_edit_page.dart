import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/clay_colors.dart';
import '../theme/clay_container.dart';
import '../theme/clay_input.dart';
import '../models/travel_location.dart';
import '../providers/location_provider.dart';
import '../providers/mark_provider.dart';
import '../widgets/color_family_picker.dart';
import '../widgets/day_field.dart';

class _ReminderItem {
  final String label;
  final int value;
  final bool isBefore;
  const _ReminderItem(this.label, this.value, this.isBefore);
  _ReminderItem copyWith({int? value}) => _ReminderItem(label, value ?? this.value, isBefore);
}

class LocationEditPage extends StatefulWidget {
  final int locationId;
  final int? viewYear;
  final int? viewMonth;
  const LocationEditPage({super.key, required this.locationId, this.viewYear, this.viewMonth});

  @override
  State<LocationEditPage> createState() => _LocationEditPageState();
}

class _LocationEditPageState extends State<LocationEditPage> {
  late TextEditingController _nameCtrl;
  late TextEditingController _tagCtrl;
  late List<_ReminderItem> _reminderItems;
  late List<String> _tags;
  late List<TextEditingController> _reminderCtrls;
  late List<String> _invoicePaths;
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    final loc = context.read<LocationProvider>().getById(widget.locationId)!;
    _nameCtrl = TextEditingController(text: loc.name);
    _tagCtrl = TextEditingController();
    _reminderItems = [
      _ReminderItem('差旅通知', -loc.notificationDaysBefore, true),
      _ReminderItem('差旅确认', -loc.confirmationDaysBefore, true),
      _ReminderItem('差旅跟进', loc.followUpDaysAfter, false),
      _ReminderItem('差旅报告', loc.reportDaysAfter, false),
      _ReminderItem('票据报销', loc.reimbursementDaysAfter, false),
    ];
    _tags = List.from(loc.preparationTags);
    _reminderCtrls = loc.specialReminder.map((s) => TextEditingController(text: s)).toList();
    _invoicePaths = List.from(loc.invoicePaths);
    _selectedColor = loc.color;
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _tagCtrl.dispose();
    for (final c in _reminderCtrls) { c.dispose(); }
    super.dispose();
  }

  List<(int, _ReminderItem)> _sortedWithIndex() {
    final indexed = _reminderItems.asMap().entries.toList()
      ..sort((a, b) => a.value.value.compareTo(b.value.value));
    return indexed.map((e) => (e.key, e.value)).toList();
  }

  void _save() {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入地点名称')));
      return;
    }
    int val(String label) {
      return _reminderItems.firstWhere((r) => r.label == label, orElse: () => _ReminderItem(label, 0, true)).value;
    }
    context.read<LocationProvider>().updateLocationFull(
      widget.locationId,
      name: _nameCtrl.text.trim(), color: _selectedColor,
      notificationDaysBefore: val('差旅通知').abs(), followUpDaysAfter: val('差旅跟进'),
      preparationTags: _tags, reimbursementDaysAfter: val('票据报销'),
      confirmationDaysBefore: val('差旅确认').abs(), reportDaysAfter: val('差旅报告'),
      specialReminder: _reminderCtrls.map((c) => c.text.trim()).toList(),
      invoicePaths: _invoicePaths,
    );
    Navigator.pop(context);
  }

  Future<void> _captureInvoice() async {
    try {
      const platform = MethodChannel('com.biztrip.biztrip/camera');
      final name = _nameCtrl.text.trim().isNotEmpty ? _nameCtrl.text.trim() : '未知';
      final seq = _invoicePaths.length + 1;
      final path = await platform.invokeMethod<String>('capturePhoto', {
        'locationName': name,
        'sequence': seq,
      });
      if (path != null && mounted) {
        setState(() => _invoicePaths.add(path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('拍照失败，请确认已授权相机权限。错误详情：$e')),
        );
      }
    }
  }

  void _showDayPicker(String label, int current, bool isBefore, ValueChanged<int> onChange) {
    int temp = current;
    final manualCtrl = TextEditingController(text: '$current');
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDState) {
        return AlertDialog(
          backgroundColor: clayBg,
          title: Text(label),
          content: SizedBox(
            width: 220,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: () => setDState(() {
                        temp = (temp - 1).clamp(-365, 365);
                        manualCtrl.text = '$temp';
                      }),
                    ),
                    SizedBox(
                      width: 70,
                      child: ClayTextField(
                        controller: manualCtrl,
                        hintText: '天数',
                        onChanged: (v) {
                          final parsed = int.tryParse(v);
                          if (parsed != null) setDState(() => temp = parsed.clamp(-365, 365));
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => setDState(() {
                        temp = (temp + 1).clamp(-365, 365);
                        manualCtrl.text = '$temp';
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('-365 ~ 365 天', style: TextStyle(fontSize: 11, color: clayTextTertiary)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            TextButton(onPressed: () { onChange(temp); Navigator.pop(ctx); }, child: const Text('确定')),
          ],
        );
      }),
    );
  }

  void _showAddReminderDialog(BuildContext context) {
    final customCtrl = TextEditingController();
    final presetOptions = ['差旅通知', '差旅确认', '差旅跟进', '差旅报告', '票据报销'];
    final available = presetOptions.where((o) => !_reminderItems.any((r) => r.label == o)).toList();

    void addReminder(String label) {
      final trimmed = label.trim();
      if (trimmed.isEmpty) return;
      if (trimmed.length > 10) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('标签不超过10个字')));
        return;
      }
      setState(() {
        int defaultVal(String label) {
          if (label.contains('通知')) return -7;
          if (label.contains('确认')) return -3;
          if (label.contains('跟进')) return 3;
          if (label.contains('报告')) return 7;
          if (label.contains('报销')) return 5;
          return 7;
        }
        _reminderItems.add(_ReminderItem(trimmed, defaultVal(trimmed), trimmed.contains('通知') || trimmed.contains('确认')));
      });
      Navigator.pop(context);
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: clayBg,
        title: const Text('添加提醒'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (available.isNotEmpty) ...[
                Text('预设有', style: TextStyle(fontSize: 11, color: clayTextSecondary)),
                const SizedBox(height: 4),
                Wrap(spacing: 6, children: available.map((o) => ClayChip(
                  label: o,
                  onTap: () => addReminder(o),
                )).toList()),
                const Divider(height: 16),
              ],
              Text('自定义（不超过10字）', style: TextStyle(fontSize: 11, color: clayTextSecondary)),
              const SizedBox(height: 4),
              ClayTextField(
                controller: customCtrl,
                hintText: '输入提醒名称',
                onChanged: (_) {},
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(onPressed: () => addReminder(customCtrl.text), child: const Text('添加')),
        ],
      ),
    );
  }

  void _showAddTagDialog(BuildContext context) {
    final manualCtrl = TextEditingController();
    final allTags = <String>{};
    for (final loc in context.read<LocationProvider>().locations) {
      allTags.addAll(loc.preparationTags);
    }
    final archived = allTags.difference(_tags.toSet()).toList()..sort();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: clayBg,
        title: const Text('添加标签'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (archived.isNotEmpty) ...[
                Text('已存档标签', style: TextStyle(fontSize: 12, color: clayTextSecondary)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6, runSpacing: 4,
                  children: archived.map((t) => ClayChip(
                    label: t,
                    onTap: () {
                      setState(() => _tags.add(t));
                      Navigator.pop(ctx);
                    },
                  )).toList(),
                ),
                const Divider(height: 16),
              ],
              Text('手动添加', style: TextStyle(fontSize: 12, color: clayTextSecondary)),
              const SizedBox(height: 6),
              ClayTextField(
                controller: manualCtrl,
                hintText: '输入新标签',
                onChanged: (_) {},
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () {
              if (manualCtrl.text.trim().isNotEmpty) {
                setState(() => _tags.add(manualCtrl.text.trim()));
                Navigator.pop(ctx);
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_nameCtrl.text.isEmpty ? '目的地设置' : _nameCtrl.text),
        actions: [IconButton(icon: const Icon(Icons.check), onPressed: _save)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClayTextField(controller: _nameCtrl, hintText: '输入地点名称', onChanged: (_) {}),
          const SizedBox(height: 20),

          // 颜色选择
          Text('颜色', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: clayTextPrimary)),
          const SizedBox(height: 8),
          ColorFamilyPicker(selected: _selectedColor, onChanged: (c) => setState(() => _selectedColor = c)),
          const SizedBox(height: 20),

          // 提醒事项
          Row(children: [
            Text('提醒事项', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: clayTextPrimary)),
            const Spacer(),
            ClayIconButton(icon: Icons.add_circle_outline, size: 28, onPressed: () => _showAddReminderDialog(context)),
          ]),
          const SizedBox(height: 8),
          ..._sortedWithIndex().map((pair) {
            final i = pair.$1;
            final item = pair.$2;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: ClayCard(
                padding: EdgeInsets.zero,
                margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 3),
                child: Row(
                  children: [
                    Container(width: 4, height: 44, decoration: BoxDecoration(
                      color: item.value < 0 ? clayPurple : clayWarning,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(clayRadius),
                        bottomLeft: Radius.circular(clayRadius),
                      ),
                    )),
                    ReorderableDragStartListener(index: i, child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(Icons.drag_indicator, size: 18, color: clayTextTertiary),
                    )),
                    Expanded(
                      child: DayField(
                        label: item.label, value: item.value, isBefore: item.isBefore,
                        onTap: () => _showDayPicker(item.label, item.value, item.isBefore, (v) {
                          setState(() => _reminderItems[i] = _reminderItems[i].copyWith(value: v));
                        }),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16, color: clayError),
                      onPressed: _reminderItems.length > 1 ? () => setState(() => _reminderItems.removeAt(i)) : null,
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 12),

          // 差旅准备
          Row(children: [
            Text('差旅准备', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: clayTextPrimary)),
            const Spacer(),
            ClayIconButton(icon: Icons.add_circle_outline, size: 28, onPressed: () => _showAddTagDialog(context)),
          ]),
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 6, children: [
            ..._tags.map((t) => ClayChip(
              label: t,
              color: clayCream, // 暖奶油 — 差旅标签背景
              trailing: GestureDetector(
                onTap: () => setState(() => _tags.remove(t)),
                child: const Icon(Icons.close, size: 14, color: clayTextTertiary),
              ),
            )),
          ]),
          const SizedBox(height: 20),

          // 本次差旅特别提醒
          Row(children: [
            Text('本次差旅特别提醒', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: clayTextPrimary)),
            const Spacer(),
            ClayIconButton(icon: Icons.add_circle_outline, size: 28, onPressed: () => setState(() => _reminderCtrls.add(TextEditingController()))),
          ]),
          ...List.generate(_reminderCtrls.length, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: ClayCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 3),
              child: Row(children: [
                SizedBox(width: 20, child: Text('${i + 1}.', style: TextStyle(color: clayTextTertiary, fontSize: 13))),
                Expanded(child: ClayTextField(
                  controller: _reminderCtrls[i],
                  hintText: '第${i + 1}行',
                  onChanged: (_) {},
                )),
                IconButton(
                  icon: const Icon(Icons.close, size: 16, color: clayError),
                  onPressed: _reminderCtrls.length > 1 ? () { setState(() { _reminderCtrls[i].dispose(); _reminderCtrls.removeAt(i); }); } : null,
                ),
              ]),
            ),
          )),
          const SizedBox(height: 24),

          // 单据扫描
          Row(children: [
            Text('单据扫描', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: clayTextPrimary)),
            const Spacer(),
            ClayIconButton(icon: Icons.add_circle_outline, size: 28, onPressed: () => _captureInvoice()),
          ]),
          const SizedBox(height: 4),
          Text('本次差旅的费用及发票', style: TextStyle(fontSize: 13, color: clayTextSecondary)),
          const SizedBox(height: 8),
          if (_invoicePaths.isEmpty)
            ClayCard(
              padding: const EdgeInsets.all(12),
              child: const Center(child: Text('暂无单据', style: TextStyle(fontSize: 13, color: clayTextTertiary))),
            )
          else
            Wrap(spacing: 6, runSpacing: 6, children: _invoicePaths.asMap().entries.map((e) {
              final idx = e.key;
              final path = e.value;
              final name = path.split('/').last;
              return ClayChip(
                label: name,
                color: clayInvoiceBg, // 冷蓝灰 — 与暖色标签区分
                trailing: GestureDetector(
                  onTap: () => setState(() => _invoicePaths.removeAt(idx)),
                  child: const Icon(Icons.close, size: 14, color: clayWarning),
                ),
              );
            }).toList()),
          const SizedBox(height: 16),

          // 删除选项
          Text('删除目的地', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: clayTextPrimary)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.visibility_off, size: 16),
                  label: const Text('临时删除', style: TextStyle(fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: clayWarning,
                    side: const BorderSide(color: clayWarning),
                  ),
                  onPressed: () async {
                    final locProvider = context.read<LocationProvider>();
                    final markProvider = context.read<MarkProvider>();
                    final loc = locProvider.getById(widget.locationId);
                    // 清除当前月份的所有标注
                    if (widget.viewYear != null && widget.viewMonth != null) {
                      await markProvider.removeMarksForMonth(widget.locationId, widget.viewYear!, widget.viewMonth!);
                    }
                    // 全局目的地还需清除未来月份标注
                    if (loc?.scope == LocationScope.global) {
                      await markProvider.removeFutureMarks(widget.locationId);
                    }
                    if (!mounted) return;
                    locProvider.tempDeleteLocation(widget.locationId);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('已临时删除，配置已保存')),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.delete_forever, size: 16),
                  label: const Text('永久删除', style: TextStyle(fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: clayError,
                    side: const BorderSide(color: clayError),
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: clayBg,
                        title: const Text('确认删除'),
                        content: const Text('永久删除后将无法恢复，但历史差旅记录将保留'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
                          TextButton(
                            onPressed: () async {
                              final markProvider = context.read<MarkProvider>();
                              await markProvider.removeFutureMarks(widget.locationId);
                              if (!mounted) return;
                              context.read<LocationProvider>().permDeleteLocation(widget.locationId);
                              Navigator.pop(ctx);
                              Navigator.pop(context);
                            },
                            child: const Text('确认删除', style: TextStyle(color: clayError)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
