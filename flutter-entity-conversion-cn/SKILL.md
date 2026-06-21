---
name: flutter-entity-conversion-cn
description: 中文 Flutter 响应实体类转换与 JSON 解析规范。用于在 Flutter/Dart 项目中根据后端 JSON 或 .api 契约创建、修改、评审响应实体，复用项目模板内置的 RespEntity/ListRespEntity/PageRespEntity 响应包装对象，并按 FlutterJsonBeanFactory 风格生成主实体、generated/json 辅助文件、泛型解析和服务层调用示例。
---

# Flutter 实体类转换规范

## 基本原则

涉及后端响应实体、JSON 字段映射、泛型响应解析、列表响应、分页响应时使用本 skill。实现前先读取 `.api` 契约和相邻实体文件，优先复用项目现有 `RespEntity<T>`、`ListRespEntity<T>`、`PageRespEntity<T>`、`@JsonSerializable()`、`@JSONField` 风格。

本项目实体模板参考 `lib/model/response/amount_log_entity.dart`，import 默认固定使用 `package:app`。

## 文件放置

- 项目模板已内置响应包装对象，不在本 skill 中重新定义或初始化这些基础文件。
- 业务开发时默认复用以下模板文件：
  - `lib/model/response/resp_entity.dart`
  - `lib/model/response/list_resp_entity.dart`
  - `lib/model/response/page_resp_entity.dart`
  - `lib/model/response/page_data_impl.dart`
  - `lib/generated/json/base/resp_entity.base.dart`
  - `lib/generated/json/base/list_resp_entity.dart`
  - `lib/generated/json/base/page_resp_entity.dart`
- 主实体放在 `lib/model/response/` 或业务子目录，例如 `lib/model/response/amount_log_entity.dart`。
- 业务实体的生成文件放在 `lib/generated/json/`，文件名与主实体对应，例如 `amount_log_entity.g.dart`。
- `generated/json/base/json_field.dart`、`generated/json/base/json_convert_content.dart` 由 FlutterJsonBeanFactory 维护，不手写。
- 若实体属于列表或分页接口，服务层解析时复用模板提供的响应包装类，不在页面里直接解析原始 `Map`。

## 模板内置响应对象使用约定

模板中的响应包装对象只作为统一解析入口使用，新增业务实体时不要复制这些基础类，也不要为单个接口另建重复的响应包装结构。

- `RespEntity<T>`：用于 `data` 是单个对象、基础值或可空结果的接口。
- `ListRespEntity<T>`：用于 `data` 是数组的接口。
- `PageRespEntity<T>` / `PageData<T>`：用于 `data` 包含分页字段和列表数据的接口。
- `PageData<T>` 已实现 `PageDataImpl`，页面或通用列表组件需要统一读取列表和总数时，直接使用 `getList()` / `getTotal()` 或访问 `data` / `total`。
- generated/base 中的响应包装辅助文件属于模板基础设施；只有模板升级或 FlutterJsonBeanFactory 重新生成时才同步修改，不在业务实体任务中手写。

## 主实体示例

按 `amount_log_entity.dart` 的结构生成或调整实体：

```dart
import 'dart:convert';

import 'package:app/generated/json/amount_log_entity.g.dart';
import 'package:app/generated/json/base/json_field.dart';

@JsonSerializable()
class AmountEntity {
  int id = 0;
  @JSONField(name: 'user_id')
  int userId = 0;
  String money = '';
  String before = '';
  String after = '';
  String memo = '';
  @JSONField(name: 'create_time')
  int createTime = 0;
  int type = 0;
  @JSONField(name: 'create_time_text')
  String createTimeText = '';
  @JSONField(name: 'type_text')
  String typeText = '';

  AmountEntity();

  factory AmountEntity.fromJson(Map<String, dynamic> json) => $AmountEntityFromJson(json);

  Map<String, dynamic> toJson() => $AmountEntityToJson(this);

  @override
  String toString() {
    return jsonEncode(this);
  }
}
```

替换规则：

