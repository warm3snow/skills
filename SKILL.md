---
name: ai-friendly-skill
description: 微服务和跨团队系统 AI 友好化 / AI 协作推进 skill。当用户需要为单个代码仓库生成 AI 友好化文档时使用 repo-mode，包括生成 AGENTS.md、README.md、架构、领域模型、API、决策日志和运维手册；当用户需要推进跨微服务、跨小组需求时使用 system-mode，包括生成全局系统上下文、服务目录、服务依赖图、跨服务契约索引、功能路由表、跨服务 RFC、小组任务单和可复制给各小组 AI 的 vibe coding prompt。触发场景："帮我做 AI 友好化"、"生成 AGENTS.md"、"跨服务 AI 协作"、"多微服务需求拆分"、"生成跨团队 RFC"、"生成小组任务单"、"让 AI 理解多个微服务关系"、"ai-friendly"。
---

# AI 友好化与跨服务协作 Skill

本 skill 指导 code agent（Claude Code / Cursor / CodeBuddy 等）生成两类产物：

1. **repo-mode：单仓库 AI 友好化** —— 为某个微服务仓库生成 `AGENTS.md`、README、架构、领域模型、API、决策日志和运维手册，让 AI 能在单仓库内安全开发。
2. **system-mode：跨服务 AI 协作推进** —— 为多微服务、多小组场景生成全局上下文、服务目录、服务关系图、契约索引、跨服务 RFC、小组任务单和 vibe coding prompt。目标是统一上下文和任务拆分，不是让一个 AI 越权统一修改所有服务代码。

## 模式选择

- 用户要求“生成 AGENTS.md / 单个仓库 AI 友好化 / 写项目文档”时，使用 **repo-mode**。
- 用户要求“跨服务协作 / 多个微服务关系 / 需求涉及多个小组 / 生成 RFC / 拆分小组任务 / 方便 vibe coding 推进”时，使用 **system-mode**。
- 如果用户没有明确模式，根据输入对象判断：单个仓库用 repo-mode；多个仓库、多个服务或跨团队需求用 system-mode。

## 执行前准备

### repo-mode 探查步骤

在开始生成单仓库文档前，先执行以下探查步骤：

```
1. 读取仓库根目录文件列表
2. 读取目录树结构（depth=3）
3. 读取已有的 README.md（如存在）
4. 读取 go.mod / pom.xml / package.json / requirements.txt（取存在的那个，判断技术栈）
5. 扫描 internal/handler 或 controller 目录（了解对外接口）
6. 扫描 internal/model 或 entity 目录（了解数据模型）
7. 扫描 internal/service 目录（了解业务逻辑模块）
```

探查完成后，列出理解摘要；除非用户明确要求先确认，否则继续生成目标文档。

### system-mode 输入和探查步骤

跨服务场景优先收集以下输入；缺失时用 `[待确认]` 占位，不编造：

```
1. 服务清单：服务名、仓库地址/路径、所属小组、负责人
2. 已有上下文：各服务 README.md、AGENTS.md、docs/api.md、proto/openapi、配置文件
3. 运行时依赖：HTTP/RPC client、MQ topic、DB/schema、缓存 key、服务发现配置
4. 需求输入：业务目标、可能涉及服务、已知接口或字段、上线时间约束
5. 组织边界：哪个小组负责哪个服务，哪些服务不可由当前 AI 直接修改
```

system-mode 的默认行为：**先产出分析、RFC、任务单和 prompt，不直接跨仓库写代码**。如果只能访问部分仓库，基于可见信息生成初稿，并明确列出需要各小组补充确认的清单。

## repo-mode：单仓库文档生成任务

### 任务 A：生成 AGENTS.md ⭐ 最高优先级

**输出路径：** `./AGENTS.md`

参考 `references/AGENTS.md.template`，按以下要求填充：

1. **服务一句话描述** — 用业务语言描述这个服务存在的意义
2. **技术栈** — 从依赖文件中提取，注明版本
3. **目录结构** — 运行 `find . -maxdepth 3 -type d` 获取，每个关键目录写一句话职责
4. **核心业务模块** — 列出 service 层主要文件，每个写一句话职责
5. **上下游依赖** — 从配置文件、RPC 调用代码推断；不确定标注 `[待确认]`
6. **添加新功能的标准路径** — 基于实际目录结构写 step-by-step（最关键！）
7. **禁止触碰区域** — 找出 auth、crypto、migration 等敏感目录，说明原因
8. **代码规范** — 从已有代码推断命名风格、错误处理方式
9. **测试和启动命令** — 从 Makefile / package.json scripts 提取

**质量要求：** 每条不超过 2 句话；不确定标注 `[需人工确认]`，不编造。


### 任务 B：补全 README.md

**输出路径：** `./README.md`

参考 `references/README.md.template`。必须包含：服务职责、技术栈、快速启动、目录结构、文档索引、维护团队。

