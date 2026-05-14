# AGENTS.md — AI Agent 指南

> 本文件专为 AI Coding Agent（Claude Code / Cursor / Copilot / CodeBuddy 等）设计。
> 阅读本文件后，AI 应能独立完成常见开发任务，无需额外追问。
> 人类新人开发者请先阅读下方「👋 新人快速入门」，再按需深入其他章节。

## 👋 新人快速入门

> 5 分钟了解本项目，开始你的第一次代码修改。

### 这个项目是做什么的？
[用最通俗的大白话解释，避免技术术语。让完全不懂技术的人也能理解]

### 修改代码前必须知道的 3 件事
1. **[最关键的架构约束]**：例如"所有外部调用必须走 service 层，handler 层禁止直接调 repo"
2. **[最重要的业务规则]**：例如"订单状态只能单向流转，不允许回退"
3. **[最容易踩的坑]**：例如"XX 字段在数据库中是枚举值，不能随便加，要通知下游"

### 我想修改... → 去哪里？
| 我想做... | 先看这个文件 | 再看这个文件 | 参考文档 |
|-----------|------------|------------|---------|
| 加新 HTTP 接口 | `internal/handler/` | `internal/service/` | `docs/api.md` |
| 改业务逻辑 | `internal/service/` | 对应 `model/` | `docs/domain-model.md` |
| 加新数据字段 | `internal/model/` | 数据库 migration | `docs/domain-model.md` |
| 加新的 MQ 消费/生产 | `internal/service/` | `config/` 里的 MQ 配置 | `docs/api.md` |
| 改配置项 | `config/config.yaml` | `config/config.example.yaml` | - |
| 排查线上问题 | `docs/runbook.md` | 搜索日志关键词 | - |
| 了解为什么这么设计 | `docs/decision-log.md` | 代码中 `// NOTE:` 注释 | - |

### 第一次提交代码前的检查清单
- [ ] 我阅读了本文件的「⛔ 禁止触碰的区域」
- [ ] 我的修改没有超出「业务职责边界」
- [ ] 我运行了 `make test` 且全部通过
- [ ] 如果改了接口或数据模型，我更新了对应文档（`docs/api.md` / `docs/domain-model.md`）
- [ ] 我没有硬编码配置项，配置走 `config/` 目录

## 🧭 服务一句话描述
**[在此填写]**

## 🎯 业务职责边界
**本服务负责：**
- [职责1：用业务语言描述]
- [职责2]
- [职责3]

**本服务不负责（交由其他服务/模块）：**
- [不负责事项1] → 由 [XX 服务] 负责
- [不负责事项2] → 由 [XX 服务] 负责

> AI 注意：涉及"不负责"范围的需求，应提示用户到对应服务仓库处理，不要在本仓库强行实现。

## 📦 技术栈
| 项目 | 版本/说明 |
|------|-----------|
| 语言 | Go 1.21 / Java 17 / Python 3.11 |
| 框架 | Gin / Spring Boot / FastAPI |
| 数据库 | MySQL 8.0 / Redis 7.0 |
| 消息队列 | Kafka / RocketMQ（如有） |
| 服务发现 | Polaris / Consul（如有） |
| 部署方式 | Docker + K8s |

## 🗂️ 目录结构
.
├── cmd/                # 程序入口
├── internal/
│   ├── handler/        # HTTP/RPC 请求处理层
│   ├── service/        # 业务逻辑层
│   ├── repo/           # 数据访问层
│   ├── model/          # 数据模型
│   └── middleware/     # 中间件
├── pkg/                # 可复用工具包
├── proto/              # Protobuf 定义
├── config/             # 配置文件
├── docs/               # 文档目录
├── test/               # 集成测试
└── scripts/            # 构建/部署脚本

## 🔑 核心业务模块
| 模块 | 路径 | 职责说明 |
|------|------|----------|
| [模块名] | `internal/service/xxx.go` | [一句话描述] |

## 🔗 上下游依赖
### 依赖的服务（我调用谁）
| 服务名 | 调用方式 | 用途 |
|--------|----------|------|
| [服务名] | gRPC / HTTP | [用途说明] |

