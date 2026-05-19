# 本地开发环境 + 修改场景速查

> **规约定位**：本服务的本地开发环境规范 + 6 类常见修改场景的「定位 → 步骤 → 检查」速查表。
>
> 本文档由 SOP v1 要求合并自原 dev-guide。**新人 30 分钟内应能跑通环境**。

---

# Part 1：本地开发环境

## 一、环境准备

### 1.1 必装工具

| 工具 | 版本 | 安装方式 |
|---|---|---|
| `[Go]` | `1.21+` | `brew install go` / [官网](https://go.dev/dl/) |
| `[Docker]` | `24+` | Docker Desktop |
| `[Make]` | 自带 | macOS 自带 / `apt install make` |
| `[Git]` | `2.30+` | `brew install git` |
| `[golangci-lint]` | `1.55+` | `brew install golangci-lint` |
| `[待补充其他工具]` | | |

### 1.2 IDE 推荐

| IDE | 必装插件 |
|---|---|
| VS Code | Go / GitLens / TODO Tree / GitHub Copilot |
| GoLand | 自带 |
| Cursor | AI 默认 |

---

## 二、一键启动

```bash
# 1. 克隆
git clone [repo-url] && cd [repo-name]

# 2. 安装 git hooks（强制要求）
make install-hooks
# 等价于：
#   chmod +x .githooks/pre-commit
#   git config core.hooksPath .githooks

# 3. 启动依赖中间件
make dev-deps
# 等价于：docker-compose -f docker-compose.dev.yml up -d

# 4. 准备配置
cp config/config.example.yaml config/config.local.yaml
# 按需修改 config.local.yaml（不要提交）

# 5. 启动服务
make dev

# 6. 健康检查
curl http://localhost:[port]/health
```

**首次启动时间**：约 `[X]` 分钟（含依赖镜像下载）。

## 三、常用命令

```bash
make dev              # 一键启动开发
make test             # 全部测试
make test-unit        # 单测
make lint             # 代码检查
make build            # 构建二进制
make coverage         # 覆盖率
make clean            # 清理生成物
make migrate-up       # 执行数据库迁移
make migrate-down     # 回滚最近一次迁移
make proto            # 重新生成 proto 代码
```

## 四、本地配置规范

### 4.1 配置文件优先级

```
config.local.yaml > config.{env}.yaml > config.yaml
```

`config.local.yaml` 加入 `.gitignore`，**禁止提交**。

### 4.2 敏感配置

- ❌ **禁止**在任何 yaml 中提交密钥、token、数据库密码
- ✅ 通过环境变量或配置中心注入
- ✅ `config.example.yaml` 用占位符（如 `your-api-key-here`）

详见 [`harness/deployment.md`](./deployment.md) 配置管理章节。

## 五、调试技巧

| 场景 | 方法 |
|---|---|
| 接口请求调试 | `make dev` + Postman / `curl` |
| DB 查询慢 | 开启慢查询日志：`SET GLOBAL slow_query_log = 'ON';` |
| 内存/CPU 占用高 | `go tool pprof` / `flamegraph` |
| Goroutine 泄漏 | `go tool pprof http://localhost:6060/debug/pprof/goroutine` |
| MQ 消息排查 | `kafka-console-consumer` |

---

# Part 2：常见修改场景速查

> 按「场景 → 定位 → 步骤 → 检查」模式组织。

## 文档约定

| 符号 | 含义 |
|---|---|
| 🎯 | 修改目标 |
| 📍 | 需要定位的文件/目录 |
| 📝 | 具体操作步骤 |
| ⚠️ | 常见陷阱 |
| ✅ | 完成后必须检查 |

---

## 场景 1：添加新的 HTTP / RPC 接口

🎯 **目标**：对外暴露一个新的接口能力

### 📍 定位

| 步骤 | 去哪里 | 做什么 |
|---|---|---|
| 1 | `proto/` 或 `internal/handler/` | 定义接口签名 |
| 2 | `internal/handler/` | 添加 handler 函数，解析请求参数 |
| 3 | `internal/service/` | 实现业务逻辑 |
| 4 | `internal/repo/`（如需读写数据） | 添加数据访问方法 |
| 5 | `internal/model/`（如需新数据结构） | 定义请求/响应 struct |
| 6 | 路由注册文件 | 注册新路由 |
| 7 | `docs/api.md` | 补充接口文档 |
| 8 | 测试文件 | 添加单测 + 接口测试 |

### 📝 操作步骤

1. 阅读 [`harness/api-standards.md`](./api-standards.md) 确认命名 / 错误码 / 兼容性策略
2. 在 handler 层定义接口签名（仅做参数解析与响应组装）
3. 在 service 层实现业务逻辑
4. 如需 DB 操作，在 repo 层添加方法
5. 注册路由（注意中间件 / 鉴权）
6. 写测试（先失败 → 再实现 → 通过）
7. 更新 [`docs/api.md`](../docs/api.md)

### ⚠️ 常见陷阱

- 不要在 handler 层写业务逻辑
- 新接口必须补 `docs/api.md`，否则其他开发者（和 AI）不知道接口存在
- 涉及跨服务调用时必须先确认契约兼容性

### ✅ 完成检查

- [ ] handler 只做参数解析，业务逻辑在 service
- [ ] 单测 + 接口测试已添加，`make test` 通过
- [ ] [`docs/api.md`](../docs/api.md) 已更新
- [ ] 接口符合 [`harness/api-standards.md`](./api-standards.md) 命名规则

---

## 场景 2：修改已有接口行为

🎯 **目标**：调整某个已有接口的返回值、业务逻辑或参数

### 📍 定位

| 步骤 | 去哪里 |
|---|---|
| 1 | [`docs/api.md`](../docs/api.md) 查接口契约、调用方、兼容性等级 |
| 2 | `internal/handler/` 找到 handler |
| 3 | `internal/service/` 找业务逻辑 |
| 4 | `internal/model/` 确认 struct |

### 📝 操作步骤

1. 先判断变更是否**兼容**（参考 [`harness/api-standards.md`](./api-standards.md) §四）
2. 不兼容变更 → 必须走 RFC，不能直接改
3. 兼容变更 → 实施 + 更新文档 + 补测试

### ⚠️ 常见陷阱

- 删除字段 / 修改字段语义 = **不兼容变更**，必须通知所有消费方
- 修改 service 层可能影响其他调用方
- 新增枚举值必须确认消费方有兜底逻辑

### ✅ 完成检查

- [ ] 确认是兼容变更，或走 RFC
- [ ] `make test` 通过，旧测试未破坏
- [ ] [`docs/api.md`](../docs/api.md) 已更新
- [ ] 不兼容变更已通知下游

---

## 场景 3：给已有数据模型加新字段

🎯 **目标**：在已有 struct / DB 表中新增字段

### 📍 定位

| 步骤 | 去哪里 |
|---|---|
| 1 | `internal/model/` 添加字段 |
| 2 | `migrations/` 新建 migration（**只追加**） |
| 3 | `internal/repo/` 更新 SELECT/INSERT/UPDATE |
| 4 | `internal/service/` 补充赋值逻辑 |
| 5 | `internal/handler/` 确认是否返回 |
| 6 | [`docs/domain-model.md`](../docs/domain-model.md) 更新字段说明 |

### 📝 操作步骤

1. 阅读 [`harness/database.md`](./database.md) 确认字段命名、类型、索引规则
2. 在 model struct 加字段（注意 json/db tag）
3. **新建** migration 文件，禁止修改已应用的
4. 字段必须有默认值或允许 NULL
5. 更新 [`docs/domain-model.md`](../docs/domain-model.md)

### ⚠️ 常见陷阱

- **绝对不能修改已应用的 migration**（PreCommit Hook 会拦截）
- 新字段无默认值会导致旧数据报错
- 若新字段需要被其他服务消费，必须走契约变更

### ✅ 完成检查

- [ ] migration 是**新建**的，没有改旧文件
- [ ] 字段有默认值或允许 NULL
- [ ] [`docs/domain-model.md`](../docs/domain-model.md) 已更新
- [ ] 跨服务影响已通知

---

## 场景 4：新增 MQ 消费者 / 生产者

🎯 **目标**：新增消息发送或消费逻辑

### 📍 定位

| 步骤 | 去哪里 |
|---|---|
| 1 | `internal/service/` 实现生产/消费业务 |
| 2 | `config/` MQ 配置 |
| 3 | MQ 注册文件 |
| 4 | [`docs/api.md`](../docs/api.md) MQ 章节 |
| 5 | [`harness/dependency-map.md`](./dependency-map.md) 上下游 |

### 📝 操作步骤

1. 阅读 [`harness/api-standards.md`](./api-standards.md) MQ 章节
2. 确认 Topic 命名 / 消息结构 / 投递语义
3. 实现生产/消费
4. **消费端必须幂等**（基于 event_id 去重）
5. 配置死信队列
6. 更新文档

### ⚠️ 常见陷阱

- MQ 消息可能**重复投递**，必须幂等
- 业务依赖消息顺序时必须确认顺序消费保障
- 新增字段允许，删除/语义变更必须走 RFC

### ✅ 完成检查

- [ ] 消费端实现幂等
- [ ] 死信队列已配置
- [ ] [`docs/api.md`](../docs/api.md) MQ 章节已更新
- [ ] 本地可正常生产消费

---

## 场景 5：修改配置项

🎯 **目标**：新增或调整服务配置

### 📍 定位

| 步骤 | 去哪里 |
|---|---|
| 1 | `config/config.yaml` 修改 |
| 2 | `config/config.example.yaml` 同步 |
| 3 | 配置 struct 定义文件 |

### 📝 操作步骤

1. 在 config struct 加字段
2. 同步更新 `config.example.yaml`（写注释说明）
3. 在 service 中使用新配置项，替换硬编码
4. 敏感配置走环境变量

### ⚠️ 常见陷阱

- 不更新 `config.example.yaml` → 其他开发者本地起不来
- 敏感配置写 yaml → 提交时被 Hook 拦截
- 配置变更影响线上行为 → 需要灰度

### ✅ 完成检查

- [ ] `config.example.yaml` 已同步
- [ ] 敏感配置未硬编码
- [ ] `make dev` 正常启动

---

## 场景 6：排查线上问题

🎯 **目标**：快速定位与解决线上异常

### 📍 定位

| 步骤 | 去哪里 |
|---|---|
| 1 | [`docs/runbook.md`](../docs/runbook.md) 找排查路径 |
| 2 | [`harness/failures.md`](./failures.md) 看类似案例 |
| 3 | 日志搜索（用 runbook 关键词） |
| 4 | [`docs/decision-log.md`](../docs/decision-log.md) 了解设计决策 |

### 📝 操作步骤

1. 确认错误现象：错误码 / 日志关键词 / 影响范围
2. 在 [`docs/runbook.md`](../docs/runbook.md) 查排查步骤
3. 搜索代码中的错误日志关键词，定位到代码
4. 阅读 service 注释，理解业务逻辑
5. 制定修复方案，**先写回归测试**
6. 修复后**追加到 [`harness/failures.md`](./failures.md)**（Prompt/输出/根因/规约改进）

### ⚠️ 常见陷阱

- 紧急修复前先确认影响范围，不要"修一个引出三个"
- 跨服务问题先确认是本服务还是上下游
- 修复后必须补测试和文档

### ✅ 完成检查

- [ ] 根因已定位
- [ ] 回归测试已添加
- [ ] [`harness/failures.md`](./failures.md) 已追加案例
- [ ] 文档已更新

---

# Part 3：项目修改速查表

> 按目录组织，告诉你每个目录的修改规则。

| 目录/文件 | 可以改什么 | 不能改什么 | 修改后必须做什么 |
|---|---|---|---|
| `internal/handler/` | 加新 handler、调整参数解析 | 不要在 handler 写业务逻辑 | 更新 [`docs/api.md`](../docs/api.md) |
| `internal/service/` | 修改业务逻辑 | 注意对其他调用方的影响 | 测试通过，更新相关文档 |
| `internal/repo/` | 加新查询方法 | 不要绕过 repo 直接操作 DB | 用 EXPLAIN 验证 SQL |
| `internal/model/` | 加新 struct / 新字段 | 不要删除或重命名已有字段 | 更新 [`docs/domain-model.md`](../docs/domain-model.md) |
| `migrations/` | 只追加新 migration | **禁止修改已应用的 migration** | 执行 `make migrate-up` |
| `config/` | 加新配置项 | 不要硬编码、不要提交敏感信息 | 同步 `config.example.yaml` |
| `pkg/` | 加新工具函数 | 不要改已有函数签名 | 补单测 |
| `harness/` | 改进规约 | 不要随意删除规则 | 全员同步 |
| `docs/` | 随时补充 | 不要删除 AGENTS.md 索引中的条目 | 保持索引一致 |
| `*_test.go` | 加新测试 | **不要修改已有断言** | - |
