# [项目名称]

> 本文件是**业务入口**，服务对象：业务方、新人开发者、外部协作者。
> 架构详情见 [`ARCHITECTURE.md`](./ARCHITECTURE.md)。AI 协作约束见 [`AGENTS.md`](./AGENTS.md)。

---

## 项目背景与业务目标

[用业务语言（非技术术语）说明这个项目存在的意义。让完全不懂技术的人也能理解。]

**核心业务目标：**
- [目标 1：例如「为电商订单系统提供支付能力」]
- [目标 2]
- [目标 3]

---

## 核心功能清单

| 功能 | 业务说明 | 服务对象 |
|---|---|---|
| [功能 1] | [业务描述] | [前端 / 内部系统 / 外部商户] |
| [功能 2] | | |
| [功能 3] | | |

---

## 上下游依赖

### 我调用谁（依赖的服务/中间件）
| 依赖 | 类型 | 用途 |
|---|---|---|
| [服务名 / 中间件] | HTTP / RPC / MySQL / Redis / Kafka | [业务用途] |
| `[待确认]` | | |

### 谁调用我（被依赖方）
| 调用方 | 调用方式 | 调用场景 |
|---|---|---|
| [上游服务] | HTTP / RPC | [业务场景] |
| `[待确认]` | | |

> 详细依赖关系（含字段级契约、兼容性）见 [`harness/dependency-map.md`](./harness/dependency-map.md)。

---

## 快速启动

> SOP v1 要求：一条命令跑通本地环境。

```bash
# 1. 克隆仓库
git clone [repo-url] && cd [repo-name]

# 2. 启动依赖中间件
make dev-deps         # 或：docker-compose up -d

# 3. 一键启动
make dev              # 或等效命令
```

启动成功后访问健康检查：

```bash
curl http://localhost:[port]/health
# 预期：{"status":"ok"}
```

**首次启动时间**：约 [X] 分钟（含依赖下载与中间件启动）。
**新人 30 分钟内应能跑通环境**（SOP v1 硬性要求）。

详细本地开发环境说明见 [`harness/development.md`](./harness/development.md)。

---

## 部署环境要求

| 项 | 要求 |
|---|---|
| 运行时 | [Go 1.21 / JDK 17 / Python 3.11 / Node 20] |
| 最低资源 | CPU [N] 核 / 内存 [N] GB / 磁盘 [N] GB |
| 必需中间件 | [MySQL 8.0 / Redis 7.0 / Kafka 3.x] |
| 部署方式 | [Docker + K8s / 物理机 / Serverless] |
| 配置中心 | [配置中心名称 / 环境变量] |
| 网络要求 | [出网白名单 / 内网域名] |

详细部署规范见 [`harness/deployment.md`](./harness/deployment.md)。

---

## 注意事项

- **数据合规**：[涉及哪些敏感数据，遵循什么合规要求]
- **限流与配额**：[QPS 上限、调用方配额]
- **灰度策略**：[发布时是否需要灰度，灰度维度]
- **数据迁移**：[是否有历史数据兼容要求]
- **第三方依赖风险**：[关键第三方服务的可用性、降级策略]

---

## 项目导航

| 我想了解... | 去这里 |
|---|---|
| 这个项目的架构怎么设计的 | [`ARCHITECTURE.md`](./ARCHITECTURE.md) |
| 我（或 AI）准备改代码，有什么禁忌 | [`AGENTS.md`](./AGENTS.md) |
| 本地开发环境怎么搭、常见修改怎么做 | [`harness/development.md`](./harness/development.md) |
| 编码规范、API 规范、测试规范 | [`harness/`](./harness/) |
| 接口契约、领域模型、ADR | [`docs/`](./docs/) |
| 业务术语表 | [`harness/glossary.md`](./harness/glossary.md) |
| 踩过的坑 / 已知问题 | [`harness/failures.md`](./harness/failures.md) |

---

## 维护团队

| 角色 | 姓名 | 联系方式 |
|---|---|---|
| Owner | `[待确认]` | `[待确认]` |
| 备份 Owner | `[待确认]` | `[待确认]` |
| SOP Maintainer | `[待确认]` | `[待确认]` |

---

## 外部参考资料

- [关键技术博客 / 官方文档链接]
- [团队内部知识库链接]
- [`[待补充]`]
