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

### Flutter 原生布局优先

- 页面布局首先遵循 Flutter 官方 Box Constraints 模型： **Constraints go down. Sizes go up. Parent sets position.**
  父组件向子组件传递约束，子组件在约束内决定尺寸，最终由父组件决定位置。实现页面时必须先解决约束和空间分配，再处理视觉尺寸。
- **`flutter_screenutil` 仅作为 Figma 视觉尺寸辅助工具，不属于页面布局基础设施。** 页面结构、空间分配、响应式适配必须优先使用
  Flutter 原生 Constraints 布局体系；只有在确实需要把 375 宽 Figma 设计稿中的视觉常量映射到不同设备时才使用 ScreenUtil。
- **不得为了“项目已经引入 ScreenUtil”而强制使用 ScreenUtil。** 如果 Flutter 原生 logical
  pixels、父级约束或现有组件已经能正确表达设计意图，可以直接使用原生尺寸或布局能力，不要求额外添加 `.w` / `.h` / `.r`。
  **字体禁止使用 `.sp`。**
- 不得为了还原 Figma 而把所有 `width`、`height`、`padding`、`margin` 都机械转换成 `.w` / `.h`。
- 优先通过组件关系表达布局：
    - 横向/纵向排列使用 `Row`、`Column`、`Wrap`；
    - 剩余空间分配使用 `Expanded`、`Flexible`、`Spacer`；
    - 填满父级可用宽度优先使用父约束、`Expanded` 或 `double.infinity`，不要用 `375.w` 或手算屏幕宽度；
    - 固定宽高比的图片、视频、卡片优先使用 `AspectRatio`；
    - 尺寸需要受上下限约束时使用 `ConstrainedBox` / `SizedBox`；
    - 对齐和留白优先使用 `Align`、`Center`、`Padding`；
    - 内容可能超出一行时优先考虑 `Wrap`，不要依赖固定宽度硬塞；
    - 长列表/网格使用 `ListView.builder`、`GridView.builder` 或现有懒加载方案，避免一次性构建全部子项。
- `Expanded` / `Flexible` 只能在主轴约束有界的 `Row` / `Column` 中使用；处于 `ListView`、`SingleChildScrollView`
  等主轴无界场景时，先重新梳理约束，禁止通过随意增加固定高度来掩盖布局错误。
- 页面布局优先使用 `Column` / `Row` / `Wrap` 等常规布局； **非叠加关系不要使用 `Stack` / `Positioned`**。
  仅头像角标、浮层、悬浮按钮、图片覆盖文字等确有层叠关系时使用 `Stack`。

### 响应式与可用空间

- 响应式布局按 **当前实际可用空间**决定，不按“手机/平板”硬编码设备类型。
- 需要根据当前组件局部可用空间改变布局时，使用 `LayoutBuilder` 读取 `constraints.maxWidth` / `maxHeight`。
- 只有确实需要整个 App Window 尺寸时才使用 `MediaQuery.sizeOf(context)`；不要为了普通间距或组件宽度频繁读取屏幕尺寸。
- 需要断点布局时，根据可用宽度设置 breakpoint，再切换布局结构；禁止仅通过 ScreenUtil 比例把手机布局无限放大到平板或大屏。
- 状态栏、刘海、圆角屏、Home Indicator、系统导航区域使用 `SafeArea` / `MediaQuery` 处理， **禁止使用 `.w` / `.h`
  猜测安全区高度**。
- 键盘弹起导致的可用区域变化应结合 `Scaffold`、滚动容器和 `MediaQuery.viewInsetsOf(context)` 处理，不通过写死页面高度规避。

### Figma 375 设计稿与 ScreenUtil

- 本项目 Figma 移动端设计稿统一以 **375px 宽度** 为视觉基准。读取 Figma 标注时，默认按 375 宽设计稿理解。
- **375 仅是 Figma 视觉标注基准，不是 Flutter 页面固定宽度。** 页面实际宽度必须服从父级 Constraints 和当前可用空间，禁止因为设计稿宽度为
  375 就在页面中使用 `375.w`、固定 375 宽容器或按 375 手算布局。
- ScreenUtil 的定位是“设计稿视觉数值映射工具”，不是响应式布局方案；能通过 `Expanded`、`Flexible`、`AspectRatio`、
  `LayoutBuilder`、`SafeArea`、父级约束等 Flutter 原生能力解决的问题，不应交给 ScreenUtil。
- 项目继续沿用现有 `flutter_screenutil` 初始化； **业务页面不得重新初始化 ScreenUtil，也不得自行改变 `designSize`**。
  `designSize` 的高度以项目入口现有配置为准，设计稿“375 宽”不代表所有纵向尺寸都必须按屏幕高度同比缩放。
- ScreenUtil 使用原则：
    - `.w`：用于需要保持设计稿视觉尺度的宽度、横向间距、普通间距、图标尺寸、正方形图片尺寸等；
    - `.h`：仅用于设计意图明确要求“随可用屏幕高度比例变化”的尺寸； **不能因为属性叫 `height` 就机械使用 `.h`**；
    - `.r`：用于圆角、圆形/近似等比尺寸等项目已有场景；
    - **字体禁止使用 `.sp` 或其他 ScreenUtil 字体缩放方式。** Figma 标注字号直接作为 Flutter logical pixel 使用，例如设计稿
      `14px` 写为 `fontSize: 14`；
    - 普通纵向间距如果只是 Figma 中的视觉间距，优先沿用项目 `.w` 的统一视觉缩放方式，而不是默认 `.h`。
