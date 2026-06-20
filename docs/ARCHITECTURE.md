# Sub2API Monitor - 架构设计文档

## 架构模式: Feature-First + Clean Architecture

本项目采用 **Feature-First** 目录组织 + **Clean Architecture** 分层：

```
features/
  └── [feature_name]/
      ├── domain/          # 领域层 (纯 Dart，无依赖)
      │   ├── entities/    # 数据实体
      │   └── repositories/ # 仓库接口 (abstract)
      │
      ├── data/            # 数据层 (实现 domain 接口)
      │   ├── datasources/
      │   │   ├── local/   # 本地存储
      │   │   └── remote/  # 网络请求
      │   └── repositories/ # 仓库实现
      │
      └── presentation/    # 展示层 (UI + 状态)
          ├── [page].dart
          └── widgets/     # 页面级组件
```

## 数据流

```
UI Widget
   ↕ (watch/read)
Riverpod Provider (AsyncNotifier)
   ↕ (call)
Repository (interface)
   ↕ (implement)
Repository Impl
   ↕ (HTTP/Storage)
ApiClient / AuthStorage
```

## 状态管理: Riverpod

- **AsyncNotifier** 管理异步状态 (loading/data/error)
- **Provider** 提供依赖注入
- **StateProvider** 管理简单状态 (baseUrl)

### 状态流转

```
AsyncLoading → AsyncData(数据) / AsyncError(错误)
```

UI 通过 `.when()` 三态渲染：

```dart
provider.when(
  loading: () => LoadingView(),
  error: (err, _) => ErrorView(message: err.toString()),
  data: (data) => ContentWidget(data: data),
)
```

## 网络层: Dio

- `ApiClient` 封装所有 HTTP 请求
- `AuthInterceptor` 自动注入 JWT + 401 自动刷新
- `baseUrl` 通过 StateProvider 动态切换

## 路由: GoRouter

- ShellRoute 实现底部导航
- 自动重定向 (未登录 → /login, 已登录 → /)
- NoTransitionPage 避免底部导航切换动画

## 主题系统

- `ThemeModeNotifier` 持久化主题选择到 SharedPreferences
- Light/Dark 双主题定义在 `AppTheme`
- Material 3 + 自定义 ColorScheme

## 安全设计

- JWT Token 存储在 FlutterSecureStorage (Android 加密 SharedPreferences / iOS Keychain)
- Refresh Token 自动续期
- API Key 在列表中脱敏显示 (`sk-sub-xxxx...yyyy`)
