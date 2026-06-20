import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';

class _NavItem {
  final String path;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool adminOnly;

  const _NavItem({required this.path, required this.icon, required this.activeIcon, required this.label, this.adminOnly = false});
}

const _allNavItems = [
  _NavItem(path: '/', icon: Icons.space_dashboard_outlined, activeIcon: Icons.space_dashboard, label: '仪表盘'),
  _NavItem(path: '/accounts', icon: Icons.dns_outlined, activeIcon: Icons.dns, label: '账号', adminOnly: true),
  _NavItem(path: '/users', icon: Icons.people_outline, activeIcon: Icons.people, label: '用户', adminOnly: true),
  _NavItem(path: '/profile', icon: Icons.person_outline, activeIcon: Icons.person, label: '我的'),
];

class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final isAdmin = ref.watch(authStateProvider).valueOrNull?.user?.isAdmin ?? false;
    final items = _allNavItems.where((e) => !e.adminOnly || isAdmin).toList();

    final location = GoRouterState.of(context).matchedLocation;
    int currentIndex = 0;
    for (var i = 0; i < items.length; i++) {
      final path = items[i].path;
      if (path == '/' ? location == '/' : location.startsWith(path)) { currentIndex = i; break; }
    }

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: KeyedSubtree(key: ValueKey(currentIndex), child: child),
      ),
      bottomNavigationBar: _NavBar(cs: cs, items: items, currentIndex: currentIndex, onTap: (i) => context.go(items[i].path)),
    );
  }
}

class _NavBar extends StatelessWidget {
  final ColorScheme cs;
  final List<_NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _NavBar({required this.cs, required this.items, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isDark = cs.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 8),
      decoration: BoxDecoration(
        color: isDark ? cs.surface.withValues(alpha: 0.98) : cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: [BoxShadow(color: isDark ? Colors.black38 : Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60 + bottomPadding,
          child: Padding(
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: Row(
              children: List.generate(items.length, (i) {
                final active = i == currentIndex;
                final item = items[i];
                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTap(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(duration: const Duration(milliseconds: 250), width: active ? 28 : 0, height: 2.5,
                              decoration: BoxDecoration(color: active ? cs.primary : Colors.transparent, borderRadius: BorderRadius.circular(2))),
                          const Spacer(),
                          Icon(active ? item.activeIcon : item.icon,
                              size: active ? 22 : 20, color: active ? cs.primary : cs.onSurfaceVariant),
                          const SizedBox(height: 4),
                          Text(item.label, style: TextStyle(fontSize: 10, fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                              color: active ? cs.primary : cs.onSurfaceVariant, letterSpacing: 0.3)),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
