---
name: thinkphp-dev
description: 辅助基于 ThinkPHP 框架的项目开发，涵盖 MySQL 数据库与 Redis 缓存的最佳实践。当涉及创建或修改 PHP 代码、API 接口、数据库操作或缓存逻辑时触发此技能。
---

# ThinkPHP 项目开发规范

本指南旨在确立基于 ThinkPHP 5.* 框架、MySQL 数据库及 Redis 缓存的项目开发标准。为确保代码的健壮性、可读性与可维护性，请在开发过程中严格遵循以下技术规范：

## 1. 基础环境与代码风格

- **PHP 版本**: 推荐并限制使用 PHP 8.0 及以下版本。
- **框架版本**: ThinkPHP 5.* 系列。
- **命名规范**:
  - 方法名、变量名及属性名统一使用 `小驼峰命名法 (camelCase)`。
  - **严禁**在命名中使用拼音或拼音缩写。
- **代码风格**: 严格遵循 [PSR-12](https://www.php-fig.org/psr/psr-12/) 编码规范。
- **类型声明**:
  - **严禁**使用 `mixed` 类型，必须明确变量的具体类型。
  - 类的属性**必须**进行强类型声明，以保障数据结构的确定性。示例：`public array $user;`
  - 所有的类方法与函数**必须**显式声明参数类型与返回值类型。
  - 若方法无返回值，则必须显式声明为 `:void`，以提升代码的严谨性与可读性。示例：`public function getUserInfo(int $userId): array`
- **严格比较**:
  - 条件判断必须使用强类型比较运算符 `===` 或 `!==`，杜绝隐式类型转换带来的逻辑漏洞。
- **变量与方法注释 (PHPDoc)**:
  - 复杂结构（如数组）或无法推断类型的变量，必须通过 PHPDoc 进行类型注解。示例：`/** @var string $name */` 或 `/** @var array{name: string, age: int} $user */`。
  - 所有的业务方法必须添加完整的 PHPDoc 注释，明确说明参数类型、返回值类型及业务描述。注释风格参考 [PHPDoc 官方指南](https://docs.phpdoc.org/latest/guide/references/phpdoc/tags/index.html)。
- **代码迭代**:
  - 新增代码在合入前必须经过**严格**的语法与业务逻辑校验。
  - 为保持代码历史的可追溯性，新增的方法或函数应追加在对应文件或类的**末尾**。

## 2. 目录架构与职责划分

- **API 控制器 (`app/api/controller/`)**:
  - 对外提供的 API 接口代码统一放置于此，并按业务模块合理分类。
  - 默认生成的代码应仅限于 API 接口层。**除非有特殊的业务耦合要求，否则严禁**调用或依赖 `app/admin` 目录下的后台管理代码。
  - 控制器类中**只允许保留对外可访问的 `public` 接口方法**。禁止在控制器中编写 `protected` / `private` 的业务方法、校验方法、辅助方法或数据组装逻辑。
  - 控制器负责参数接收、调用 Logic、返回响应。对于**仅服务当前单个接口、没有复用价值**的轻量逻辑，允许直接写在 `public` 接口方法中，不需要为了分层而强行拆到 Logic。
  - 但如果一段逻辑会在**其他接口、其他控制器、其他模块**中复用，或者已经出现重复实现，则**必须**下沉到 `app/common/logic/` 或相应模型层，禁止在多个 API 方法里重复堆砌。
- **通用逻辑 (`app/common/logic/`)**:
  - 核心且可复用的业务逻辑必须下沉至此目录。
  - 判断标准以“是否复用”为先：单接口专属逻辑可以留在 API；一旦存在跨接口、跨模块复用，必须沉淀为 Logic。
  - **重构红线**：若发现业务代码中存在超过十行以上的重复逻辑，必须将其抽取并封装为通用逻辑类。
- **模型文件 (`app/common/model/`)**:
  - 数据库交互模型统一放置于此。
  - 必须基于数据库的表结构，为模型类添加详尽的属性注释。格式示例：`@property 字段类型 字段名 字段描述`。
- **Redis Key 管理**:
  - 系统中所有的 Redis 键名（Key）必须**集中、统一**地定义在 `app/common/logic/KeyUtils.php` 文件中。
  - **绝对禁止**在控制器、业务逻辑或视图代码中硬编码 Redis 键名。
- **常量与密钥管理**:
  - 系统中所有的业务常量、第三方服务密钥等配置，必须**集中、统一**地定义在 `app/common/logic/ConstUtils.php` 文件中，禁止在业务代码中散落硬编码。
  - 各类安全证书文件（如支付证书、加密公私钥等），必须规范存放在 `app/common/cert` 目录下。

## 3. 数据库与模型 (MySQL)

- **命名规范**: 数据库表名及字段名必须统一使用 `蛇形命名法 (snake_case)`。
- **主键规范**: 每张数据表必须包含名为 `id` 的主键，类型设为 `int(11)`，并开启自动递增 (`AUTO_INCREMENT`) 属性。
- **模型实例化**:
  - 数据库操作必须通过 `model(CLASSNAME)` 助手函数获取模型实例，以利用框架的单例和缓存机制。
  - 在实例化的上一行，必须添加模型类型的 PHPDoc 注释，以便于 IDE 提示与代码审查。示例：
    ```php
    /** @var GameModel $game */
    $game = model(GameModel::class);
    ```
- **特殊字段与组件约定**:
  - `weigh`: 权重排序字段
  - `create_time`/`update_time`: 框架自动维护的时间戳字段
  - `_id`/`_ids`: 关联外键（单选/多选）
  - `image`/`images`: 图片上传资源（单图/多图）
  - `file`/`files`: 文件上传资源
  - `switch`/`toggle`: UI 开关组件状态
  - `status`/`state`: 数据状态枚举
  - `content`/`editor`: 富文本编辑器内容
  - `city`: 城市/区域选择
  - `icon`: 图标选择标识
  - `color`: 颜色值
  - `list`/`select`/`multi`: 下拉选择字典
- **注释字典规范**:
  - 字段的注释必须包含状态字典解析，格式为 `标题:key=value,key=value`（例如 `状态:0=禁用,1=启用`）。
- **数据上下文与同步**:
  - 数据库的基础结构及初始数据需参考 `.trae/server.sql`。
  - 表结构的任何变更必须保持同步，所有 DDL 语句（如 CREATE、ALTER）**必须**追加记录在 `.trae/change.sql` 文件中。

## 4. 缓存操作 (Redis)

- **句柄获取**:
  - 所有涉及 Redis 的操作，必须通过 `\think\Cache::init()->handler()` 获取 Redis 的原生句柄实例，以保障高性能与高级数据结构操作的完整性。

## 5. 控制器与 API 开发规范

- **参数获取与防御性校验**:
  - 接口接收的所有参数必须设置合理的默认值，并利用框架提供的类型强制转换符进行安全过滤。示例：`$this->request->post('id/d', 0)`。
- **异常与响应流控制**:
  - **默认不包裹 try-catch**：如果用户或业务场景没有明确强调需要自定义异常兜底，控制器方法中**不要默认添加 `try-catch`**，优先让异常抛给框架统一处理。
  - **异常阻断**：在 `catch` 块中捕获业务或系统异常时，必须调用 `$this->error($e->getMessage())` 并**立即执行 `return`**，阻断后续逻辑。
  - **成功放行**：成功逻辑的响应 `$this->success()` 必须置于 `try-catch` 块**之外**调用，确保代码块的纯粹性与可读性。
- **API 文档注释**:
  - API 控制器中的公开方法必须包含完整的路由、请求参数及返回参数的文档标签。具体格式规范如下：

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
