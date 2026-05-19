# AGENTS.md — AI Coding Agent 行为约束与索引

> 本文件是**AI 入口**，服务对象：Claude Code / Cursor / Codex / CodeBuddy / Copilot / Aider 等 AI Coding Agent。
> 业务背景见 [`README.md`](./README.md)。架构详情见 [`ARCHITECTURE.md`](./ARCHITECTURE.md)。
>
> **本文件硬约束 ≤300 行**。详细内容外链到 `harness/` 与 `docs/`，本文件只承担「索引 + 行为约束」。

---

## 🧭 服务一句话描述

**[用一句业务语言描述这个服务的核心定位]**

## 📦 技术栈

| 项 | 版本/说明 |
|---|---|
| 语言 | `[Go 1.21 / Java 17 / Python 3.11 / Node 20]` |
| 框架 | `[Gin / Spring Boot / FastAPI / NestJS]` |
| 数据库 | `[MySQL 8.0 / PostgreSQL 15]` |
| 缓存 | `[Redis 7.0]` |
| 消息队列 | `[Kafka / RocketMQ]` |
| 配置中心 | `[七彩石 / Apollo / Nacos]` |

## 🗂️ 目录结构

```
.
├── cmd/                  # 程序入口
├── internal/
│   ├── handler/          # HTTP/RPC 请求处理层
│   ├── service/          # 业务逻辑层
│   ├── repo/             # 数据访问层
│   ├── model/            # 数据模型
│   └── middleware/       # 中间件
├── pkg/                  # 可复用工具包
├── proto/                # Protobuf / OpenAPI 定义
├── config/               # 配置文件
├── migrations/           # 数据库迁移
├── harness/              # SOP 规约库（10 份）
├── docs/                 # 设计深化文档
├── test/                 # 集成测试
└── scripts/              # 构建/部署脚本
```

## 🔑 核心业务模块

| 模块 | 路径 | 一句话职责 |
|---|---|---|
| `[模块名]` | `internal/service/[file].go` | `[职责描述]` |
| `[模块名]` | `internal/service/[file].go` | `[职责描述]` |

详细模块边界见 [`ARCHITECTURE.md`](./ARCHITECTURE.md) §二。

---

## 📖 文档索引

> 本列表是仓库**目标文档集合**。AI 不得因文件缺失而从索引中删除条目；缺失应补骨架。

| 文档 | 类型 | 何时阅读 |
|---|---|---|
| [`README.md`](./README.md) | 业务入口 | 不理解业务背景时 |
| [`ARCHITECTURE.md`](./ARCHITECTURE.md) | 架构入口 | 涉及跨模块改动、技术选型时 |
| [`harness/dependency-map.md`](./harness/dependency-map.md) | 规约 | 涉及上下游调用时 |
| [`harness/coding-style.md`](./harness/coding-style.md) | 规约 | **每次编码前必读** |
| [`harness/api-standards.md`](./harness/api-standards.md) | 规约 | 设计/修改接口时 |
| [`harness/testing.md`](./harness/testing.md) | 规约 | 写/改测试时 |
| [`harness/database.md`](./harness/database.md) | 规约 | 涉及 DB schema 或 SQL 时 |
| [`harness/development.md`](./harness/development.md) | 规约 | 本地开发 + 常见修改场景速查 |
| [`harness/code-review.md`](./harness/code-review.md) | 规约 | 提交 PR 前自检 |
| [`harness/deployment.md`](./harness/deployment.md) | 规约 | 涉及部署 / 灰度 / 回滚时 |
| [`harness/glossary.md`](./harness/glossary.md) | 规约 | 不确定术语含义时 |
| [`harness/failures.md`](./harness/failures.md) | 规约 | 排查问题、修 bug 时 |
| [`docs/domain-model.md`](./docs/domain-model.md) | 设计 | 涉及业务规则 / 实体关系时 |
| [`docs/api.md`](./docs/api.md) | 设计 | 涉及接口契约时 |
| [`docs/decision-log.md`](./docs/decision-log.md) | 设计 | 想改动看似奇怪的设计前 |
| [`docs/runbook.md`](./docs/runbook.md) | 设计 | 排查线上问题时 |

---

## 🚀 标准修改路径

### 添加新接口
1. 在 `proto/` 或 `internal/handler/` 定义签名
2. 在 `internal/handler/` 实现 handler（仅参数解析、响应组装）
3. 在 `internal/service/` 实现业务逻辑
4. 如需读写 DB，在 `internal/repo/` 添加方法
5. 注册路由 + 添加测试用例
6. 更新 [`docs/api.md`](./docs/api.md)
7. 提交前阅读 [`harness/api-standards.md`](./harness/api-standards.md) 与 [`harness/code-review.md`](./harness/code-review.md)

