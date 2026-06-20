import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_theme.dart';
import '../../../shared/providers/app_providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final themeMode = ref.watch(themeModeProvider);
    final baseUrl = ref.watch(baseUrlProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(padding: const EdgeInsets.all(14), children: [
        _Sec(text: '外观', cs: cs), const SizedBox(height: 8),
        Container(decoration: AppTheme.cardDecoration(cs), child: Column(children: [
          _ThemeOpt(icon: Icons.light_mode, label: '浅色模式 (Precision Lab)', selected: themeMode == ThemeMode.light, cs: cs,
              onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light)),
          const _Div(),
          _ThemeOpt(icon: Icons.dark_mode, label: '深色模式 (Obsidian)', selected: themeMode == ThemeMode.dark, cs: cs,
              onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark)),
          const _Div(),
          _ThemeOpt(icon: Icons.brightness_auto, label: '跟随系统', selected: themeMode == ThemeMode.system, cs: cs,
              onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.system)),
        ])),
        const SizedBox(height: 22), _Sec(text: '服务器', cs: cs), const SizedBox(height: 8),
        Container(padding: const EdgeInsets.all(14), decoration: AppTheme.cardDecoration(cs), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('服务器地址', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant, letterSpacing: 0.5)),
          const SizedBox(height: 6), Text(baseUrl.isEmpty ? '未配置' : baseUrl, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface)),
          const SizedBox(height: 10), SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () => _editUrl(context, ref, baseUrl), child: const Text('修改地址'))),
        ])),
        const SizedBox(height: 22), _Sec(text: '关于', cs: cs), const SizedBox(height: 8),
        Container(padding: const EdgeInsets.all(14), decoration: AppTheme.cardDecoration(cs), child: Column(children: [
          _InfoRow(label: '版本', value: '1.0.0'), const _Div(), _InfoRow(label: '框架', value: 'Flutter 3.x'), const _Div(), _InfoRow(label: '项目', value: 'Sub2API Monitor'),
        ])),
      ]),
    );
  }

  void _editUrl(BuildContext ctx, WidgetRef ref, String cur) {
    final ctrl = TextEditingController(text: cur);
    showDialog(context: ctx, builder: (c) => AlertDialog(
      title: const Text('服务器地址'), content: TextField(controller: ctrl, keyboardType: TextInputType.url, decoration: const InputDecoration(hintText: 'https://api.example.com', prefixIcon: Icon(Icons.link, size: 18))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: const Text('取消')),
        ElevatedButton(onPressed: () { ref.read(baseUrlProvider.notifier).setBaseUrl(ctrl.text.trim()); Navigator.pop(c); if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('地址已更新'))); }, child: const Text('保存')),
      ],
    ));
  }
}

class _Sec extends StatelessWidget {
  final String text; final ColorScheme cs;
  const _Sec({required this.text, required this.cs});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(left: 4, bottom: 4), child: Row(children: [
    Container(width: 3, height: 14, decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 8), Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant, letterSpacing: 0.5)),
  ]));
}

class _ThemeOpt extends StatelessWidget {
  final IconData icon; final String label; final bool selected; final ColorScheme cs; final VoidCallback? onTap;
  const _ThemeOpt({required this.icon, required this.label, required this.selected, required this.cs, this.onTap});
  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, size: 20, color: selected ? cs.primary : cs.onSurfaceVariant),
    title: Text(label, style: TextStyle(fontSize: 14, color: selected ? cs.primary : cs.onSurface, fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
    trailing: selected ? Container(width: 8, height: 8, decoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle)) : null,
    contentPadding: const EdgeInsets.symmetric(horizontal: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), onTap: onTap,
  );
}

class _Div extends StatelessWidget { const _Div(); @override Widget build(BuildContext context) => Divider(height: 1, color: Theme.of(context).colorScheme.outlineVariant); }

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)), Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface)),
    ]));
  }
}
