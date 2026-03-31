---
name: thinkphp-dev
description: 辅助基于 ThinkPHP 框架的项目开发，涵盖 MySQL 数据库与 Redis 缓存。当用户要求创建或修改 PHP 代码、API 接口、或处理数据库/缓存逻辑时触发此技能。
---

# ThinkPHP 项目开发规范

本技能用于指导基于 ThinkPHP 5.* 框架、MySQL 数据库及 Redis 缓存的 PHP 项目开发。请在编写、修改代码时严格遵守以下规范：

## 1. 基础环境与代码风格

- **PHP 版本**: <= 8.0 (推荐使用 8.0)
- **ThinkPHP 版本**: 5.*
- **命名规范**: 所有方法名和变量名必须使用 `小驼峰命名法 (camelCase)`。
- **类型声明**: 所有方法和函数**必须**显式声明参数类型和返回值类型。如果方法没有返回值，则必须声明为 `: void`。例如：`public function getUserInfo(int $userId): array`
- **严格比较**: 所有的比较操作必须使用强类型比较 `===` 或 `!==`。
- **变量类型**: 变量类型要通过类型注释来声明，例如：`/** @var string $name */` 或者 `/** @var array{name: string, age: int} $user */`。

## 2. 目录架构与职责划分

- **API 控制器**: 生成在 `app/api/controller/` 目录下，并按模块或功能进行分类。默认生成的代码应为 API 接口，**无特殊要求下禁止**参考或依赖 `app/admin` 目录下的代码。
- **通用逻辑**: 业务逻辑应生成在 `app/common/logic/` 目录下，如果超过十行以上重复的代码，请封装为通用逻辑并保存在 `app/common/logic/` 目录下。
- **模型文件**: 生成在 `app/common/model/` 目录下。必须根据数据库字段为模型添加注释，格式为：`@property 字段类型 字段名 字段描述`。
- **Redis Key 管理**: Redis 的 key 必须**集中、统一**保存在 `app/common/logic/KeyUtils.php` 文件中，禁止在业务代码中硬编码 Redis Key。


## 3. 数据库与模型 (MySQL)

- **命名规范**: 数据库表名及字段名必须使用 `蛇形命名法 (snake_case)`。
- **主键规范**: 表主键必须命名为 `id`，类型为 `int(11)`，并且设置为自增。
- **模型实例化**: 操作数据库时，必须通过 `model(CLASSNAME)` 来获取模型实例。必须在获取实例的上一行增加类型注释，例如：
  ```php
  /** @var GameModel $game */
  $game = model(GameModel::class);
  ```
- **特殊字段与组件**: 
  - `weigh`: 权重排序
  - `create_time`/`update_time`: 自动维护时间戳
  - `_id`/`_ids`: 关联选择 (单/多选)
  - `image`/`images`: 图片上传 (单/多图)
  - `file`/`files`: 文件上传
  - `switch`/`toggle`: 开关组件
  - `status`/`state`: 单选框
  - `content`/`editor`: 富文本编辑器
  - `city`: 城市选择
  - `icon`: 图标选择
  - `color`: 颜色选择
  - `list`/`select`/`multi`: 下拉选择
- **注释字典**: 字段注释字典格式为 `标题:key=value,key=value` (如 `状态:0=禁用,1=启用`)。
- **数据上下文**: 数据库结构参考 `.trae/server.sql`，必须同步更新。所有生成的 SQL 语句**必须**记录在 `.trae/change.sql` 文件中。

## 4. 缓存操作 (Redis)

- **获取句柄**: 所有涉及到 Redis 缓存的地方，必须使用 `\think\Cache::init()->handler()` 获取 Redis 句柄来进行原生操作。

## 5. 控制器与 API 开发规范

- **参数获取**: 所有接口的请求参数必须设置默认值并指定类型强制转换。例如：`$this->request->post('id/d', 0)`。
- **异常与响应处理**:
  - 捕获异常时，必须在 `catch` 块中调用 `$this->error($e->getMessage())` 并**立即 `return`**。
  - 成功响应 `$this->success()` 必须在 `try-catch` 块**之外**调用。
- **方法注释**: 方法必须包含标准注释 `@param`、`@return`、`@throws` 以及 `@author ai`。
- **API 文档注释**: API 方法必须包含完整的文档标签，具体格式如下：

```php
    /**
     * 获取用户信息
     *
     * @param int $uid 用户ID
     * @return array
     * @throws ModelNotFoundException
     * @author ai 2023-08-01
     * @ApiTitle    (测试名称)
     * @ApiSummary  (测试描述信息)
     * @ApiMethod   (POST)
     * @ApiRoute    (/api/demo/test/id/{id}/name/{name})
     * @ApiParams   (name="name", type="string", required=true, description="用户名")
     * @ApiReturnParams   (name="code", type="integer", required=true, sample="0")
     * @ApiReturnParams   (name="msg", type="string", required=true, sample="返回成功")
     * @ApiReturnParams   (name="data", type="object", sample="", description="扩展数据返回")
     * @ApiReturnParams   (name="data.user_name", type="string", required=true, sample="张三", description="用户名")
     * @ApiReturnParams   (name="data.user_id", type="integer", required=true, sample="1", description="用户ID")
     * @ApiReturn   ({'code':'1','msg':'返回成功'})
     */
public function getUserInfo(int $uid): array
{
    // ...
}
```