- `AmountEntity` 替换为业务实体类名，例如 `UserEntity`、`GoodsOrderEntity`。
- `amount_log_entity.g.dart` 替换为当前实体对应的生成文件名。
- 后端字段为下划线时，Dart 字段使用驼峰，并用 `@JSONField(name: 'server_field')` 保留原始字段名。
- 基础字段给安全默认值：`int = 0`、`double = 0`、`String = ''`、`bool = false`。
- 对象、数组、可空字段按业务决定是否 nullable；避免页面层到处兜底。

## 生成文件示例

生成文件由 FlutterJsonBeanFactory 生成。Codex 不手写这类文件，但评审或排查时按以下结构核对：

```dart
import 'package:app/generated/json/base/json_convert_content.dart';
import 'package:app/model/response/amount_log_entity.dart';

AmountEntity $AmountEntityFromJson(Map<String, dynamic> json) {
  final AmountEntity amountEntity = AmountEntity();
  final int? id = jsonConvert.convert<int>(json['id']);
  if (id != null) {
    amountEntity.id = id;
  }
  final int? userId = jsonConvert.convert<int>(json['user_id']);
  if (userId != null) {
    amountEntity.userId = userId;
  }
  final String? money = jsonConvert.convert<String>(json['money']);
  if (money != null) {
    amountEntity.money = money;
  }
  final int? createTime = jsonConvert.convert<int>(json['create_time']);
  if (createTime != null) {
    amountEntity.createTime = createTime;
  }
  return amountEntity;
}

Map<String, dynamic> $AmountEntityToJson(AmountEntity entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['id'] = entity.id;
  data['user_id'] = entity.userId;
  data['money'] = entity.money;
  data['create_time'] = entity.createTime;
  return data;
}
```

## 服务层调用示例

普通对象响应：

```dart
static Future<AmountEntity?> getAmountDetail({required int id}) async {
  final Request request = Request();
  final Map<String, dynamic> res = await request.get('/index/getAmountDetail', data: {'id': id});
  final RespEntity<AmountEntity> result = RespEntity.fromJson(res);
  if (result.code != HttpRespCode.success.val) {
    ToastHelper.showToast(msg: result.msg ?? '获取详情失败');
    return null;
  }
  return result.data;
}
```

列表响应：

```dart
static Future<List<AmountEntity>> getAmountList({int type = 0}) async {
  final Request request = Request();
  final Map<String, dynamic> res = await request.get('/index/getAmountList', data: {'type': type});
  final ListRespEntity<AmountEntity> result = ListRespEntity.fromJson(res);
  if (result.code != HttpRespCode.success.val) {
    ToastHelper.showToast(msg: result.msg.isNotEmpty ? result.msg : '获取列表失败');
  }
  return result.data;
}
```

分页响应：

```dart
static Future<PageData<AmountEntity>> getAmountLog({int page = 1, int limit = 20, int type = 0}) async {
  final Request request = Request();
  final Map<String, dynamic> res = await request.get(
    '/index/getAmountLog',
    data: {'page': page, 'limit': limit, 'type': type},
  );
  final PageRespEntity<AmountEntity> result = PageRespEntity.fromJson(res);
  if (result.code != HttpRespCode.success.val) {
    ToastHelper.showToast(msg: result.msg ?? '获取金额记录失败');
  }
  return result.data;
}
```

页面调用服务层：

```dart
Future<void> _loadAmountLog() async {
  final PageData<AmountEntity> pageData = await UserServices.getAmountLog(page: 1, limit: 20);
  if (!mounted) {
    return;
  }
  setState(() {
    items = pageData.data;
  });
}
```

## 检查清单

- 业务实体复用项目模板内置的 `RespEntity`、`ListRespEntity`、`PageRespEntity` 及对应 generated/base 文件，不在业务任务中重复初始化这些基础对象。
- 主实体 import、类名、生成函数名、文件名保持一致。
- 后端下划线字段必须用 `@JSONField` 映射。
- 生成文件与主实体字段同步，不提交过期辅助文件。
- 服务层统一解析响应并处理失败提示，页面层只消费类型化结果。
- 涉及接口新增或变更时，同步 `.api` 契约。
- 完成后运行 `dart format .` 和 `flutter analyze`；若只改 skill 文档，校验 YAML 即可。
