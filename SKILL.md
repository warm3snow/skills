---
name: ai-repo-docs
description: 微服务仓库 AI 友好化文档生成 skill。当用户需要为代码仓库生成 AI 友好化文档时使用，包括：(1) 生成 AGENTS.md（AI Agent 专属指南）(2) 生成或补全 README.md (3) 生成 docs/architecture.md 架构文档 (4) 生成 docs/domain-model.md 领域模型文档 (5) 生成 docs/api.md 接口文档 (6) 生成 docs/decision-log.md 设计决策日志 (7) 生成 docs/runbook.md 运维手册 (8) 对整个仓库执行完整 AI 友好化。触发场景："帮我做 AI 友好化"、"生成 AGENTS.md"、"写项目文档"、"让 AI 能理解这个仓库"、"ai-friendly"、"帮我写架构文档"。
---

# AI 仓库文档生成 Skill

本 skill 指导 code agent（Claude Code / Cursor / CodeBuddy 等）为微服务仓库生成一套 AI 友好化文档，让新员工和 AI agent 能快速理解仓库并独立扩展功能。

## 执行前准备

在开始生成任何文档前，先执行以下探查步骤：

```
1. 读取仓库根目录文件列表
2. 读取目录树结构（depth=3）
3. 读取已有的 README.md（大小写不敏感匹配：`README.md` / `Readme.md` / `readme.md` 等任一存在即读取其内容，并在任务 B 中统一为 `README.md`）
4. 读取 go.mod / pom.xml / package.json / requirements.txt（取存在的那个，判断技术栈）
5. 扫描 internal/handler 或 controller 目录（了解对外接口）
6. 扫描 internal/model 或 entity 目录（了解数据模型）
7. 扫描 internal/service 目录（了解业务逻辑模块）
```

探查完成后，列出你的理解摘要，再开始写文档。

## 文档生成任务

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

**输出路径：** `./README.md`（文件名必须是全大写的 `README.md`）

**文件命名强制规则：**
- 只能使用 `README.md`（全大写），禁止生成 `Readme.md` / `readme.md` / `ReadMe.md` 等任何变体
- 若仓库中已存在 `Readme.md` / `readme.md` 等变体文件：
  1. 读取其原有内容
  2. 将内容迁移并整合到 `README.md`
  3. 通过 `git mv` 将旧变体文件重命名为 `README.md`（避免大小写敏感文件系统上出现两份文件）
  4. 在完成摘要中明确告知用户发生过重命名
- 执行写文件前，务必显式确认目标路径为 `./README.md`

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


## 完整 AI 友好化执行顺序

```
Step 1: 探查仓库，输出理解摘要，等待用户确认或纠正
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

每完成一个文档后告知用户，不要一次性全部输出。


## 质量检查清单

- [ ] 业务描述使用业务语言，非纯技术术语
- [ ] 不确定内容已标注 `[需人工确认]` 或 `[待确认]`
- [ ] 没有编造不存在的接口、字段或业务规则
- [ ] "添加新功能步骤"基于实际目录结构
- [ ] 枚举字段每个值都有业务含义说明
- [ ] 文档间引用路径正确
- [ ] README 文件名为全大写 `README.md`，仓库中不存在 `Readme.md` / `readme.md` 等变体
- [ ] README 文档索引中的每个条目，在 `docs/` 下都有对应文件（至少是骨架）


## 参考模板

- `references/AGENTS.md.template` — AGENTS.md 完整模板
- `references/README.md.template` — README.md 完整模板
- `references/architecture-templates.md` — `docs/architecture.md` 架构文档模板
- `references/domain-model-templates.md` — `docs/domain-model.md` 领域模型文档模板
- `references/decision-log-templates.md` — `docs/decision-log.md` 设计决策日志模板
- `references/runbook-templates.md` — `docs/runbook.md` 运维手册模板
