# Sub2API Monitor - 开发指南

## 快速开始

```bash
cd D:\ChaoProjects\FlutterProject\sub2api_monitor
flutter pub get
flutter run
```

## 代码规范

### 命名
- 文件: `snake_case.dart`
- 类: `PascalCase`
- 变量/函数: `camelCase`
- 常量: `camelCase` (Dart 风格)
- Provider: `xxxProvider`

### 目录
- 每个 Feature 独立目录
- `domain/` 不依赖 Flutter，纯 Dart
- `data/` 实现领域接口
- `presentation/` 只做 UI + 状态绑定

### 状态管理
- 异步数据用 `AsyncNotifierProvider`
- 简单状态用 `StateProvider` / `StateNotifierProvider`
- Provider 间依赖用 `ref.watch()` / `ref.read()`

## 添加新功能模块

### 1. 创建目录结构

```
features/
  └── new_feature/
      ├── domain/
      │   ├── entities/new_entity.dart
      │   ├── repositories/new_repository.dart
      │   └── providers/new_provider.dart
      ├── data/
      │   └── repositories/new_repository_impl.dart
      └── presentation/
          └── new_page.dart
```

### 2. 定义实体

```dart
class NewEntity {
  final int id;
  final String name;
  // ...
  factory NewEntity.fromJson(Map<String, dynamic> json) => ...
}
```

### 3. 在 ApiClient 中添加接口

```dart
Future<Map<String, dynamic>> getNewData() async {
  final response = await _dio.get('/api/v1/new-endpoint');
  return response.data;
}
```

### 4. 创建 Provider

```dart
final newProvider = AsyncNotifierProvider<NewNotifier, NewState>(() {
  return NewNotifier();
});

class NewNotifier extends AsyncNotifier<NewState> {
  @override
  Future<NewState> build() async { ... }
  Future<void> refresh() async { ... }
}
```

### 5. 创建页面

```dart
class NewPage extends ConsumerWidget {
  @override
  Widget build(context, ref) {
    final data = ref.watch(newProvider);
    return data.when(
      loading: () => const LoadingView(),
      error: (err, _) => ErrorView(message: err.toString()),
      data: (d) => /* 渲染 UI */,
    );
  }
}
```

### 6. 注册路由

在 `app/router.dart` 的 ShellRoute routes 中添加：

```dart
GoRoute(
  path: '/new',
  name: 'new',
  pageBuilder: (context, state) => const NoTransitionPage(child: NewPage()),
),
```

## 测试

```bash
# 单元测试
flutter test test/features/new_feature/

# 集成测试
flutter test integration_test/
```

## 发布

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release
```