**文档索引一致性规则（强制）：**
- README 的"文档索引"表格**以模板为准**，必须完整列出模板中的全部条目
- 禁止"docs/ 下不存在就从索引中删除"——索引代表的是**目标文档集合**，不是现状
- 若 README 索引中某文档在 `docs/` 下不存在，必须：
  1. 在本次任务中生成该文档的骨架（至少包含标题、章节占位和 `[待补充]` 标注）
  2. 或在完成摘要中明确列出"待生成文档"清单，提醒用户后续补齐
- 执行完 Step 2~Step 8 后，进入收尾步骤对照 README 索引逐条核验 `docs/` 下文件是否齐全

### 任务 C：生成架构文档

**输出路径：** `./docs/architecture.md`

参考 `references/architecture-templates.md`，按实际仓库情况填充：

1. ASCII 图画出服务上下游位置
2. 描述 2-3 个核心业务流程数据流
3. 提取代码中设计决策注释，整理为 ADR 格式
4. 无法推断的标注 `[待补充]`

### 任务 D：生成领域模型文档

**输出路径：** `./docs/domain-model.md`

参考 `references/domain-model-templates.md`，按实际仓库情况填充：

1. 读取 model / entity / domain 目录
2. 识别核心业务实体（跳过 Response、Config 等技术性 struct）
3. 用**中文**解释每个实体的业务含义
4. 枚举字段必须说明每个值的业务状态
5. 画出实体关系图（ASCII）
6. 从 service 层归纳业务规则

### 任务 E：生成 API 文档

**输出路径：** `./docs/api.md`

读取 handler / controller / router 层，每个接口输出：业务描述、Method+路径、请求/响应参数表格、错误码含义、注意事项。


### 任务 F：生成设计决策日志

**输出路径：** `./docs/decision-log.md`

参考 `references/decision-log-templates.md`。搜索 `// NOTE:` `// IMPORTANT:` `// FIXME:` `// TODO:` 注释及 git commit，整理为 ADR 格式。无历史时生成空模板。


### 任务 G：生成运维手册

**输出路径：** `./docs/runbook.md`

参考 `references/runbook-templates.md`。从代码提取健康检查接口、错误日志关键词、超时/重试配置、DB 连接失败处理逻辑。信息不足用 `[待补充]` 占位。


## system-mode：跨服务 AI 协作任务

### 任务 H：生成全局系统上下文

**输出路径：** `./ai-system-context/SYSTEM.md`

参考 `references/cross-service-ai-collaboration-templates.md`。必须包含：系统一句话描述、核心业务域、全局职责边界、核心链路、AI 使用约束。信息不足时标注 `[待确认]`。

### 任务 I：生成服务目录和服务卡片

**输出路径：**
- `./ai-system-context/SERVICE-CATALOG.md`
- `./ai-system-context/services/<service-name>.md`

要求：
1. 每个服务记录所属小组、仓库、职责、不负责事项、技术栈、数据归属、对外能力、负责人。
2. 每个服务卡片控制在 1-2 页，便于小组维护。
3. 明确“本服务负责什么 / 不负责什么”，避免 AI 把需求错放到错误服务。
4. 无法确认的负责人、仓库、字段语义标注 `[待确认]`。

### 任务 J：生成服务依赖图

**输出路径：** `./ai-system-context/SERVICE-GRAPH.md`

要求：
1. 使用 Mermaid `flowchart` 画出服务、DB、MQ、外部系统之间的关系。
2. 用表格列出上游、下游、协议、用途、契约位置、归属小组、风险。
3. 只表达有证据的依赖；推断依赖标注 `[待确认]`。

### 任务 K：生成跨服务契约索引

**输出路径：** `./ai-system-context/CONTRACTS.md`

要求：
1. 收集 HTTP、RPC、MQ、共享读模型等跨服务契约。
2. 标注提供方、调用方/消费方、契约位置、兼容性等级。
3. 字段级说明必须包含业务含义、是否必填、是否可删除、变更规则。
4. 默认规则：允许新增兼容字段；禁止删除字段或修改旧字段语义；新增枚举值必须通知消费方。

### 任务 L：生成功能路由表

**输出路径：** `./ai-system-context/FEATURE-ROUTING.md`

要求：
1. 按业务功能域归纳通常涉及哪些服务和小组。
2. 对每个功能域说明服务涉及原因、常见改动类型、主责服务、推荐推进顺序和契约风险。
3. 该文件用于需求早期影响面分析，不替代具体 RFC。

### 任务 M：生成跨服务功能 RFC

**输出路径：** `./ai-system-context/rfcs/<feature-name>.md`

输入：业务需求描述、可能涉及服务、已知约束。

要求：
1. 先说明需求背景、业务目标和非目标。
2. 列出涉及服务、小组、是否必须改、改动类型、涉及原因和待确认项。
3. 画出跨服务数据流或时序图。
4. 说明契约变更、兼容策略、发布顺序、回滚策略。
5. 拆出每个小组的输入、输出、开发任务、测试任务和文档任务。
6. 明确风险和待确认项；不确定内容不得编造。

### 任务 N：生成小组任务单