- 以下场景优先使用 Flutter 布局能力，而不是 ScreenUtil 计算：
    - 两个按钮平分一行：`Expanded`，不要分别计算按钮宽度；
    - 页面内容区域占满剩余高度：`Expanded` / `Flexible`，不要计算 `屏幕高度 - xxx.h`；
    - 全宽组件：父约束 / `double.infinity`，不要写 `375.w`；
    - 固定比例封面：`AspectRatio`，不要同时写死 `width: xxx.w` + `height: xxx.h`；
    - 安全区域：`SafeArea`，不要写固定底部 `35.w` / `35.h` 代替系统安全区；
    - 局部响应式布局：`LayoutBuilder`，不要只根据 `ScreenUtil().screenWidth` 推断。

### Figma 还原判断顺序

实现 Figma 页面时按以下顺序判断，禁止跳过布局设计直接套 ScreenUtil：

1. **先确定父子约束关系**：该区域是固定内容尺寸、填满剩余空间、按比例显示，还是可滚动内容。
2. **再确定布局组件**：优先从 `Row` / `Column` / `Wrap` / `Expanded` / `Flexible` / `AspectRatio` /
   `LayoutBuilder` / `SafeArea` 中选择合适方案。
3. **最后按需使用 ScreenUtil 做视觉尺寸映射**：仅将确实需要缩放的边距、图标、圆角等视觉值映射到当前设备； **字体不参与
   ScreenUtil 映射**。
4. 如果 Figma 固定尺寸与 Flutter 自适应布局发生冲突，优先保证 **无溢出、可滚动、安全区正确、长文本可用、不同屏宽可用**，
   再在约束允许范围内提高视觉还原度。

### 字体与文字缩放

- **字体大小统一使用 Flutter 原生 logical pixels，不使用 `flutter_screenutil`。** 禁止 `14.sp`、`16.sp` 等写法。
- Figma 375 宽设计稿中的字号标注直接对应 `TextStyle.fontSize` 数值，例如设计稿字号 14 使用 `fontSize: 14`。
- 字体是否因系统无障碍设置而缩放，交给 Flutter 自身的 `MediaQuery` / `TextScaler` 机制处理；业务页面不得通过 ScreenUtil
  修改或补偿字体比例。
- 不得为了视觉还原而全局关闭系统字体缩放；如特定组件确有固定字号需求，应先确认产品交互要求，并限制在最小范围内处理。
- 长文本、系统大字体下出现布局问题时，应优先通过 `Flexible`、`Expanded`、`Wrap`、`maxLines`、`TextOverflow`
  、可滚动布局等方式解决，而不是缩小字体或改用 `.sp`。

### 禁止项

- 禁止按照“宽度一律 `.w`、高度一律 `.h`”的规则机械转换 Figma 标注。
- 禁止大量 `Positioned(left: xx.w, top: xx.h)` 进行页面级绝对定位，除非设计本身就是明确叠加关系。
- 禁止通过 `MediaQuery.sizeOf(context).width - xx.w`、`ScreenUtil().screenWidth - xx.w` 等方式替代 `Expanded` / 父约束。
- 禁止为了修复 overflow 随意增加固定高度；必须先检查 `Row` / `Column` / ScrollView 的 bounded / unbounded constraints。
- 禁止使用固定 ScreenUtil 尺寸模拟系统状态栏、键盘、安全区域。
- 禁止仅按设备类型（phone/tablet）决定布局；需要差异化布局时按实际可用宽度判断。

### 项目 UI 约定

- 图片优先走 `assets/images/...` 已声明目录，并复用 `img`、`ImgConf` 等封装。
- 优先使用 `Cupertino` 组件（如 `CupertinoAlertDialog`、`CupertinoPicker`、`CupertinoActionSheet` 等），保持与项目现有 iOS
  风格一致；仅在 Cupertino 无法满足交互需求时回退到 Material 组件。
- 确认弹窗、底部弹出层、picker 等通用交互必须先在 `lib/widget/` 封装为公共组件，再暴露给外部调用；业务页面不直接散落
  `showDialog`、`showModalBottomSheet` 等原始调用。输入框、选择框、radio、列表 item 等常见 UI 同理，优先使用或封装公共组件。
- 页面布局优先保持现有产品风格，不新增突兀的卡片、过度渐变或不一致的圆角体系。
- 文案使用中文，错误和空状态提示要具体、可行动。
- 页面布局编码时必须着重考虑不同屏幕宽度及实际可用空间，并主动处理安全区域、长文本、系统字体缩放、键盘弹起、横向
  overflow、列表滚动和返回行为；不得先按固定尺寸完成页面后再以补丁方式处理这些适配问题。

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

### 第三方 pub 依赖变更

- 如需求需要新增第三方 pub 包，只修改 `pubspec.yaml` 中的依赖声明即可。
- **不要执行 `flutter pub get`、`dart pub get` 或其他依赖安装命令；由用户手动执行。**
- 新增依赖后，如果因为依赖尚未安装导致 `flutter analyze`、`flutter test` 或编译无法继续，应停止依赖相关验证，并在结果中明确说明：依赖已写入
  `pubspec.yaml`，尚未执行 `flutter pub get`，需用户手动执行后再验证。
- 不得通过 `flutter pub add` 自动修改依赖；应直接编辑 `pubspec.yaml`，以便用户审核具体版本和变更。

若命令因网络、平台环境或生成冲突失败，说明已执行的命令、失败原因和后续建议；不要静默跳过。

## 输出要求

给用户总结时使用中文，说明改了哪些文件、完成了什么行为、验证了哪些命令。若存在未验证项或外部依赖阻塞，明确列出。
