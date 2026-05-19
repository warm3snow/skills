# API 设计规范

> **规约定位**：本服务对外接口（HTTP / RPC / MQ）的设计规则与兼容策略。
>
> **门禁联动**：接口变更未更新文档 → Review 阻断；不兼容变更未走 RFC → Review 阻断。

---

## 一、HTTP 接口规范

### 1.1 URL 命名

| 规则 | 示例 |
|---|---|
| 复数名词 | `/api/v1/orders` 而不是 `/api/v1/order` |
| 小写连字符 | `/api/v1/order-items` 而不是 `/api/v1/orderItems` |
| 必须带版本号 | `/api/v1/...` |
| 资源 ID 在路径 | `/api/v1/orders/{order_id}` |
| 动作用 HTTP Method | `POST /orders`，而不是 `/createOrder` |

### 1.2 HTTP Method 语义

| Method | 用途 | 幂等 |
|---|---|---|
| GET | 查询 | 是 |
| POST | 创建 / 复杂查询 | 否 |
| PUT | 全量更新 | 是 |
| PATCH | 部分更新 | 是（推荐） |
| DELETE | 删除 | 是 |

### 1.3 响应结构（统一）

```json
{
  "code": 0,
  "message": "success",
  "request_id": "uuid-xxx",
  "data": {}
}
```

| 字段 | 类型 | 必返 | 含义 |
|---|---|---|---|
| `code` | int | 是 | 业务错误码，0 表示成功 |
| `message` | string | 是 | 错误描述（用户可见） |
| `request_id` | string | 是 | 全链路追踪 ID |
| `data` | object | 否 | 业务数据 |

### 1.4 HTTP Status Code

| Status | 使用场景 |
|---|---|
| 200 | 业务成功（即使 code != 0 也用 200，业务错误通过 code 区分） |
| 400 | 请求参数错误 |
| 401 | 未鉴权 |
| 403 | 鉴权失败 / 无权限 |
| 404 | 资源不存在 |
| 429 | 限流 |
| 500 | 服务内部错误 |
| 502/503/504 | 网关 / 服务不可用 / 超时 |

---

## 二、RPC 接口规范

### 2.1 Proto 文件组织

```
proto/
├── order/
│   └── v1/
│       ├── order.proto
│       └── order_service.proto
└── common/
    └── v1/
        └── error.proto
```

### 2.2 Proto 命名

| 实体 | 风格 | 示例 |
|---|---|---|
| 文件 | 蛇形小写 | `order_service.proto` |
| 包 | `<domain>.<version>` | `order.v1` |
| Service | 大驼峰 + `Service` | `OrderService` |
| Method | 大驼峰 | `CreateOrder` |
| Message | 大驼峰 | `CreateOrderRequest` |
| 字段 | 蛇形小写 | `user_id` |

### 2.3 字段编号规则（强约束）

- ❌ 禁止**修改已发布字段的编号**
- ❌ 禁止**复用已删除字段的编号**（用 `reserved`）
- ✅ 新增字段使用未使用过的编号

```proto
message Order {
  reserved 3, 5;        // 已删除字段编号不可复用
  reserved "old_field"; // 已删除字段名不可复用

  int64 id = 1;
  int64 user_id = 2;
  // string deleted_field = 3;  ← 禁止复用 3
  string new_field = 6;         // ✅ 用新编号
}
```

---

## 三、MQ 消息规范

### 3.1 Topic 命名

```
<domain>.<event>            # 业务事件
<domain>.<event>.dlq        # 死信队列
```

示例：`order.created`, `payment.success`, `order.created.dlq`

### 3.2 消息结构

```json
{
  "event_id": "uuid-xxx",
  "event_type": "order.created",
  "occurred_at": 1700000000,
  "version": "1.0",
  "payload": { ... }
}
```

| 字段 | 类型 | 必返 | 含义 |
|---|---|---|---|
| `event_id` | string | 是 | 事件唯一标识，消费方据此去重 |
| `event_type` | string | 是 | 事件类型 |
| `occurred_at` | int64 | 是 | 事件发生时间（毫秒） |
| `version` | string | 是 | 消息版本 |
| `payload` | object | 是 | 业务数据 |

### 3.3 消费要求

- ✅ **必须幂等**：基于 `event_id` 去重
- ✅ **必须配置死信队列**（DLQ）
- ✅ **必须监控消费延迟**

---

## 四、兼容性策略（强约束）

### 4.1 兼容性等级

| 等级 | 说明 | 变更流程 |
|---|---|---|
| **P0** | 核心接口（订单、支付等） | 任何不兼容变更必须走跨服务 RFC + 全链路灰度 |
| **P1** | 常规接口 | 不兼容变更需提前 2 周通知 + 灰度 |
| **P2** | 边缘接口 | 可在小版本内调整 |

### 4.2 兼容变更（允许）

- ✅ 新增可选字段
- ✅ 新增枚举值（前提：所有消费方有兜底逻辑）
- ✅ 放宽校验规则

### 4.3 不兼容变更（禁止/受限）

- ❌ 删除字段
- ❌ 修改字段类型
- ❌ 修改字段语义
- ❌ 修改 HTTP Method / URL
- ❌ 修改 RPC 方法签名
- ❌ 收紧校验规则

必须走 RFC 流程，并在 [`harness/dependency-map.md`](./dependency-map.md) 标注下游影响。

---

## 五、错误码规范

### 5.1 错误码段位划分

```
[业务域 3 位][子模块 3 位][序号 3 位]
例：100001001
    ↑ 100  → 订单域
       ↑ 001 → 创建订单子模块
          ↑ 001 → 第 1 个错误码
```

### 5.2 错误码必须有

- 唯一编码
- 业务含义（用户可见消息）
- 调用方处理建议（重试 / 提示用户 / 降级）

详细错误码表见 [`docs/api.md`](../docs/api.md) 错误码章节。

---

## 六、版本管理

- URL 版本号：`/api/v1/`, `/api/v2/`
- Proto 版本号：包路径中体现 `order.v1`, `order.v2`
- 新老版本**至少并存 3 个月**，下线前必须通知所有调用方

---

## 七、AI 行为约束

- AI 不得**编造**接口名、字段名、错误码
- AI 设计接口时**必须先检查** [`docs/api.md`](../docs/api.md) 是否已有类似接口
- AI 涉及字段变更必须**先判断兼容性等级**，P0/P1 必须停下来与用户确认
- AI 不得**修改 Proto 字段编号**或**复用已删除编号**

---

## 八、参考

- 详细接口契约见 [`docs/api.md`](../docs/api.md)
- 上下游影响见 [`harness/dependency-map.md`](./dependency-map.md)
