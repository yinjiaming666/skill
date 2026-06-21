---
name: flutter-dev-guidelines-cn
description: 中文 Flutter 项目通用开发规范。用于在 Flutter/Dart 项目中新增或修改页面、组件、状态管理、网络请求封装、资源、样式适配、权限、音视频、WebSocket、缓存或测试验证时，指导 Codex 按项目既有结构和约定实施代码变更；实体类转换使用 flutter-entity-conversion-cn，路由配置和跳转使用 flutter-route-guidelines-cn。
---

# Flutter 项目开发规范

## 基本原则

使用本 skill 时，以“贴合现有项目”为第一优先级。修改前先阅读相关目录和相邻文件，复用当前项目已有的命名、分层、工具类和交互方式；只在确有必要时引入新抽象或新依赖。

本项目当前以 `lib/pages`、`lib/services`、`lib/model`、`lib/request`、`lib/tool`、`lib/widget` 分层，常用依赖包括 `provider`、`dio`、`fluro`、`flutter_screenutil`、`easy_refresh`、`event_bus`、`web_socket_channel`、`agora_rtc_engine`、`permission_handler` 等。新增功能应优先落入这些既有边界。

实体类转换、响应模型生成、JSON 泛型解析等任务使用 `$flutter-entity-conversion-cn`。路由路径、`fluro` 注册、`RouterHelper` 跳转和参数传递等任务使用 `$flutter-route-guidelines-cn`。

## 修改前检查

1. 先用 `rg --files` 和 `rg` 查找同类页面、同类服务方法、同类组件和工具类写法。
2. 阅读 `pubspec.yaml`、`analysis_options.yaml`，确认依赖、资源目录和 lint 规则。
3. 涉及接口时，先阅读 `.api` 契约；若创建或修改接口调用，必须同步 `.api` 契约。
4. 涉及响应实体时，切换到 `$flutter-entity-conversion-cn`。
5. 涉及路由时，切换到 `$flutter-route-guidelines-cn`。
6. 涉及样式时，先查看相邻页面和 `lib/widget` 公共组件，复用 `CommonWidget`、`ToastHelper`、`ImgHelper` 等现有工具。

## 目录与命名

- 页面放在 `lib/pages/<业务模块>/`，入口文件通常命名为 `index.dart`，子页面按业务语义命名。
- 业务请求封装放在 `lib/services/<module>_services.dart`，服务类使用静态方法时沿用现有风格。
- 通用 UI 放在 `lib/widget/`，纯工具方法放在 `lib/tool/`。
- 资源放在 `assets/images/<业务模块>/` 等已声明目录；新增资源后同步 `pubspec.yaml`。
- 文件名使用小写加下划线；Dart 类型使用 `UpperCamelCase`，变量和方法使用 `lowerCamelCase`。

## Dart 代码规范

- 遵守 `flutter_lints`；提交前运行 `dart format .` 和 `flutter analyze`。
- 优先使用明确类型。局部变量可用 `final`，当类型能提升可读性时显式写出类型。
- Widget 构造函数尽量加 `const`；不可变字段使用 `final`。
- 避免魔法字符串散落。重复出现的缓存 key、枚举值、颜色和资源路径应复用已有常量或集中定义。
- 不使用 `print` 作为正式日志；如需调试或线上诊断，优先使用项目已有 logger 或受控日志方式。
- 不扩大无关重构范围；只整理与本次需求直接相关的代码。

## 页面与状态

- 页面优先使用项目现有 `StatefulWidget`、`provider` 和全局状态模式，不随意引入新的状态管理库。
- `TextEditingController`、`TabController`、`AnimationController`、`Timer`、`StreamSubscription` 等必须在 `dispose` 中释放或取消。
- 异步回调后访问 `context` 或调用 `setState` 前检查 `context.mounted` 或 `mounted`。
- 列表、刷新、分页优先参考现有 `easy_refresh` 用法；分页参数保持 `page`、`limit` 等项目既有命名。
- 表单提交前在页面层做基础校验，业务失败提示由服务层或页面按现有模式使用 `ToastHelper.showToast`。

## UI 与适配

- 尺寸适配沿用 `flutter_screenutil`，优先使用项目内已有 `.w` 写法。
- 图片优先走 `assets/images/...` 已声明目录，并复用 `img`、`ImgConf` 等封装。
- 页面布局优先保持现有产品风格，不新增突兀的卡片、过度渐变或不一致的圆角体系。
- 文案使用中文，错误和空状态提示要具体、可行动。

## 网络请求

- 接口调用统一通过 `lib/request/request.dart` 的 `Request` 封装，不直接在页面里创建裸 `Dio` 请求，除非是文件上传等已有工具已采用的例外场景。
- 新增请求方法放在对应 `services` 类中，页面只调用服务方法，不直接拼接复杂请求逻辑。
- 请求路径、参数名、返回结构必须与 `.api` 契约一致。
- 处理失败时检查 `code`，优先展示服务端 `msg`，同时提供合理默认文案。

## 缓存与实时能力

- 本地缓存优先使用项目封装的 `sharedPreferencesInstance` 和 `CacheKeys`，不要在业务代码里重复创建缓存实例。
- 登录态、用户信息、IM 登录等流程必须参考 `UserServices`、`EasemobServices` 的现有边界。
- 权限申请复用 `permission_handler` 和 `lib/tool/permission.dart` 的既有封装。
- 音频、视频、Agora、WebSocket、环信 IM 相关改动先阅读对应服务类和工具类文件，保持生命周期和异常处理一致。
- 进入后台、页面销毁、房间切换等场景必须释放频道、播放器、录音器、订阅和定时器。

## 验证清单

完成代码变更后，按影响面选择验证：

```bash
dart format .
flutter analyze
flutter test
```

如果修改了依赖，补充运行：

```bash
flutter pub get
```

若命令因网络、平台环境或生成冲突失败，说明已执行的命令、失败原因和后续建议；不要静默跳过。

## 输出要求

给用户总结时使用中文，说明改了哪些文件、完成了什么行为、验证了哪些命令。若存在未验证项或外部依赖阻塞，明确列出。
