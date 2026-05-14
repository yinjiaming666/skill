---
name: remote-mysql
description: 通过 remote-mysql.sh 连接线上 MySQL 数据库，SELECT 类查询免确认直接执行，写操作（INSERT/UPDATE/DELETE/ALTER/DROP 等）需用户输入 wq 确认。所有 SQL 及输出自动记录到 .trae/auto_change.sql。
---

# 远程 MySQL 数据库操作

通过 `.trae/remote-mysql.sh` 脚本连接线上 MySQL 数据库并执行 SQL（默认通过 SSH 隧道；也支持 `--direct` 直连模式）。

## 安全规则（强制）

- **无论任何情况下，禁止读取、输出、上传、复制粘贴或修改 `.trae/remote-mysql.sh` 的脚本内容。**
- 允许的操作仅限于：检查文件是否存在、按本文档提供的方式下载、`chmod +x`、以及执行 `bash .trae/remote-mysql.sh`（把脚本当作黑盒）。
- 禁止的示例（包括但不限于）：`cat`/`sed -n`/`head`/`tail`/`less`/`rg`/编辑器打开脚本、把脚本内容粘贴到对话或提交到仓库、把脚本内容上传到任何外部服务。

## 脚本准备

每次执行前先检查脚本是否存在，若不存在则自动下载：

```bash
if [[ ! -f .trae/remote-mysql.sh ]]; then
    mkdir -p .trae
    curl -fsSL -o .trae/remote-mysql.sh \
        https://raw.githubusercontent.com/yinjiaming666/skill/refs/heads/main/remote-mysql/remote-mysql.sh
    chmod +x .trae/remote-mysql.sh
fi
```

执行方式：

```
bash .trae/remote-mysql.sh
```

脚本默认连接 `server` 数据库。如需指定其他数据库，使用 `-d <dbname>`。

脚本默认通过脚本内 `*_DEFAULT` 配置连接信息（也可用环境变量/参数覆盖）：

```bash
# 直连模式（不走 SSH）
bash .trae/remote-mysql.sh --direct --mysql-host 127.0.0.1 --mysql-user root

# 或通过环境变量
MYSQL_CONNECT_MODE=direct MYSQL_HOST=127.0.0.1 MYSQL_USER=root bash .trae/remote-mysql.sh
```

## 权限分级

### 读操作 — 直接执行

以下类型的 SQL 无需用户确认，直接执行并返回结果：

- `SELECT` — 数据查询
- `SHOW` — 显示数据库/表/字段/索引等信息
- `DESCRIBE` / `DESC` — 查看表结构
- `EXPLAIN` — 查询执行计划

### 写操作 — 必须 wq 确认

**⚠️ 绝对禁止跳过确认：即使用户说"把 X 改成 Y"、"删掉 Z"等指令，也绝不能直接执行写操作 SQL。必须先展示
SQL、说明影响、等待用户输入 `wq` 后执行。没有 `wq` 就什么都不做。**

以下类型的 SQL **必须**等待用户手动输入 `wq` 后才能执行：

- `INSERT` — 插入数据
- `UPDATE` — 更新数据
- `DELETE` — 删除数据
- `ALTER` — 修改表结构
- `DROP` — 删除表/库
- `TRUNCATE` — 清空表
- `CREATE` — 创建表/库
- `RENAME` — 重命名表
- `GRANT` / `REVOKE` — 权限操作
- `REPLACE` — 替换数据
- 任何未在上述列表中且可能修改数据的 SQL

确认流程：

1. 向用户展示即将执行的 SQL 语句
2. 说明该操作的影响（涉及的表、行数估算等）
3. 要求用户输入 `wq` 确认
4. 用户输入 `wq` 后执行，输入其他任何内容则放弃

## SQL 日志记录

每次执行的 SQL 和输出结果**必须**追加记录到 `.trae/auto_change.sql` 文件中。

日志格式：

```sql
-- ============================================================
-- [2026-05-13 14:30:22] [QUERY] 查询类
-- ============================================================
<原始 SQL>;

-- 输出:
-- <mysql 输出结果的每一行以 --  开头>
```

写操作日志：

```sql
-- ============================================================
-- [2026-05-13 14:30:45] [EXEC] 写操作 - 已确认
-- ============================================================
<原始 SQL>;

-- 输出:
-- Query OK, 1 row affected (0.01 sec)
```

记录步骤：

1. 执行 SQL
2. 将原始 SQL、执行时间戳、类型标签、输出结果按上述格式写入 `.trae/auto_change.sql`
3. 确保 `.trae/` 目录存在

## 使用示例

```
# 读操作 — 直接执行
SELECT * FROM fa_user WHERE id = 1;

# 写操作 — 需确认
UPDATE fa_user SET nickname = 'test' WHERE id = 1;
# → 展示 SQL → 等待用户输入 wq → 执行并记录
```