### 被依赖的服务（谁调用我）
| 服务名 | 调用我的接口 | 说明 |
|--------|-------------|------|
| [服务名] | [接口名] | [说明] |

### 消息队列
| Topic / Queue | 生产/消费 | 说明 |
|---------------|-----------|------|
| [topic名] | Producer | [说明] |

## 🚀 添加新功能的标准路径

### 添加新的 HTTP 接口
1. 在 proto/ 或 internal/handler/ 定义接口签名
2. 在 internal/handler/ 添加 handler 函数
3. 在 internal/service/ 实现业务逻辑
4. 如需读写数据库，在 internal/repo/ 添加数据访问方法
5. 在路由注册文件注册路由
6. 在 test/ 添加集成测试用例
7. 更新 docs/api.md

### 添加新的数据模型
1. 在 internal/model/ 定义 struct
2. 添加数据库 migration 文件
3. 在 internal/repo/ 添加 CRUD 方法
4. 更新 docs/domain-model.md

### 修改已有业务逻辑
1. 先阅读对应 service 文件注释，理解现有逻辑
2. 修改 internal/service/ 中的实现
3. 确保测试通过：make test
4. 如接口行为有变化，更新 docs/api.md

## ⛔ 禁止触碰的区域
| 路径 | 原因 |
|------|------|
| `internal/middleware/auth.go` | 鉴权核心逻辑，修改需安全审查 |
| `migrations/` | 只能追加，不能修改已有文件 |
| `pkg/crypto/` | 加密模块，修改需专项评审 |

## 📏 代码规范
- 命名：完整业务语义，禁止缩写
- 错误处理：所有错误必须显式处理，禁止 `_ = err`
- 日志：使用 `pkg/logger`，禁止 `fmt.Println`
- 配置：从 `config/` 读取，禁止硬编码
- 注释：写"为什么这么做"，而不是"做了什么"

## 🧪 测试指南
make test            # 所有测试
make test-unit       # 单元测试
make test-integration # 集成测试
make coverage        # 覆盖率报告

## 🏗️ 本地开发启动
make deps
cp config/config.example.yaml config/config.local.yaml
docker-compose up -d
make run

## 🤖 AI Agent 行为约束
> 本节约束仅针对 AI Coding Agent，人类开发者可参考。

**必读前置：**
- 修改任何代码前，必须先阅读本文件 + 目标模块内的现有注释
- 涉及业务语义的修改，必须阅读 `docs/domain-model.md`
- 涉及接口变更的修改，必须阅读 `docs/api.md`

**禁止行为：**
- ❌ 猜测业务含义后编造字段、枚举值或业务规则
- ❌ 擅自修改 `⛔ 禁止触碰的区域` 中列出的路径
- ❌ 未经确认引入新的外部依赖（`go get` / `npm install` / `pip install`）
- ❌ 静默吞异常（`_ = err` / `catch {}` / `except: pass`）
- ❌ 一次性大规模重构超出当前任务范围的代码
- ❌ 因 `docs/` 下缺失就从 `README.md` 文档索引中删除条目——索引代表目标集合，缺失应补齐骨架

**必做行为：**
- ✅ 不确定的业务语义 → 停下来反问用户，而不是猜测
- ✅ 发现需要修改"禁止触碰区域" → 停止并报告，等待人工介入
- ✅ 新增依赖前 → 在回复中说明理由和替代方案
- ✅ 修改接口或数据模型后 → 同步更新 `docs/api.md` / `docs/domain-model.md`
- ✅ 遇到"添加新功能"类任务 → 严格按本文件的"标准路径"逐步执行

**输出前自检：**
- [ ] 代码改动是否符合本文件的"代码规范"
- [ ] 是否碰到了"禁止触碰的区域"
- [ ] 是否需要同步更新文档
- [ ] 是否需要补充或修改测试

## ❓ 遇到问题时
1. 查 docs/ 目录下相关文档
2. 查看 docs/decision-log.md 了解历史设计决策
3. 搜索代码中的 // NOTE: 和 // IMPORTANT: 注释
4. 联系：[团队负责人] / [联系方式]
