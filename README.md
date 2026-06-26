# Sub2API Monitor — AI API 网关移动监控面板

> 📱 随身监控 [Sub2API](https://github.com/Wei-Shaw/sub2api) 网关，实时查看用量统计、余额、API Key 状态与用户管理。

## 🚀 功能概览

| 模块 | 说明 | 核心端点 |
|------|------|----------|
| 登录 | 邮箱密码登录，JWT + Refresh Token 自动续期 | `POST /api/v1/auth/login` |
| 仪表盘 | 余额、今日/本周/本月用量、趋势图、模型分布（管理员可切换全站视图） | `/api/v1/usage/dashboard/*` `/api/v1/admin/dashboard/*` |
| 用量详情 | 使用日志列表，分页 + 日期/模型筛选 | `GET /api/v1/usage` |
| API Key 管理 | 密钥 CRUD、脱敏展示、一键复制 | `/api/v1/keys` |
| 账号管理 | AI 账号列表、平台/状态过滤、测试/清错/恢复/刷新 | `/api/v1/admin/accounts` |
| 用户管理 | 用户列表、搜索/过滤、CRUD、余额调整 | `/api/v1/admin/users` |
| 订阅管理 | 订阅列表、分配/批量分配/延期/重置配额/撤销 | `/api/v1/admin/subscriptions` |
| 个人中心 | 用户信息、兑换码、公告 | `/api/v1/auth/me` `/api/v1/redeem` |
| 渠道监控 | AI 账号与渠道状态查询 | `/api/v1/channel-monitors` `/api/v1/admin/accounts` |
| 设置 | Light/Dark 主题切换、服务器地址配置 | — |

## 🔗 后端项目

本 App 对接 [**Sub2API**](https://github.com/Wei-Shaw/sub2api) — 一个功能丰富的 AI API 网关，支持多模型聚合、额度管理、渠道监控等。

## 📁 项目结构

```
lib/
├── main.dart                           # 应用入口（竖屏锁定 + 透明状态栏）
├── app/
│   ├── app_theme.dart                  # Material 3 Light/Dark 双主题
│   └── router.dart                     # GoRouter + ShellRoute 底部导航 + 鉴权重定向
│
├── features/
│   ├── auth/                           # 认证模块
│   │   ├── domain/
│   │   │   ├── entities/user.dart
│   │   │   └── repositories/auth_repository.dart       # 抽象接口
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── local/auth_storage.dart             # FlutterSecureStorage
│   │   │   │   └── remote/
│   │   │   │       ├── api_client.dart                 # Dio HTTP 客户端（所有端点）
│   │   │   │       └── auth_interceptor.dart           # JWT 自动注入 + 401 静默刷新
│   │   │   └── repositories/auth_repository_impl.dart
│   │   └── presentation/
│   │       └── login_page.dart
│   │
│   ├── dashboard/                     # 仪表盘
│   │   ├── domain/
│   │   │   ├── entities/dashboard_data.dart            # 兼容用户级 + 管理员级数据
│   │   │   └── providers/dashboard_provider.dart       # admin 优先 + 自动降级用户级
│   │   ├── presentation/
│   │   │   └── dashboard_page.dart
│   │   └── widgets/
│   │       ├── stat_card.dart          # 统计卡片组件
│   │       ├── usage_chart.dart        # 用量趋势折线图 (fl_chart)
│   │       └── top_models_chart.dart   # 模型用量分布
│   │
│   ├── usage/                         # 用量详情
│   │   ├── domain/
│   │   │   ├── entities/usage_log.dart
│   │   │   └── providers/usage_provider.dart
│   │   └── presentation/
│   │       └── usage_page.dart         # 分页列表 + 日期/模型筛选
│   │
│   ├── keys/                          # API Key 管理
│   │   ├── domain/
│   │   │   ├── entities/api_key.dart
│   │   │   └── providers/keys_provider.dart
│   │   └── presentation/
│   │       └── keys_page.dart          # CRUD + 脱敏复制
│   │
│   ├── users/                         # 用户管理（管理员）
│   │   ├── domain/
│   │   │   ├── entities/admin_user.dart
│   │   │   └── providers/users_provider.dart           # 分页 + 搜索/过滤/CRUD/余额调整
│   │   └── presentation/
│   │       ├── users_page.dart
│   │       └── user_detail_page.dart   # 用户详情 + 用量统计 + 余额调整
│   │
│   ├── accounts/                       # 账号管理（管理员）
│   │   ├── domain/
│   │   │   ├── entities/admin_account.dart              # AI 账号实体
│   │   │   └── providers/accounts_provider.dart         # 列表 + 过滤 + 清错/恢复/刷新/删除
│   │   └── presentation/
│   │       └── accounts_page.dart       # 账号列表 + 平台/状态过滤 + 操作菜单
│   │
│   ├── subscriptions/                  # 订阅管理（管理员）
│   │   ├── domain/
│   │   │   ├── entities/admin_subscription.dart        # AdminUserSubscription + BulkAssignResult
│   │   │   └── providers/subscriptions_provider.dart   # 列表 + 分配/延期/重置/撤销
│   │   └── presentation/
│   │       └── subscriptions_page.dart # 订阅列表 + 状态过滤 + 操作对话框
│   │
│   ├── profile/                       # 个人中心
│   │   └── presentation/
│   │       └── profile_page.dart      # 用户信息/兑换/订阅/公告
│   │
│   └── settings/                      # 设置
│       └── presentation/
│           └── settings_page.dart     # 主题切换/服务器地址配置
│
└── shared/                            # 共享层
    ├── presentation/
    │   ├── main_shell.dart            # 底部导航 Shell（仪表盘/用量/用户/我的）
    │   └── common_widgets.dart        # 通用 Loading/Error 组件
    └── providers/
        ├── app_providers.dart         # ThemeMode / BaseUrl 持久化
        ├── auth_provider.dart         # 认证状态管理 + 全局 DI（ApiClient / Repository）
        └── global_providers.dart      # 全局刷新触发器
```

## 🛠️ 技术栈

| 类别 | 技术 | 版本 |
|------|------|------|
| 框架 | Flutter | 3.x / Dart 3.5+ |
| 状态管理 | Riverpod | 2.6.x |
| 网络请求 | Dio | 5.7.x |
| 路由 | GoRouter | 14.x |
| 图表 | fl_chart | 0.69.x |
| 安全存储 | FlutterSecureStorage | 9.x |
| 本地配置 | SharedPreferences | 2.x |

### 架构模式

**Feature-First + Clean Architecture**，每个功能模块垂直切分为三层：

```
features/<feature>/
  domain/       领域层 — 实体 + 仓库接口（纯 Dart，零框架依赖）
  data/         数据层 — 数据源 + 仓库实现
  presentation/ 展示层 — 页面 + 组件
```

数据流 `UI → Riverpod AsyncNotifier → Repository(接口) → RepositoryImpl → ApiClient / Storage`，UI 通过 `.when()` 三态渲染（loading / error / data）。

状态管理采用 `AsyncNotifier` 管理异步状态，`StateNotifier` 管理复杂本地状态，`Provider` 提供依赖注入。

## 🔧 开发指南

### 环境准备

```bash
# 1. 确保 Flutter 环境就绪
flutter doctor

# 2. 安装依赖
flutter pub get

# 3. 运行（连接设备或模拟器）
flutter run
```

### 连接 Sub2API 后端

1. 启动 App → 底部导航「我的」→ 右上角设置图标进入设置页
2. 填写你的 **Sub2API 服务器地址**
3. 返回登录页，输入邮箱密码登录
4. JWT 自动持久化，后续启动自动恢复登录态

### 构建发布版

```bash
# Android APK
flutter build apk --release

# iOS (需 macOS + Xcode)
flutter build ios --release
```

## 📡 API 接口对照

Sub2API 后端使用 **JWT Bearer Token** 认证，所有 `/api/v1/*` 端点需在 Header 中携带：

```
Authorization: Bearer <your-jwt-token>
```

Token 过期后由 `AuthInterceptor` 自动用 refresh_token 续期，对用户透明。

### 认证

| 接口 | 方法 | 用途 | 鉴权 |
|------|------|------|------|
| `/api/v1/auth/login` | POST | 登录获取 Token 与用户信息 | 公开 |
| `/api/v1/auth/refresh` | POST | 刷新 Token（拦截器自动调用） | 公开 |
| `/api/v1/auth/me` | GET | 获取当前登录用户 | JWT |

### 个人监控（用户级，JWT 鉴权）

| 接口 | 方法 | 用途 |
|------|------|------|
| `/api/v1/usage/dashboard/stats` | GET | 个人仪表盘汇总 |
| `/api/v1/usage/dashboard/trend` | GET | 个人用量趋势 |
| `/api/v1/usage/dashboard/models` | GET | 个人模型用量分布 |
| `/api/v1/usage` | GET | 用量日志列表（分页） |
| `/api/v1/keys` | GET | API Key 列表 |
| `/api/v1/keys` | POST | 创建 API Key |
| `/api/v1/keys/:id` | PUT | 更新 API Key |
| `/api/v1/keys/:id` | DELETE | 删除 API Key |
| `/api/v1/subscriptions` | GET | 订阅列表 |
| `/api/v1/announcements` | GET | 公告列表 |
| `/api/v1/redeem` | POST | 兑换码兑换 |
| `/api/v1/channel-monitors` | GET | 渠道监控状态 |

### 管理员面板（admin 鉴权，普通用户返回 403）

| 接口 | 方法 | 用途 |
|------|------|------|
| `/api/v1/admin/dashboard/stats` | GET | 全站仪表盘汇总 |
| `/api/v1/admin/dashboard/trend` | GET | 全站用量趋势 |
| `/api/v1/admin/dashboard/models` | GET | 全站模型分布 |
| `/api/v1/admin/accounts` | GET | 账号列表（分页+平台/状态过滤） |
| `/api/v1/admin/accounts/:id/clear-error` | POST | 清除账号错误 |
| `/api/v1/admin/accounts/:id/recover-state` | POST | 恢复账号状态 |
| `/api/v1/admin/accounts/:id/refresh` | POST | 刷新账号 |
| `/api/v1/admin/accounts/:id/test` | POST | 测试连通性 |
| `/api/v1/admin/subscriptions` | GET | 订阅列表（分页+过滤） |
| `/api/v1/admin/subscriptions/assign` | POST | 分配订阅 |
| `/api/v1/admin/subscriptions/bulk-assign` | POST | 批量分配订阅 |
| `/api/v1/admin/subscriptions/:id/extend` | POST | 延长/缩短有效期 |
| `/api/v1/admin/subscriptions/:id/reset-quota` | POST | 重置用量配额 |
| `/api/v1/admin/subscriptions/:id` | DELETE | 撤销订阅 |
| `/api/v1/admin/accounts` | GET | AI 账号列表 |
| `/api/v1/admin/users` | GET | 用户列表（分页+搜索+过滤） |
| `/api/v1/admin/users` | POST | 创建用户 |
| `/api/v1/admin/users/:id` | GET | 用户详情 |
| `/api/v1/admin/users/:id` | PUT | 更新用户信息 |
| `/api/v1/admin/users/:id` | DELETE | 删除用户 |
| `/api/v1/admin/users/:id/balance` | POST | 调整用户余额（幂等） |
| `/api/v1/admin/users/:id/usage` | GET | 用户用量统计 |

### 响应信封

所有接口统一包装:

```json
{
  "code": 0,
  "message": "success",
  "data": { ... }
}
```

## 🎨 设计规范

- **品牌色**: `#6C5CE7` (紫) + `#00CEC9` (青)
- **支持 Light/Dark 双主题**，跟随系统或手动切换
- Material 3 设计语言
- 卡片圆角: 16px，按钮/输入框圆角: 12px
- 主字号: 14-16px，标题: 18-28px
- 间距: 12-24px

## 📝 后续计划

- [ ] 推送通知（配额不足/账号异常告警）
- [ ] Widget 桌面小组件（iOS/Android 余额展示）
- [ ] 渠道监控独立页面（目前仅 API 层，无专门 UI）
- [ ] 国际化 (i18n)
- [ ] 多服务器切换与管理
- [ ] OAuth / SSO 登录支持

## 📄 相关文档

- [架构设计](docs/ARCHITECTURE.md) — 分层设计、数据流、状态管理
- [开发指南](docs/DEVELOPMENT.md)
