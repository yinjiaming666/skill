---
name: flutter-response-entity-cn
description: 仅在 Flutter 项目中且需要对接后端 API 并将响应映射为 Dart 实体类时触发；遵循本仓库 lib/model/response 风格（含普通对象、列表响应、分页响应），.g.dart 自动生成文件不在本技能处理范围内。
---

# Flutter 接口响应实体生成规范（中文）

当用户要求“根据接口返回值生成 Dart 实体类”时，必须遵循本技能。

## 0. 触发规则

本技能在以下两个条件同时满足时触发：

1. 当前任务是 Flutter 项目。
2. 正在对接后端 API 接口，且需要把接口返回值映射为 Dart 实体类对象。

## 1. 目标与边界

- 目标：生成可直接接入当前项目反序列化体系的实体 `.dart` 文件。
- 不处理：`.g.dart` 文件内容（由工具自动生成）。
- 目录约定：实体放在 `lib/model/response`（或其子目录）下。

## 2. 必须遵循的代码骨架

### 2.1 普通实体类

1. 必须有以下导入与导出（按需）：
   - `import 'dart:convert';`
   - `import 'package:app/generated/json/base/json_field.dart';`（仅当需要字段重命名）
   - `import 'package:app/generated/json/xxx_entity.g.dart';`
   - `export 'package:app/generated/json/xxx_entity.g.dart';`
2. 主体类使用 `@JsonSerializable()` 注解。
3. 字段默认使用“可用默认值”写法（与项目现状一致）：
   - `int` -> `0`
   - `String` -> `''`
   - `bool` -> `false`
   - `List<T>` -> `[]`
4. 接口字段为下划线命名时，使用 `@JSONField(name: 'xxx_yyy')` 映射。
5. 必须提供：
   - 空构造：`ClassName();`
   - `factory ClassName.fromJson(Map<String, dynamic> json) => $ClassNameFromJson(json);`
   - `Map<String, dynamic> toJson() => $ClassNameToJson(this);`
   - `toString()` 返回 `jsonEncode(this)`。

### 2.2 通用响应包装（按接口结构选用）

- 单对象或任意 `data`：`ApiResponse<T>`
- 列表 `data`：`ListRespEntity<T>`
- 分页 `data`：`PagedResponse<T>` + `PagedPayload<T>`

不要自行发明新的响应外壳，优先复用项目已有：
- `lib/model/response/resp_entity.dart`
- `lib/model/response/list_resp_entity.dart`
- `lib/model/response/page_resp_entity.dart`

### 2.3 响应基座三件套规则（R3-Response-Foundation）

以下规则专门针对你项目的 3 个基座文件：
- `lib/model/response/resp_entity.dart`
- `lib/model/response/page_resp_entity.dart`
- `lib/model/response/page_data_impl.dart`

`[R3-01] ApiResponse 泛型单体响应规则（Single Payload Contract）`
- `ApiResponse<T>` 只承载通用三元组：`code`、`msg`、`data`。
- `data` 必须保持泛型 `T?`，禁止在该文件内写具体业务类型。
- 必须保留 `factory fromJson` 与 `toJson` 委托到 `generated/json/base/resp_entity.base.dart`。
- `toString()` 统一使用 `jsonEncode(this)`。
- 底层实现类名可保留为 `RespEntity<T>`，但技能输出与新代码中统一使用 `ApiResponse<T>` 命名。

`[R3-02] PagedResponse 分页外壳规则（Paged Envelope Contract）`
- `PagedResponse<T>` 只负责分页响应外层：`code`、`msg`、`data`。
- `data` 类型必须是 `PagedPayload<T>`，并保持 `late` 初始化模式。
- 禁止把分页字段（如 `total/current_page`）直接平铺在 `PagedResponse<T>` 上。
- 必须保留 `factory fromJson` 与 `toJson` 委托到 `generated/json/base/page_resp_entity.dart`。
- 底层实现类名可保留为 `PageRespEntity<T>`，但技能输出与新代码中统一使用 `PagedResponse<T>` 命名。

`[R3-03] PagedDataContract 抽象分页协议规则（Paged Data Interface Contract）`
- `PagedDataContract` 只定义分页数据最小能力：`getList()` 与 `getTotal()`。
- 任意分页实体（当前为 `PagedPayload<T>`）都必须 `implements PagedDataContract`。
- `getList()` 返回列表数据语义，`getTotal()` 返回总条数语义，不得互换含义。
- 该接口保持轻量抽象，不新增业务字段，不耦合网络/UI。
- 底层实现名可保留为 `PageDataImpl`，但技能输出与新代码中统一使用 `PagedDataContract` 命名。

