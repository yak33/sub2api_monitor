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

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull?.isAuthenticated ?? false;
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
