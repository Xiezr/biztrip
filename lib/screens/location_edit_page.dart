import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/travel_location.dart';
import '../providers/location_provider.dart';
import '../providers/mark_provider.dart';

class LocationEditPage extends StatefulWidget {
  final int locationId;
  const LocationEditPage({super.key, required this.locationId});

  @override
  State<LocationEditPage> createState() => _LocationEditPageState();
}

class _LocationEditPageState extends State<LocationEditPage> {
  late TextEditingController _nameCtrl;
  late TextEditingController _tagCtrl;
  late int _notifyDays, _followDays, _reimburseDays, _confirmDays, _reportDays;
  late List<String> _tags;
  late List<TextEditingController> _reminderCtrls;
  late Color _selectedColor;
  bool _showAllTags = false;

  @override
  void initState() {
    super.initState();
    final loc = context.read<LocationProvider>().getById(widget.locationId)!;
    _nameCtrl = TextEditingController(text: loc.name);
    _tagCtrl = TextEditingController();
    _notifyDays = loc.notificationDaysBefore;
    _followDays = loc.followUpDaysAfter;
    _reimburseDays = loc.reimbursementDaysAfter;
    _confirmDays = loc.confirmationDaysBefore;
    _reportDays = loc.reportDaysAfter;
    _tags = List.from(loc.preparationTags);
    _reminderCtrls = loc.specialReminder.map((s) => TextEditingController(text: s)).toList();
    _selectedColor = loc.color;
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _tagCtrl.dispose();
    for (final c in _reminderCtrls) { c.dispose(); }
    super.dispose();
  }

  void _save() {
    context.read<LocationProvider>().updateLocationFull(
      widget.locationId,
      name: _nameCtrl.text.trim(), color: _selectedColor,
      notificationDaysBefore: _notifyDays, followUpDaysAfter: _followDays,
      preparationTags: _tags, reimbursementDaysAfter: _reimburseDays,
      confirmationDaysBefore: _confirmDays, reportDaysAfter: _reportDays,
      specialReminder: _reminderCtrls.map((c) => c.text.trim()).toList(),
    );
    Navigator.pop(context);
  }

  void _showDayPicker(String label, int current, bool isBefore, ValueChanged<int> onChange) {
    int temp = current;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDState) {
        return AlertDialog(
          title: Text(label),
          content: SizedBox(
            width: 200,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('选择天数：'),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: () => setDState(() => temp = (temp - 1).clamp(0, 365)),
                    ),
                    Container(
                      width: 60, alignment: Alignment.center,
                      child: Text('$temp', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => setDState(() => temp = (temp + 1).clamp(0, 365)),
                    ),
                  ],
                ),
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
          TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: '地点名称', border: OutlineInputBorder())),
          const SizedBox(height: 20),

          // 颜色选择：4色系 × 5色阶
          Text('颜色', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          _ColorPicker(selected: _selectedColor, onChanged: (c) => setState(() => _selectedColor = c)),
          const SizedBox(height: 20),

          // 天数字段（点击弹出选择器）
          _DayField(label: '差旅通知', value: _notifyDays, isBefore: true, onTap: () => _showDayPicker('差旅通知', _notifyDays, true, (v) => setState(() => _notifyDays = v))),
          const SizedBox(height: 10),
          _DayField(label: '差旅确认', value: _confirmDays, isBefore: true, onTap: () => _showDayPicker('差旅确认', _confirmDays, true, (v) => setState(() => _confirmDays = v))),
          const SizedBox(height: 10),
          _DayField(label: '差旅跟进', value: _followDays, isBefore: false, onTap: () => _showDayPicker('差旅跟进', _followDays, false, (v) => setState(() => _followDays = v))),
          const SizedBox(height: 10),
          _DayField(label: '票据报销', value: _reimburseDays, isBefore: false, onTap: () => _showDayPicker('票据报销', _reimburseDays, false, (v) => setState(() => _reimburseDays = v))),
          const SizedBox(height: 10),
          _DayField(label: '差旅报告', value: _reportDays, isBefore: false, onTap: () => _showDayPicker('差旅报告', _reportDays, false, (v) => setState(() => _reportDays = v))),
          const SizedBox(height: 20),

          // 差旅准备（默认显示前2个）
          Text('差旅准备', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 6, children: [
            ...(_showAllTags ? _tags : _tags.take(2)).map((t) => Chip(
              label: Text(t, style: const TextStyle(fontSize: 13)),
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () => setState(() => _tags.remove(t)),
            )),
            if (_tags.length > 2 && !_showAllTags)
              ActionChip(
                label: Text('+${_tags.length - 2}', style: const TextStyle(fontSize: 12)),
                onPressed: () => setState(() => _showAllTags = true),
              ),
            // 添加按钮（加号图标）
            GestureDetector(
              onTap: () => _showAddTagDialog(context),
              child: Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: const Icon(Icons.add, size: 18, color: Colors.grey),
              ),
            ),
          ]),
          const SizedBox(height: 20),

          // 本次差旅特别提醒
          Row(children: [
            Text('本次差旅特别提醒', style: Theme.of(context).textTheme.titleSmall),
            const Spacer(),
            IconButton(icon: const Icon(Icons.add_circle_outline, size: 20), onPressed: () => setState(() => _reminderCtrls.add(TextEditingController()))),
          ]),
          ...List.generate(_reminderCtrls.length, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(children: [
              SizedBox(width: 20, child: Text('${i + 1}.', style: TextStyle(color: Colors.grey[500]))),
              Expanded(child: TextField(
                controller: _reminderCtrls[i],
                decoration: InputDecoration(hintText: '第${i + 1}行', border: const OutlineInputBorder(), contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), isDense: true),
                style: const TextStyle(fontSize: 14),
                maxLines: 2,
              )),
              IconButton(icon: const Icon(Icons.close, size: 18, color: Colors.red),
                onPressed: _reminderCtrls.length > 1 ? () { setState(() { _reminderCtrls[i].dispose(); _reminderCtrls.removeAt(i); }); } : null),
            ]),
          )),
          const SizedBox(height: 24),

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
                    context.read<MarkProvider>().removeMarksByLocation(widget.locationId);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已清除该目的地的所有差旅')));
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
                              context.read<MarkProvider>().removeMarksByLocation(widget.locationId);
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
    // 找出选中的颜色属于哪个色系
    String? activeFamily;
    for (final entry in TravelLocation.colorFamilies.entries) {
      if (entry.value.contains(selected)) { activeFamily = entry.key; break; }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 色系选择
        Row(children: TravelLocation.colorFamilies.keys.map((family) {
          final isActive = family == activeFamily;
          final colors = TravelLocation.colorFamilies[family]!;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => onChanged(colors[2]), // 点击色系名选中中间色
              child: Container(
                width: 48, height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [colors.first, colors.last]),
                  borderRadius: BorderRadius.circular(6),
                  border: isActive ? Border.all(color: Colors.black, width: 2) : null,
                ),
                child: Center(child: Text(family, style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500))),
              ),
            ),
          );
        }).toList()),
        // 色阶选择
        if (activeFamily != null) ...[
          const SizedBox(height: 8),
          Row(children: TravelLocation.colorFamilies[activeFamily]!.map((c) {
            final isActive = c == selected;
            return GestureDetector(
              onTap: () => onChanged(c),
              child: Container(
                width: 40, height: 40, margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: isActive ? Border.all(color: Colors.black, width: 3) : null,
                ),
              ),
            );
          }).toList()),
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