`[R3-04] PagedPayload<T> 统一字段规则（Paged Data Schema Contract）`
- `PagedPayload<T>` 必须包含：`total`、`perPage`、`currentPage`、`lastPage`、`data`。
- 下划线字段必须通过 `@JSONField` 映射：
  - `per_page -> perPage`
  - `current_page -> currentPage`
  - `last_page -> lastPage`
- `data` 必须使用 `List<T> data = [];` 默认空列表，避免空指针分支。
- `getList()` 返回 `data`，`getTotal()` 返回 `total`，保持语义稳定。
- 底层实现类名可保留为 `PageData<T>`，但技能输出与新代码中统一使用 `PagedPayload<T>` 命名。

`[R3-05] 基座文件改动边界规则（Foundation Change Boundary）`
- 新增业务接口实体时，默认不改这 3 个基座文件。
- 仅当后端响应协议发生“全局结构变化”时，才允许调整这 3 个文件。
- 若必须调整，优先保持向后兼容（旧字段/旧调用不立刻失效）。

## 3. 字段建模规则

1. 先按接口 JSON 原样建字段，再做命名映射，不要丢字段。
2. 嵌套对象直接声明为对应实体类型。
3. 嵌套列表使用 `List<实体类型> = [];`。
4. 字段类型不稳定且业务暂不关心时，可短期用 `dynamic`，但优先明确类型。
5. 允许在实体内补充业务只读 getter（如格式化展示），但不要在 `fromJson/toJson` 里写手工解析逻辑。

## 4. 服务层接入写法

保持与项目一致的调用方式：

```dart
final res = await Request().get('/xxx');
ApiResponse<UserEntity> result = ApiResponse.fromJson(res);
```

```dart
final res = await Request().get('/xxx/list');
ListRespEntity<ItemEntity> result = ListRespEntity.fromJson(res);
```

```dart
final res = await Request().get('/xxx/page');
PagedResponse<ItemEntity> result = PagedResponse.fromJson(res);
final list = result.data.data;
```

## 5. 生成时的执行清单

1. 判断响应形态：单对象 / 列表 / 分页。
2. 新建或更新 `lib/model/response/..._entity.dart`。
3. 补齐 `@JsonSerializable`、`@JSONField`、`fromJson/toJson/toString`。
4. 确认所有 `List` 字段有 `[]` 默认值，避免空列表判空分支泛滥。
5. 不创建、不修改 `.g.dart` 内容；仅保证主 `.dart` 可被生成工具处理。

## 6. FlutterJsonBeanFactory 工具补充规则

`[FJBF-01] 生成路径一致性规则（Generated Path Consistency）`
- 若项目配置了 `pubspec.yaml -> flutter_json.generated_path`，实体导入路径必须与该路径一致。
- 当前项目使用路径前缀 `package:app/generated/json/...`，新增实体时保持同一风格，不混用其他路径。

`[FJBF-02] 注解触发规则（Annotation Trigger Contract）`
- 仅对带 `@JsonSerializable()` 的类生成序列化辅助代码。
- 字段重命名必须使用 `@JSONField(name: 'xxx_yyy')`，不要使用其他注解体系替代。

`[FJBF-03] 泛型转换入口规则（Generic Conversion Entry）`
- 当网络层需要做泛型/列表泛型转换时，优先复用 `JsonConvert.fromJsonAsT` 或现有 `ApiResponse<T>/ListRespEntity<T>/PagedResponse<T>`。
- 不重复造新的泛型转换工具，避免与 `json_convert_content.dart` 的类型分发表冲突。

`[FJBF-04] 生成产物边界规则（Generated Artifact Boundary）`
- `lib/generated/json/**` 下文件视为生成产物，不手工长期维护业务逻辑。
- 允许通过重新生成刷新这些文件；禁止把业务规则直接写进生成文件。
- 当新增/修改实体字段后，必须触发一次生成流程以同步 `convertFuncMap` 与列表子类型分发。

`[FJBF-05] 自定义解析扩展规则（Custom JsonConvert Extension）`
- 需要特殊类型解析（如非标准时间格式）时，采用继承 `JsonConvert` 的方式扩展。
- 优先在 `asT/convert` 扩展点做兼容，不在实体 `fromJson` 中堆手写分支。

## 7. 命名强制规则

- 新增代码中统一使用：`ApiResponse`、`PagedResponse`、`PagedPayload`、`PagedDataContract`。
- 以下旧命名不再作为新增代码命名：`RespEntity`、`PageRespEntity`、`PageData`、`PageDataImpl`。
- 旧命名仅作为底层兼容实现存在，不作为技能输出的首选命名。

## 8. 禁止事项

- 禁止手写 `.g.dart`。
- 禁止引入与当前项目不一致的序列化框架写法。
- 禁止在实体层混入网络请求、UI 逻辑或副作用代码。
