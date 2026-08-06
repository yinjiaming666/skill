# 路由规范

本文件是 flutter-dev-guidelines-cn 的路由细则，由 SKILL.md「路由规范」章节引用。涉及路由路径、页面注册、页面跳转、清栈跳转、替换跳转、无 `context` 跳转、返回传参、页面参数读取时按本文件执行。

本项目路由基于 `fluro`，统一在 `lib/router.dart` 中维护 `Routes`，跳转统一使用 `lib/tool/route_helper.dart` 的 `RouterHelper`。示例 import 默认固定使用 `package:app`。

## 路由接入示例

在应用初始化时先注册路由：

```dart
Future<void> _init() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 注册路由
  Routes.configureRoutes();

  // 其他初始化...
}
```

在 `MaterialApp` 或项目当前使用的 `PiPMaterialApp` 中接入路由：

```dart
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return PiPMaterialApp(
      navigatorKey: navigatorKey,
      onGenerateRoute: Routes.router.generator,
      navigatorObservers: [AppRouteObserver().routeObserver],
    );
  }
}
```

## Routes 配置示例

在 `lib/router.dart` 中集中维护路径和页面注册：

```dart
import 'package:app/pages/index/user.dart';
import 'package:app/pages/wallet/detail.dart';
import 'package:app/tabbar.dart';
import 'package:app/tool/route_helper.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';

class Routes {
  static FluroRouter router = FluroRouter();

  static String indexPage = '/index/index'; // 首页
  static String userPage = '/index/user'; // 用户主页
  static String walletDetailPage = '/wallet/detail'; // 钱包详情页

  static void _initRouter() {
    router.define('/', handler: Handler(handlerFunc: (_, __) => const NavContainer(0)));
    router.define(indexPage, handler: Handler(handlerFunc: (_, __) => const NavContainer(0)));

    router.define(
      userPage,
      handler: Handler(
        handlerFunc: (BuildContext? context, Map<String, List<String>> parameters) {
          int uid = 0;
          if (context != null) {
            uid = readArguments<int>(context, 'uid');
          }
          return UserPage(uid: uid);
        },
      ),
    );

    router.define(
      walletDetailPage,
      handler: Handler(
        handlerFunc: (BuildContext? context, Map<String, List<String>> parameters) {
          int type = 0;
          if (context != null) {
            type = readArguments<int>(context, 'type');
          }
          return WalletDetailPage(type: type);
        },
      ),
    );
  }

  static void configureRoutes() {
    router.notFoundHandler = Handler(
      handlerFunc: (_, __) {
        return const Scaffold(
          body: Center(child: SizedBox()),
        );
      },
    );
    _initRouter();
  }
}
```

新增路由时必须同时完成：

- import 目标页面。
- 在 `Routes` 中增加 `static String xxxPage = '/module/page';`。
- 在 `_initRouter()` 中增加 `router.define(...)`。
- 有参数的页面通过 `readArguments<T>(context, 'key')` 读取。
- 路径使用小写模块路径，例如 `/wallet/detail`、`/discover/topic_detail`。

## 参数读取示例

本项目通过 `RouteSettings.arguments` 传参，使用 `readArguments<T>` 读取：

```dart
readArguments<T>(BuildContext context, String key) {
  final Object? args = ModalRoute.of(context)?.settings.arguments;
  if (args == null) {
    RouterHelper.back();
  }
  final Map<String, dynamic> params = args as Map<String, dynamic>;
  return params[key] as T;
}
```

调用约定：

```dart
final int uid = readArguments<int>(context, 'uid');
final String keyword = readArguments<String>(context, 'keyword');
final bool isCustom = readArguments<bool>(context, 'isCustom');
```

如果新增复杂参数，优先创建路由参数模型放在 `lib/model/route-args/`，再通过 `arguments` 传入，避免多个页面散落魔法 key。

## RouterHelper 示例

跳转必须优先走 `RouterHelper`，不要在业务页面里散落 `Routes.router.navigateTo`。

```dart
import 'package:app/main.dart';
import 'package:app/router.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';

class RouterHelper {
  static void push(
    BuildContext context,
    String path, {
    bool replace = false,
    bool clearStack = false,
    Object? arguments,
    TransitionType? transition,
  }) {
    Routes.router.navigateTo(
      context,
      path,
      replace: replace,
      clearStack: clearStack,
      transition: transition ?? TransitionType.inFromRight,
      routeSettings: RouteSettings(arguments: arguments),
    );
  }

  static void switchTab(String path, {bool replace = false, bool clearStack = true, Object? arguments}) {
    Routes.router.navigateTo(
      navigatorKey.currentContext!,
      path,
      replace: replace,
      clearStack: clearStack,
      transition: TransitionType.inFromRight,
      routeSettings: RouteSettings(arguments: arguments),
    );
  }

  static void back({int count = 1, Object? params, BuildContext? context}) {
    if (context != null && !context.mounted) {
      return;
    }

    NavigatorState state = Navigator.of(context ?? navigatorKey.currentContext!);
    while (count-- > 0) {
      state = state..pop(params);
    }
  }

  static void pushWithNoContext(
    String path, {
    bool replace = false,
    bool clearStack = false,
    Object? arguments,
    TransitionType? transition,
  }) {
    Routes.router.navigateTo(
      navigatorKey.currentContext!,
      path,
      replace: replace,
      clearStack: clearStack,
      transition: transition ?? TransitionType.inFromRight,
      routeSettings: RouteSettings(arguments: arguments),
    );
  }
}
```

## 页面跳转示例

普通跳转：

```dart
RouterHelper.push(context, Routes.walletDetailPage, arguments: {'type': MoneyType.money.val});
```

替换当前页：

```dart
RouterHelper.push(context, Routes.familyIndexPage, replace: true);
```

清空路由栈跳转到登录页：

```dart
RouterHelper.push(context, Routes.smsLoginPage, clearStack: true);
```

无 `context` 跳转：

```dart
RouterHelper.pushWithNoContext(Routes.smsLoginPage, clearStack: true);
```

切换到首页或 tab 容器：

```dart
RouterHelper.switchTab(Routes.indexPage);
```

返回并携带结果：

```dart
RouterHelper.back(params: {'refresh': true}, context: context);
```

## 页面接收参数示例

目标页面构造函数保持显式参数：

```dart
class WalletDetailPage extends StatefulWidget {
  final int type;

  const WalletDetailPage({super.key, required this.type});

  @override
  State<WalletDetailPage> createState() => _WalletDetailPageState();
}
```

路由注册时给默认值，避免参数缺失导致页面崩溃：

```dart
router.define(
  Routes.walletDetailPage,
  handler: Handler(
    handlerFunc: (BuildContext? context, Map<String, List<String>> parameters) {
      int type = 0;
      if (context != null) {
        type = readArguments<int>(context, 'type');
      }
      return WalletDetailPage(type: type);
    },
  ),
);
```

## 检查清单

- 新页面已 import 到 `router.dart`。
- `Routes` 中已新增清晰的路径常量。
- `_initRouter()` 中已 `router.define`。
- 跳转方使用 `RouterHelper.push`、`switchTab`、`pushWithNoContext` 或 `back`。
- 参数 key 在跳转方和 `readArguments<T>` 读取方完全一致。
- 异步回调后跳转前检查 `context.mounted`。
