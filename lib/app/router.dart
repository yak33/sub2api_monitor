import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/login_page.dart';
import '../features/dashboard/presentation/dashboard_page.dart';
import '../features/keys/presentation/keys_page.dart';
import '../features/users/presentation/users_page.dart';
import '../features/users/presentation/user_detail_page.dart';
import '../features/accounts/presentation/accounts_page.dart';
import '../features/subscriptions/presentation/subscriptions_page.dart';
import '../features/profile/presentation/profile_page.dart';
import '../features/settings/presentation/settings_page.dart';
import '../shared/presentation/main_shell.dart';
import '../shared/providers/auth_provider.dart';

// ── Shell 路由 (底部导航) ──
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// 登录状态的变化列表。仅当 isAuthenticated 翻转时才通知 router 重定向，
/// 避免 login() 内部的中间状态（loading / error）重建整个 router，
/// 否则 LoginPage 会被销毁重建，导致输入框被清空、错误提示丢失。
class _AuthRedirectNotifier extends ChangeNotifier {
  _AuthRedirectNotifier(Ref ref) {
    ref.listen<AuthState?>(
      // 只关注“是否已登录”这一个维度，过滤掉 loading/error 抖动
      authStateProvider.select((async) {
        final v = async.valueOrNull;
        return v == null ? null : AuthState(isAuthenticated: v.isAuthenticated);
      }),
      (_, __) => notifyListeners(),
      // fireImmediately: 不需要，router 初始化时 redirect 会自然执行一次
    );
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _AuthRedirectNotifier(ref);
  // provider 销毁时一并释放监听，避免内存泄漏
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      // 直接读 provider 当前值，避免在 build 期 watch 导致 router 被重建
      final authState = ref.read(authStateProvider).valueOrNull;
      final isLoggedIn = authState?.isAuthenticated ?? false;
      final isLoginRoute = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoginRoute) return '/login';
      if (isLoggedIn && isLoginRoute) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            name: 'dashboard',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DashboardPage(),
            ),
          ),
          GoRoute(
            path: '/accounts',
            name: 'accounts',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AccountsPage(),
            ),
          ),
          GoRoute(
            path: '/users',
            name: 'users',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: UsersPage(),
            ),
            routes: [
              GoRoute(
                path: ':id',
                name: 'userDetail',
                builder: (context, state) {
                  final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
                  return UserDetailPage(userId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfilePage(),
            ),
          ),
        ],
      ),
      // ── 顶层路由（push 方式访问，不显示底部导航）──
      GoRoute(
        path: '/keys',
        name: 'keys',
        builder: (context, state) => const KeysPage(),
      ),
      GoRoute(
        path: '/subscriptions',
        name: 'subscriptions',
        builder: (context, state) => const SubscriptionsPage(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsPage(),
      ),
    ],
  );
});
