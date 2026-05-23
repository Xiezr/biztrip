import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/travel_location.dart';
import '../providers/location_provider.dart';

class _ReminderItem {
  final String label;
  final int value;
  final bool isBefore;
  const _ReminderItem(this.label, this.value, this.isBefore);
  _ReminderItem copyWith({int? value}) => _ReminderItem(label, value ?? this.value, isBefore);
}

class LocationEditPage extends StatefulWidget {
  final int locationId;
  const LocationEditPage({super.key, required this.locationId});

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
      _ReminderItem('差旅通知', loc.notificationDaysBefore, true),
      _ReminderItem('差旅确认', loc.confirmationDaysBefore, true),
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
      ..sort((a, b) => (a.value.isBefore ? -a.value.value : a.value.value)
          .compareTo(b.value.isBefore ? -b.value.value : b.value.value));
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
      notificationDaysBefore: val('差旅通知'), followUpDaysAfter: val('差旅跟进'),
      preparationTags: _tags, reimbursementDaysAfter: val('票据报销'),
      confirmationDaysBefore: val('差旅确认'), reportDaysAfter: val('差旅报告'),
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('拍照失败: $e')));
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
                        temp = (temp - 1).clamp(0, 365);
                        manualCtrl.text = '$temp';
                      }),
                    ),
                    SizedBox(
                      width: 70,
                      child: TextField(
                        controller: manualCtrl,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(vertical: 8)),
                        onChanged: (v) {
                          final parsed = int.tryParse(v);
                          if (parsed != null) setDState(() => temp = parsed.clamp(0, 365));
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => setDState(() {
                        temp = (temp + 1).clamp(0, 365);
                        manualCtrl.text = '$temp';
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('0 ~ 365 天', style: TextStyle(fontSize: 11, color: Colors.grey[400])),
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
        _reminderItems.add(_ReminderItem(trimmed, 7, trimmed.contains('通知') || trimmed.contains('确认') || trimmed.contains('准备')));
      });
      Navigator.pop(context);
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加提醒'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (available.isNotEmpty) ...[
                Text('预设有', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                const SizedBox(height: 4),
                Wrap(spacing: 6, children: available.map((o) => ActionChip(
                  label: Text(o, style: const TextStyle(fontSize: 12)),
                  onPressed: () => addReminder(o),
                )).toList()),
                const Divider(height: 16),
              ],
              Text('自定义（不超过10字）', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              const SizedBox(height: 4),
              Row(children: [
                Expanded(child: TextField(
                  controller: customCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(hintText: '输入提醒名称', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                  maxLength: 10,
                  style: const TextStyle(fontSize: 14),
                  onSubmitted: (v) => addReminder(v),
                )),
              ]),
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
    // 收集已存档标签（所有目的地中使用过的标签）
    final allTags = <String>{};
    for (final loc in context.read<LocationProvider>().locations) {
      allTags.addAll(loc.preparationTags);
    }
    // 去掉当前已使用的标签
    final archived = allTags.difference(_tags.toSet()).toList()..sort();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加标签'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (archived.isNotEmpty) ...[
                Text('已存档标签', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6, runSpacing: 4,
                  children: archived.map((t) => ActionChip(
                    label: Text(t, style: const TextStyle(fontSize: 12)),
                    onPressed: () {
                      setState(() => _tags.add(t));
                      Navigator.pop(ctx);
                    },
                  )).toList(),
                ),
                const Divider(height: 16),
              ],
              Text('手动添加', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              const SizedBox(height: 6),
              TextField(
                controller: manualCtrl,
                autofocus: archived.isEmpty,
                decoration: const InputDecoration(hintText: '输入新标签', border: OutlineInputBorder()),
                onSubmitted: (v) {
                  if (v.trim().isNotEmpty) {
                    setState(() => _tags.add(v.trim()));
                    Navigator.pop(ctx);
                  }
                },
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
          TextField(controller: _nameCtrl, decoration: const InputDecoration(hintText: '输入地点名称', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10))),
          const SizedBox(height: 20),

          // 颜色选择：4色系 × 5色阶
          Text('颜色', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _ColorPicker(selected: _selectedColor, onChanged: (c) => setState(() => _selectedColor = c)),
          const SizedBox(height: 20),

          // 提醒事项（可增删调整顺序）
          Row(children: [
            Text('提醒事项', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            const Spacer(),
            IconButton(icon: const Icon(Icons.add_circle_outline, size: 20), onPressed: () => _showAddReminderDialog(context)),
          ]),
          const SizedBox(height: 8),
          ..._sortedWithIndex().map((pair) {
            final i = pair.$1;
            final item = pair.$2;
            final accentColor = item.isBefore ? const Color(0xFF4488FF) : const Color(0xFFFF8833);
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(children: [
                  // 左侧色条
                  Container(width: 4, height: 44, decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(10), bottomLeft: Radius.circular(10)),
                  )),
                  ReorderableDragStartListener(index: i, child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(Icons.drag_handle, size: 18, color: Colors.grey),
                  )),
                  Expanded(
                    child: _DayField(
                      label: item.label, value: item.value, isBefore: item.isBefore,
                      onTap: () => _showDayPicker(item.label, item.value, item.isBefore, (v) {
                        setState(() => _reminderItems[i] = _reminderItems[i].copyWith(value: v));
                      }),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16, color: Colors.red),
                    onPressed: _reminderItems.length > 1 ? () => setState(() => _reminderItems.removeAt(i)) : null,
                ),
              ]),
            ),
          );
        }),
          const SizedBox(height: 12),

          // 差旅准备（全部显示）
          Text('差旅准备', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 6, children: [
            ..._tags.map((t) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4FF), // 浅蓝底
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(t, style: const TextStyle(fontSize: 13, color: Color(0xFF3366CC))),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => setState(() => _tags.remove(t)),
                    child: const Icon(Icons.close, size: 16, color: Color(0xFF8899BB)),
                  ),
                ],
              ),
            )),
            // 添加按钮（加号图标）
            GestureDetector(
              onTap: () => _showAddTagDialog(context),
              child: Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: const Icon(Icons.add, size: 16, color: Colors.grey),
              ),
            ),
          ]),
          const SizedBox(height: 20),

          // 本次差旅特别提醒
          Row(children: [
            Text('本次差旅特别提醒', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            const Spacer(),
            IconButton(icon: const Icon(Icons.add_circle_outline, size: 20), onPressed: () => setState(() => _reminderCtrls.add(TextEditingController()))),
          ]),
          ...List.generate(_reminderCtrls.length, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8F0), // 浅橙底
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFF0E8D8)),
              ),
              child: Row(children: [
                const SizedBox(width: 8),
                SizedBox(width: 20, child: Text('${i + 1}.', style: TextStyle(color: Colors.grey[500], fontSize: 13))),
                Expanded(child: TextField(
                  controller: _reminderCtrls[i],
                  decoration: InputDecoration(
                    hintText: '第${i + 1}行',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 14),
                  maxLines: 1,
                )),
                IconButton(icon: const Icon(Icons.close, size: 16, color: Colors.red),
                  onPressed: _reminderCtrls.length > 1 ? () { setState(() { _reminderCtrls[i].dispose(); _reminderCtrls.removeAt(i); }); } : null),
              ]),
            ),
          )),
          const SizedBox(height: 24),

          // 单据扫描
          Row(children: [
            Text('单据扫描', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            const Spacer(),
            GestureDetector(
              onTap: () => _captureInvoice(),
              child: Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: const Icon(Icons.add, size: 16, color: Colors.grey),
              ),
            ),
          ]),
          const SizedBox(height: 4),
          Text('本次差旅的费用及发票', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 8),
          if (_invoicePaths.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: const Center(child: Text('暂无单据', style: TextStyle(fontSize: 13, color: Colors.grey))),
            )
          else
            Wrap(spacing: 6, runSpacing: 6, children: _invoicePaths.asMap().entries.map((e) {
              final idx = e.key;
              final path = e.value;
              final name = path.split('/').last;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.receipt_long, size: 16, color: Color(0xFFEF6C00)),
                  const SizedBox(width: 4),
                  Text(name, style: const TextStyle(fontSize: 12, color: Color(0xFFE65100))),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => setState(() => _invoicePaths.removeAt(idx)),
                    child: const Icon(Icons.close, size: 16, color: Color(0xFFCC8844)),
                  ),
                ]),
              );
            }).toList()),
          const SizedBox(height: 16),

          // 删除选项
          Text('删除目的地', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.visibility_off, size: 16),
                  label: const Text('临时删除', style: TextStyle(fontSize: 13)),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.orange),
                  onPressed: () {
                    context.read<LocationProvider>().archiveLocation(widget.locationId);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已存档，历史标记保留')));
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.delete_forever, size: 16),
                  label: const Text('永久删除', style: TextStyle(fontSize: 13)),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('确认删除'),
                        content: const Text('永久删除后将无法恢复'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
                          TextButton(
                            onPressed: () {
                              context.read<LocationProvider>().removeLocation(widget.locationId);
                              Navigator.pop(ctx);
                              Navigator.pop(context);
                            },
                            child: const Text('确认删除', style: TextStyle(color: Colors.red)),
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

/// 色系选择器
class _ColorPicker extends StatelessWidget {
  final Color selected;
  final ValueChanged<Color> onChanged;

  const _ColorPicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    String? activeFamily;
    for (final entry in TravelLocation.colorFamilies.entries) {
      if (entry.value.contains(selected)) { activeFamily = entry.key; break; }
    }

    const familyLabels = {'橙': '橙色系', '绿': '绿色系', '蓝': '蓝色系', '粉': '粉色系'};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 色系选择（居中 椭圆形）
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: TravelLocation.colorFamilies.keys.map((family) {
              final isActive = family == activeFamily;
              final colors = TravelLocation.colorFamilies[family]!;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: GestureDetector(
                  onTap: () => onChanged(colors[2]),
                  child: Container(
                    width: 60, height: 32,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [colors.first, colors.last]),
                      borderRadius: BorderRadius.circular(16),
                      border: isActive ? Border.all(color: Colors.black87, width: 2) : null,
                    ),
                    child: Center(child: Text(familyLabels[family]!, style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500))),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        // 色阶选择（居中 圆形）
        if (activeFamily != null) ...[
          const SizedBox(height: 10),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: TravelLocation.colorFamilies[activeFamily]!.map((c) {
                final isActive = c == selected;
                return GestureDetector(
                  onTap: () => onChanged(c),
                  child: Container(
                    width: 36, height: 36, margin: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: isActive ? Border.all(color: Colors.black87, width: 3) : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }
}

/// 天数字段（点击弹出选择器）
class _DayField extends StatelessWidget {
  final String label;
  final int value;
  final bool isBefore;
  final VoidCallback onTap;

  const _DayField({required this.label, required this.value, required this.isBefore, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sign = isBefore ? '-' : '+';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(children: [
          Text(label, style: const TextStyle(fontSize: 15)),
          const Spacer(),
          Text('$sign$value天', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isBefore ? Colors.blue : Colors.orange)),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, size: 18, color: Colors.grey[400]),
        ]),
      ),
    );
  }
}