### 修改数据模型
1. 在 `internal/model/` 定义/修改 struct
2. 添加 migration 文件（**只追加，禁止改已应用的 migration**）
3. 在 `internal/repo/` 更新 CRUD
4. 更新 [`docs/domain-model.md`](./docs/domain-model.md)
5. 提交前阅读 [`harness/database.md`](./harness/database.md)

### 修复 bug
1. 优先在 [`harness/failures.md`](./harness/failures.md) 查类似案例
2. 在 [`docs/runbook.md`](./docs/runbook.md) 找排查路径
3. 写**回归测试**确保失败 → 再修代码使测试通过（TDD）
4. 提交时在 [`harness/failures.md`](./harness/failures.md) 追加记录

---

## ⛔ 禁止触碰的区域

| 路径 | 原因 |
|---|---|
| `internal/middleware/auth.go` | 鉴权核心逻辑，修改需安全评审 |
| `migrations/` 已应用文件 | 只能追加，不能修改 |
| `pkg/crypto/` | 加密模块，修改需专项评审 |
| `[待补充其他敏感路径]` | `[原因]` |

---

## 🤖 AI 行为约束（核心）

> 本节是 SOP v1 P-G-E 角色分离原则的硬约束。AI 必须主动规避，而不是依赖 Hook 被动拦截。

### ✅ 必做

- **业务语义不确定 → 停下来反问用户**，不要猜
- **修改前先读** `harness/coding-style.md` 与目标模块现有注释
- **涉及接口变更** → 同步更新 [`docs/api.md`](./docs/api.md)
- **涉及数据模型** → 同步更新 [`docs/domain-model.md`](./docs/domain-model.md)
- **写代码用 TDD**：先写测试确保失败 → 再写实现使测试通过
- **新增依赖** → 在 commit message 中说明引入理由与替代方案
- **修复 bug** → 必须附回归测试

### ❌ 禁止（违反将被 PreCommit Hook 拦截）

- ❌ **修改已有测试文件的断言**（P-G-E 原则：Generator 不准动 Evaluator 的测试）
- ❌ **删除已有测试**（除非 PR 中明确说明理由）
- ❌ **静默吞异常**：`_ = err` / `catch {}` / `except: pass`
- ❌ **猜测业务语义**后编造字段、枚举值或业务规则
- ❌ 擅自修改 `⛔ 禁止触碰的区域` 路径
- ❌ 未经确认引入新外部依赖
- ❌ 一次性大规模重构超出当前任务范围
- ❌ 提交 `.env` / `*.pem` / `*.key` / `credentials*` 等敏感文件
- ❌ 提交未格式化代码（gofmt / prettier 未通过）
- ❌ 提交 `vendor/` / `node_modules/` / `dist/` / `*.exe` 等生成物
- ❌ build 不通过、lint 不通过
- ❌ 直接推 `main` / `master`（必须走特性分支 + PR）
- ❌ PR 超过 500 行未拆分
- ❌ PR 未关联 TAPD / Jira 单号
- ❌ 因 `harness/` 或 `docs/` 下缺失就从本文件「文档索引」中删除条目——索引代表目标集合，缺失应补骨架

### 🔍 输出前自检

- [ ] 代码改动符合 [`harness/coding-style.md`](./harness/coding-style.md)
- [ ] 没有碰「禁止触碰的区域」
- [ ] 没有修改/删除已有测试断言
- [ ] 接口/数据模型变更已同步文档
- [ ] 新增依赖已在 commit message 说明
- [ ] 我**理解**这段代码做了什么（不是机械生成）

---

## 📏 代码规范（要点速查）

- 命名：完整业务语义，禁止缩写
- 错误处理：所有错误必须显式处理
- 日志：用项目统一日志库，禁止 `fmt.Println` / `console.log`
- 配置：从 `config/` 读取，禁止硬编码
- 注释：写"为什么"，而不是"做了什么"

完整规范见 [`harness/coding-style.md`](./harness/coding-style.md)。

---

## 🧪 测试与启动

```bash
make dev              # 一键启动本地开发
make test             # 全部测试
make test-unit        # 单元测试
make test-integration # 集成测试
make coverage         # 覆盖率报告
make lint             # 代码检查
make build            # 构建
```

测试规范见 [`harness/testing.md`](./harness/testing.md)。

---

## 👥 维护

| 角色 | 联系方式 |
|---|---|
| Owner | `[待确认]` |
| SOP Maintainer | `[待确认]` |
