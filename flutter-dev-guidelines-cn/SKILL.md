---
name: flutter-dev-guidelines-cn
description: 中文 Flutter 项目通用开发规范（含实体类转换与路由配置规范）。用于 Flutter/Dart 项目新增或修改页面、组件、状态管理、网络请求、响应实体转换、JSON 解析、fluro 路由、资源样式、权限音视频、WebSocket 与缓存时，指导按项目既有结构和约定实施代码变更。
---

# Flutter 项目开发规范

## 基本原则

使用本 skill 时，以“贴合现有项目”为第一优先级。修改前先阅读相关目录和相邻文件，复用当前项目已有的命名、分层、工具类和交互方式；只在确有必要时引入新抽象或新依赖。

本项目当前以 `lib/pages`、`lib/services`、`lib/model`、`lib/request`、`lib/tool`、`lib/widget` 分层，常用依赖包括 `provider`、
`dio`、`fluro`、`flutter_screenutil`、`easy_refresh`、`event_bus`、`web_socket_channel`、`agora_rtc_engine`、
`permission_handler` 等。新增功能应优先落入这些既有边界。

## 修改前检查

1. 查找同类页面、同类服务方法、同类组件和工具类写法时，优先使用 codegraph（MCP `codegraph_explore` 或 `codegraph explore`）；无
   `.codegraph/` 索引或查不到时再用 `rg --files` 和 `rg`。
2. 阅读 `pubspec.yaml`、`analysis_options.yaml`，确认依赖、资源目录和 lint 规则。
3. 涉及接口时，先阅读 `.api` 契约；若创建或修改接口调用，必须同步 `.api` 契约。
4. 涉及响应实体时，阅读 `entity-conversion/rules.md` 按规范执行。
5. 涉及路由时，阅读 `route-guidelines/rules.md` 按规范执行。
6. 涉及样式时，先查看相邻页面和 `lib/widget` 公共组件，复用 `CommonWidget`、`ToastHelper`、`ImgHelper` 等现有工具。

## 目录与命名

- 一个页面一个文件，入口文件通常命名为 `index.dart`，子页面按业务语义命名；仅当前页面使用的私有组件放在同文件内，不单独建文件。
- 业务请求封装放在 `lib/services/<module>_services.dart`，服务类使用静态方法时沿用现有风格。
- 通用 UI 放在 `lib/widget/`，纯工具方法放在 `lib/tool/`；被多个页面复用的 UI 尽可能抽成公共组件放入 `lib/widget/`
  ，避免各页面重复实现。
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
- 页面布局优先使用 `Column`/`Row`/`Wrap` 等线性布局，非必须不使用 `Stack`；确需叠加层时才用 `Stack`，并说明原因。
- 优先使用 `Cupertino` 组件（如 `CupertinoAlertDialog`、`CupertinoPicker`、`CupertinoActionSheet` 等），保持与项目现有 iOS
  风格一致；仅在 Cupertino 无法满足交互需求时回退到 Material 组件。
- 确认弹窗、底部弹出层、picker 等通用交互必须先在 `lib/widget/` 封装为公共组件，再暴露给外部调用；业务页面不直接散落
  `showDialog`、`showModalBottomSheet` 等原始调用。输入框、选择框、radio、列表 item 等常见 UI 同理，优先使用或封装公共组件。
- 页面布局优先保持现有产品风格，不新增突兀的卡片、过度渐变或不一致的圆角体系。
- 文案使用中文，错误和空状态提示要具体、可行动。

## 实体类转换

涉及后端响应实体、JSON 字段映射、泛型响应解析、列表/分页响应时使用本细则。完整规范（文件放置、模板内置响应对象使用约定、主实体/生成文件/服务层调用示例、检查清单）见
`entity-conversion/rules.md`。

核心要点：

- 统一复用项目模板内置的 `RespEntity<T>`、`ListRespEntity<T>`、`PageRespEntity<T>` / `PageData<T>`，不复制基础类，不为单接口另建包装结构。
- 主实体放在 `lib/model/response/`，生成文件放在 `lib/generated/json/`，文件名与类名保持一致。
- 后端下划线字段用驼峰 + `@JSONField(name: 'server_field')` 映射，基础字段给安全默认值。
- 生成文件由 FlutterJsonBeanFactory 生成，不手写。
- 服务层统一解析响应并处理失败提示，页面层只消费类型化结果。

## 路由规范

涉及路由路径、页面注册、页面跳转、清栈/替换跳转、无 `context` 跳转、返回传参、页面参数读取时使用本细则。完整规范（路由接入、Routes
配置、readArguments、RouterHelper、跳转与接收参数示例、检查清单）见 `route-guidelines/rules.md`。

核心要点：

- 路由基于 `fluro`，路径统一在 `lib/router.dart` 的 `Routes` 中维护：import 页面 → 新增路径常量 → `_initRouter()` 中
  `router.define`。
- 跳转统一走 `RouterHelper.push`、`switchTab`、`pushWithNoContext`、`back`，不散落 `Routes.router.navigateTo`。
- 参数通过 `RouteSettings.arguments` 传递，读取用 `readArguments<T>(context, 'key')`，key 两边保持一致。
- 路由注册时给参数默认值，避免缺失导致崩溃；异步回调后跳转前检查 `context.mounted`。

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

涉及业务逻辑变更时运行 `flutter test` 相关用例；若项目尚无测试目录或外部依赖阻塞，说明原因即可。

如果修改了依赖，补充运行：

```bash
flutter pub get
```

若命令因网络、平台环境或生成冲突失败，说明已执行的命令、失败原因和后续建议；不要静默跳过。

## 输出要求

给用户总结时使用中文，说明改了哪些文件、完成了什么行为、验证了哪些命令。若存在未验证项或外部依赖阻塞，明确列出。