**输出路径：** `./ai-system-context/tasks/<feature-name>/<team-or-service>.md`

要求：
1. 每个任务单只面向一个小组或一个服务。
2. 明确本服务任务边界，禁止要求该小组修改其他小组服务。
3. 包含输入依赖、本服务交付、建议实现顺序、验收标准和给本小组 AI 的 prompt。
4. 如果某服务只需确认无需改代码，也生成“确认型任务单”。

### 任务 O：生成 vibe coding prompt 集

**输出路径：** `./ai-system-context/VIBE-CODING-PROMPTS.md`

要求：
1. 生成“全局分析 Prompt”：用于先做影响面分析，不直接写代码。
2. 生成“单服务执行 Prompt”：用于各小组在自己仓库内开发。
3. Prompt 必须强调：只负责当前服务，不跨仓库修改其他服务；先输出计划、契约影响和测试计划。

### 任务 P：生成跨服务变更 SOP

**输出路径：** `./ai-system-context/CHANGE-PLAYBOOKS.md`

要求：
1. 覆盖新增跨服务功能、接口字段变更、MQ 事件变更、灰度发布、回滚、联调。
2. 强调先 RFC、再任务单、再各服务独立开发。
3. 明确跨服务契约默认兼容策略。

## 完整执行顺序

### repo-mode 执行顺序

```
Step 1: 探查仓库，输出理解摘要；除非用户要求确认，否则继续执行
Step 2: 生成 AGENTS.md
Step 3: 补全 README.md
Step 4: 生成 docs/architecture.md
Step 5: 生成 docs/domain-model.md
Step 6: 生成 docs/api.md
Step 7: 生成 docs/decision-log.md
Step 8: 生成 docs/runbook.md
Step 9: 文档索引一致性校验 —— 对照 README 的"文档索引"，逐条核验 docs/ 下文件是否齐全，缺失则补生成骨架
Step 10: 输出完成摘要 + 所有 [待确认] 项列表 + 本次补齐的骨架文档清单
```

### system-mode 执行顺序

```
Step 1: 收集服务清单、仓库/文档路径、所属小组、需求描述；缺失项标注 [待确认]
Step 2: 生成 ai-system-context/SYSTEM.md
Step 3: 生成 SERVICE-CATALOG.md 和 services/<service-name>.md
Step 4: 生成 SERVICE-GRAPH.md
Step 5: 生成 CONTRACTS.md
Step 6: 生成 FEATURE-ROUTING.md
Step 7: 如输入了具体需求，生成 rfcs/<feature-name>.md
Step 8: 如生成了 RFC，继续生成 tasks/<feature-name>/<team-or-service>.md
Step 9: 生成或更新 VIBE-CODING-PROMPTS.md 和 CHANGE-PLAYBOOKS.md
Step 10: 输出推进摘要 + 各小组待确认项 + 契约风险 + 建议推进顺序
```

system-mode 每次输出都应强调：**本 skill 产出跨团队协作材料，不替代各小组代码评审、开发和发布流程**。


## 质量检查清单

### 通用检查
- [ ] 业务描述使用业务语言，非纯技术术语
- [ ] 不确定内容已标注 `[需人工确认]` 或 `[待确认]`
- [ ] 没有编造不存在的接口、字段或业务规则
- [ ] 文档间引用路径正确

### repo-mode 检查
- [ ] "添加新功能步骤"基于实际目录结构
- [ ] 枚举字段每个值都有业务含义说明
- [ ] README 文档索引中的每个条目，在 `docs/` 下都有对应文件（至少是骨架）

### system-mode 检查
- [ ] 服务职责边界清晰区分“负责 / 不负责”
- [ ] 每个服务都标注所属小组、仓库、数据归属和契约位置；缺失项标注 `[待确认]`
- [ ] 服务依赖图只表达有证据的依赖，推断关系已标注 `[待确认]`
- [ ] 契约索引包含提供方、消费方、字段语义、兼容性规则
- [ ] RFC 明确业务目标、非目标、数据流、契约变更、发布顺序和回滚策略
- [ ] 小组任务单只要求当前小组/服务交付，不越权要求修改其他服务
- [ ] vibe coding prompt 明确“先分析和计划，不直接跨仓库写代码”


## 参考模板

### repo-mode 模板
- `references/AGENTS.md.template` — AGENTS.md 完整模板
- `references/README.md.template` — README.md 完整模板
- `references/architecture-templates.md` — `docs/architecture.md` 架构文档模板
- `references/domain-model-templates.md` — `docs/domain-model.md` 领域模型文档模板
- `references/decision-log-templates.md` — `docs/decision-log.md` 设计决策日志模板
- `references/runbook-templates.md` — `docs/runbook.md` 运维手册模板

### system-mode 模板
- `references/cross-service-ai-collaboration-templates.md` — 跨服务全局上下文、服务目录、服务卡片、服务依赖图、契约索引、功能路由表、跨服务 RFC、小组任务单、变更 SOP 和 vibe coding prompt 模板
