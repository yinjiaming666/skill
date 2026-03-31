---
name: thinkphp-dev
description: 辅助基于 ThinkPHP 框架的项目开发，涵盖 MySQL 数据库与 Redis 缓存的最佳实践。当涉及创建或修改 PHP 代码、API 接口、数据库操作或缓存逻辑时触发此技能。
---

# ThinkPHP 项目开发规范

本技能指南旨在规范基于 ThinkPHP 5.* 框架、MySQL 数据库及 Redis 缓存的 PHP 项目开发流程。在编写或修改代码时，请严格遵循以下技术规范：

## 1. 基础环境与代码风格

- **PHP 版本**: <= 8.0 (强烈推荐使用 8.0 版本)
- **ThinkPHP 版本**: 5.*
- **命名规范**:
  - 所有方法名和变量名必须统一使用 `小驼峰命名法 (camelCase)`。
  - 不得使用拼音命名
  - 代码风格遵循 [PSR-12](https://www.php-fig.org/psr/psr-12/) 规范。
- **类型声明**:
  - 所有方法和函数**必须**显式声明参数类型与返回值类型。
  - 若方法无返回值，则必须声明为 `: void`。示例：`public function getUserInfo(int $userId): array`
- **严格比较**:
  - 代码中的逻辑判断必须使用强类型比较运算符 `===` 或 `!==`，避免隐式类型转换带来的隐患。
- **注释**:
  - 复杂结构或无法推断类型的变量，必须通过 PHPDoc 进行类型注释。示例：`/** @var string $name */` 或 `/** @var array{name: string, age: int} $user */`。
  - 注释风格参考 [PHPDoc](https://docs.phpdoc.org/latest/guide/references/phpdoc/tags/index.html)
  - 所有代码必须添加 PHPDoc 注释包含完整的参数类型、返回值类型及参数描述。
- **代码合入**:
  - 新增代码在提交前必须经过**严格**的语法与逻辑检查。
  - 新增的方法或函数应追加在对应文件或类的**末尾**。

## 2. 目录架构与职责划分

- **API 控制器 (`app/api/controller/`)**:
  - API 接口代码统一生成于此目录，并按业务模块进行分类。
  - 默认生成的代码仅限 API 接口层，**除非有特殊业务需求，否则严禁**参考或依赖 `app/admin` 目录下的后台代码。
- **通用逻辑 (`app/common/logic/`)**:
  - 核心业务逻辑必须下沉至此目录。
  - **重构原则**：若发现超过十行以上的重复代码，必须将其抽取封装为通用逻辑类并保存在此目录下。
- **模型文件 (`app/common/model/`)**:
  - 数据模型统一生成于此目录。
  - 必须基于数据库表结构为模型类添加详尽的属性注释。格式示例：`@property 字段类型 字段名 字段描述`。
- **Redis Key 管理**:
  - 系统中所有的 Redis Key 必须**集中、统一**维护在 `app/common/logic/KeyUtils.php` 文件中。
  - **严禁**在控制器或业务逻辑代码中硬编码 Redis Key。

## 3. 数据库与模型 (MySQL)

- **命名规范**: 数据库表名及字段名必须使用 `蛇形命名法 (snake_case)`。
- **主键规范**: 每张表必须包含名为 `id` 的主键，类型设为 `int(11)`，并开启自动递增 (`AUTO_INCREMENT`)。
- **模型实例化**:
  - 数据库操作必须通过 `model(CLASSNAME)` 助手函数获取模型实例。
  - 在实例化的上一行，必须添加模型类型的 PHPDoc 注释。示例：
    ```php
    /** @var GameModel $game */
    $game = model(GameModel::class);
    ```
- **特殊字段与组件约定**:
  - `weigh`: 权重排序
  - `create_time`/`update_time`: 自动维护的时间戳
  - `_id`/`_ids`: 关联选择 (单选/多选)
  - `image`/`images`: 图片上传 (单图/多图)
  - `file`/`files`: 文件上传
  - `switch`/`toggle`: 开关组件
  - `status`/`state`: 单选框状态
  - `content`/`editor`: 富文本内容
  - `city`: 城市选择
  - `icon`: 图标选择
  - `color`: 颜色选择
  - `list`/`select`/`multi`: 下拉选择
- **注释字典**:
  - 字段的注释必须包含状态字典，格式为 `标题:key=value,key=value`（例如 `状态:0=禁用,1=启用`）。
- **数据上下文与同步**:
  - 数据库的基础结构需参考 `.trae/server.sql`。
  - 表结构的任何变动必须保持同步，所有新增或修改的 SQL 语句**必须**记录在 `.trae/change.sql` 文件中。

## 4. 缓存操作 (Redis)

- **获取句柄**:
  - 所有涉及 Redis 缓存的操作，必须通过 `\think\Cache::init()->handler()` 获取 Redis 原生句柄进行交互，以保障性能与功能的完整性。

## 5. 控制器与 API 开发规范

- **参数获取与校验**:
  - 接口接收的所有参数必须设置合理的默认值，并指定类型的强制转换。示例：`$this->request->post('id/d', 0)`。
- **异常与响应处理**:
  - **异常捕获**：在 `catch` 块中捕获异常时，必须调用 `$this->error($e->getMessage())` 并**立即 `return`**。
  - **成功响应**：成功逻辑的返回 `$this->success()` 必须置于 `try-catch` 块**之外**调用，保持代码块的纯粹性。
- **方法注释**:
  - 业务方法必须包含标准的 PHPDoc 注释，涵盖 `@param`、`@return`、`@throws` 及 `@author` 标签。
- **API 文档注释**:
  - API 方法必须包含完整的路由、请求及返回参数的文档标签。具体格式规范如下：

```php
    /**
     * 获取用户信息
     *
     * @param int $uid 用户ID
     * @return array
     * @throws ModelNotFoundException
     * @author ai 2023-08-01
     * @ApiTitle    (获取用户信息)
     * @ApiSummary  (获取指定用户的详细描述信息)
     * @ApiMethod   (POST)
     * @ApiRoute    (/api/demo/test/id/{id}/name/{name})
     * @ApiParams   (name="name", type="string", required=true, description="用户名")
     * @ApiReturnParams   (name="code", type="integer", required=true, sample="1")
     * @ApiReturnParams   (name="msg", type="string", required=true, sample="返回成功")
     * @ApiReturnParams   (name="data", type="object", sample="", description="扩展数据返回")
     * @ApiReturnParams   (name="data.user_name", type="string", required=true, sample="张三", description="用户名")
     * @ApiReturnParams   (name="data.user_id", type="integer", required=true, sample="1", description="用户ID")
     * @ApiReturn   ({'code':1,'msg':'返回成功'})
     */
    public function getUserInfo(int $uid): array
    {
        // ...
    }
```