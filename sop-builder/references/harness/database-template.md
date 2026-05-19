# 数据库规范

> **规约定位**：DB schema 设计、迁移、查询、事务的硬性规则。
>
> **门禁联动**：migration 修改已应用文件 → PreCommit Hook 阻断；schema 变更未更新 [`docs/domain-model.md`](../docs/domain-model.md) → Review 阻断。

---

## 一、表设计规范

### 1.1 命名

| 实体 | 规则 | 示例 |
|---|---|---|
| 表名 | 蛇形小写复数 | `orders`, `order_items` |
| 字段名 | 蛇形小写 | `user_id`, `created_at` |
| 主键 | `id` (BIGINT UNSIGNED AUTO_INCREMENT) | - |
| 外键 | `<被引用表单数>_id` | `user_id`, `order_id` |
| 时间字段 | `xxx_at` 后缀 | `created_at`, `updated_at` |
| 布尔字段 | `is_xxx` / `has_xxx` 前缀 | `is_deleted`, `has_paid` |
| 索引 | `idx_<字段>` | `idx_user_id` |
| 唯一索引 | `uk_<字段>` | `uk_order_no` |

### 1.2 必备字段（所有业务表）

| 字段 | 类型 | 默认值 | 说明 |
|---|---|---|---|
| `id` | BIGINT UNSIGNED | AUTO_INCREMENT | 主键 |
| `created_at` | DATETIME | CURRENT_TIMESTAMP | 创建时间 |
| `updated_at` | DATETIME | CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP | 更新时间 |
| `deleted_at` | DATETIME | NULL | 软删除时间（如使用软删除） |

### 1.3 字段设计原则

- ✅ **必须** NOT NULL，有默认值；除非业务确实允许 NULL
- ✅ 金额用 `BIGINT`（单位：分）或 `DECIMAL(20, 4)`，**不用** `FLOAT/DOUBLE`
- ✅ 枚举用 `TINYINT UNSIGNED` + 注释说明每个值含义
- ✅ 字符串预估最大长度，避免 `VARCHAR(255)` 一把梭
- ❌ 禁止 `TEXT` / `BLOB` 大字段进核心表（独立子表存储）
- ❌ 禁止用 `ENUM` 类型（数据库 ENUM，扩展时痛苦）

---

## 二、索引规范

### 2.1 必须建索引的字段

- 主键字段（默认）
- 外键字段
- 高频 WHERE 查询字段
- ORDER BY 字段
- JOIN 字段

### 2.2 索引设计原则

- ✅ 复合索引遵循**最左前缀**原则
- ✅ 区分度低的字段（如 `is_deleted`）不单独建索引
- ❌ 禁止给所有字段都建索引（写性能下降）
- ❌ 索引数量单表不超过 5 个

### 2.3 索引变更

新增 / 删除索引 → 评估线上影响 → 走 migration 流程。

---

## 三、Migration 规范（**核心强约束**）

### 3.1 文件命名

```
migrations/
├── 20240101_120000_create_orders_table.sql
├── 20240102_153000_add_status_to_orders.sql
└── 20240103_090000_create_idx_user_id_on_orders.sql
```

格式：`YYYYMMDD_HHMMSS_<动作>_<表名>.sql`

### 3.2 硬性规则（PreCommit Hook 强制）

- ❌ **禁止修改已应用的 migration 文件**（即使是空格变化）
- ❌ **禁止删除已应用的 migration 文件**
- ❌ **禁止跳号**（保持时间序）
- ✅ 字段变更必须**新建** migration，不修改旧的
- ✅ Migration 必须**幂等**：`CREATE TABLE IF NOT EXISTS` / `ADD COLUMN IF NOT EXISTS`

### 3.3 允许的 Migration 操作

- ✅ ADD COLUMN（带默认值）
- ✅ CREATE INDEX
- ✅ CREATE TABLE
- ⚠️ DROP COLUMN（必须先停止读写 + 灰度）
- ⚠️ MODIFY COLUMN（类型变更必须确认无数据丢失）
- ⚠️ RENAME（必须双写过渡）
- ❌ DROP TABLE（必须走 RFC）

### 3.4 大表变更

> 单表数据量 > 1000 万行的变更需走单独流程。

- ✅ 用 `pt-online-schema-change` 或 `gh-ost`
- ✅ 避开业务高峰
- ✅ DBA 评审

---

## 四、SQL 编写规范

### 4.1 禁止行为

- ❌ `SELECT *`（必须列出具体字段）
- ❌ 在 WHERE 字段上做函数运算（破坏索引）
- ❌ 隐式类型转换（`WHERE user_id = '123'`，user_id 是 int）
- ❌ 不带 WHERE 的 UPDATE / DELETE
- ❌ 跨库 JOIN

### 4.2 必做

- ✅ 写预期影响行数大的 SQL 前用 EXPLAIN 验证
- ✅ 复杂 SQL 在注释中说明意图
- ✅ 用参数化查询，**禁止字符串拼接 SQL**（SQL 注入）

---

## 五、事务规范

### 5.1 事务边界

- ✅ 事务在 Service 层开启与提交，**禁止在 Handler 或 Repo 层管理事务**
- ✅ 事务范围**尽量小**，避免长事务
- ❌ 禁止在事务内：调用外部 RPC、发送 MQ、调用 HTTP

### 5.2 MQ 与事务的关系

```
事务提交 → 发 MQ                  ✅ 推荐
事务内发 MQ → 事务回滚导致脏消息    ❌ 错误
本地消息表 / 事务消息              ✅ 强一致场景
```

详见 [`harness/api-standards.md`](./api-standards.md) MQ 章节。

---

## 六、读写分离与缓存

### 6.1 读写分离

- 强一致读 → 走主库
- 弱一致读（列表、详情查询）→ 走从库
- 注意主从延迟

### 6.2 缓存策略

| 策略 | 适用场景 |
|---|---|
| Cache-Aside | 通用读多写少 |
| Write-Through | 强一致 |
| 缓存预热 | 大促前热点数据 |

**Key 命名**：`<业务域>:<实体>:<id>`，例：`order:detail:12345`

**TTL**：必须设置，禁止永久缓存（避免内存堆积）

---

## 七、AI 行为约束

- AI **禁止修改已应用的 migration 文件**
- AI 涉及 schema 变更必须**先读** [`docs/domain-model.md`](../docs/domain-model.md)
- AI **禁止** `SELECT *`
- AI **禁止字符串拼接 SQL**
- AI 新增字段必须**给默认值或允许 NULL**
- AI 涉及大表（> 1000 万行）变更必须**停下来与用户确认**

---

## 八、参考

- 详细领域模型见 [`docs/domain-model.md`](../docs/domain-model.md)
- 配置规范见 [`harness/deployment.md`](./deployment.md)
