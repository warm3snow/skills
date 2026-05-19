---
name: sop-builder
description: 单仓库 AI 研发 SOP 建设 skill。按「AI 研发工作流 SOP v1」规范，引导 AI Agent 为一个代码仓库生成完整 SOP 资产：顶层三入口（README.md 业务背景 + ARCHITECTURE.md 架构 + AGENTS.md AI 行为约束）、harness/ 10 份规约（dependency-map / coding-style / api-standards / testing / database / development / code-review / deployment / glossary / failures）、docs/ 设计深化文档（architecture-design / domain-model / api / decision-log / runbook）、AI 工具软链接（CODEBUDDY.md / .claude/CLAUDE.md / .codex/instructions.md / .cursor/rules.md → AGENTS.md）以及 PreCommit Hook 脚手架。触发场景："帮我做 AI 友好化"、"建设 SOP"、"生成 AGENTS.md"、"生成 README.md"、"生成 ARCHITECTURE.md"、"生成 harness 规约"、"装配 AI 工具软链接"、"生成 PreCommit Hook"、"项目 SOP 落地"、"sop-builder"、"ai-friendly"。---

# SOP-Builder Skill（单仓库 AI 研发 SOP 建设）

本 skill 指导 AI Agent（Claude Code / Cursor / Codex / CodeBuddy / Copilot 等）为单个代码仓库按「AI 研发工作流 SOP v1」生成完整 SOP 资产。

> **设计理念**见 `sop-philosophy.md`。

---

## 📚 交付物总览

> SOP v1 强制要求**三入口分工独立** + **harness/ 规约库** + **docs/ 设计文档** + **软链接** + **PreCommit Hook**。

| 分类 | 文件 | 必选性 | 服务对象 |
|---|---|---|---|
| **顶层三入口** | `README.md` | ⭐ 必选 | 业务方、新人、外部协作者 |
| | `ARCHITECTURE.md` | ⭐ 必选 | 架构师、Tech Lead、跨团队对接人 |
| | `AGENTS.md`（≤300 行） | ⭐ 必选 | AI Coding Agent |
| **harness/ 规约（10 份）** | `harness/dependency-map.md` | ⭐ 必选 | 上下游依赖、调用关系 |
| | `harness/coding-style.md` | ⭐ 必选 | 编码规范 |
| | `harness/api-standards.md` | ⭐ 必选 | API 设计规范 |
| | `harness/testing.md` | ⭐ 必选 | 测试规范 |
| | `harness/database.md` | ⭐ 必选 | 数据库规范 |
| | `harness/development.md` | ⭐ 必选 | 本地开发环境 + 修改场景速查 |
| | `harness/code-review.md` | ⭐ 必选 | Code Review 规范 |
| | `harness/deployment.md` | ⭐ 必选 | 部署运行规范 |
| | `harness/glossary.md` | ⭐ 必选 | 业务术语表 |
| | `harness/failures.md` | ⭐ 必选 | 踩坑记录（含 Prompt/输出/根因） |
| **docs/ 设计深化** | `docs/architecture-design.md` | 🟡 强烈建议 | 架构详细设计与 ADR 论证 |
| | `docs/domain-model.md` | 🟡 强烈建议 | 领域模型与业务规则 |
| | `docs/api.md` | 🟡 强烈建议 | HTTP/RPC/MQ 接口契约 |
| | `docs/decision-log.md` | 🟢 可选 | 设计决策日志（ADR） |
| | `docs/runbook.md` | 🟢 可选 | 运维操作手册 |
| **AI 工具软链** | `CODEBUDDY.md` → `AGENTS.md` | ⭐ 必选 | CodeBuddy |
| | `.claude/CLAUDE.md` → `AGENTS.md` | ⭐ 必选 | Claude Code |
| | `.codex/instructions.md` → `AGENTS.md` | ⭐ 必选 | Codex |
| | `.cursor/rules.md` → `AGENTS.md` | ⭐ 必选 | Cursor |
| **质量门禁** | `.githooks/pre-commit` | 🟡 强烈建议 | 自动化检查（build/lint/单测/敏感文件/测试保护） |

---

## 三入口内容边界（强约束，模板已实现）

| 入口 | 回答的问题 | 严禁内容 |
|---|---|---|
| `README.md` | 这是什么？怎么跑起来？依赖哪些上下游？ | 详细架构图、AI 行为约束 |
| `ARCHITECTURE.md` | 模块怎么划分？数据怎么流？技术债？ | 本地启动步骤、AI 行为约束 |
| `AGENTS.md` | AI 禁止做什么？标准修改路径？规约索引？ | 业务背景细节、架构演进史 |

修改时 AI 应能立刻判断归属哪份文件。任何信息只在一处写完整版，其余文件只放链接。

---

## 执行前准备：探查步骤

在生成任何文档前，先执行以下探查并输出理解摘要：

```
1. 读取仓库根目录文件列表与目录树（depth=3）
2. 检测技术栈：go.mod / pom.xml / package.json / requirements.txt / Cargo.toml / build.gradle
3. 读取现有 README.md / AGENTS.md / ARCHITECTURE.md（如存在，作为升级基线）
4. 扫描 handler / controller / router / api 目录（了解对外接口）
5. 扫描 model / entity / domain 目录（了解数据模型）
6. 扫描 service / biz 目录（了解业务逻辑）
7. 扫描 migrations / sql 目录（了解 DB schema 演进）
8. 读取 Makefile / package.json scripts / Taskfile（了解构建/启动命令）
9. 读取 config / configs 目录（了解外部依赖）
10. 检测已有 .githooks / .husky / lint 配置
11. 检测已有 .claude / .codex / .cursor 配置
```

探查完成后列出理解摘要；除非用户明确要求先确认，否则继续生成。

---

## 任务清单（共 12 项）

### ⭐ 必选任务

#### 任务 A：生成 README.md（业务入口）

**输出路径：** `./README.md`

参考 `references/README-template.md`。内容必须涵盖：

1. **项目背景与业务目标** — 用业务语言说明这个项目存在的意义
2. **核心功能清单** — 列出对外提供的核心能力
3. **上下游依赖** — 调用谁、被谁调用、依赖哪些中间件
4. **快速启动** — 一条 `make dev` 或等效命令跑通本地环境（强制要求）
5. **部署环境要求** — 运行时依赖、配置项、最低资源
6. **注意事项** — 限流、灰度、敏感数据、合规要求

**禁止**：架构图、AI 行为约束、详细 ADR（这些归 ARCHITECTURE.md / AGENTS.md / docs/）。

#### 任务 B：生成 ARCHITECTURE.md（架构入口）

**输出路径：** `./ARCHITECTURE.md`

参考 `references/ARCHITECTURE-template.md`。内容必须涵盖：

1. **整体架构图**（ASCII 或 Mermaid）— 服务上下游位置 + 内部模块
2. **模块划分与边界** — 每个模块的职责与"不负责什么"
3. **数据流向** — 2-3 个核心业务流程的数据流
4. **技术选型理由** — 关键技术选型为什么这么选
5. **核心设计决策** — 关键 ADR 摘要（详细版在 `docs/decision-log.md`）
6. **已知技术债** — 当前未解决的债务清单

**禁止**：本地启动步骤、AI 行为约束。

#### 任务 C：生成 AGENTS.md（AI 行为约束 + 索引，≤300 行硬约束）

**输出路径：** `./AGENTS.md`

参考 `references/AGENTS-template.md`。内容必须涵盖：

1. **服务一句话描述** — 业务定位（1 句话）
2. **技术栈与版本** — 决定 AI 用哪一套 API
3. **目录结构** — `find . -maxdepth 3 -type d` 的结果 + 每个关键目录一句话职责
4. **核心业务模块** — service 层主要文件，每个一句话职责
5. **文档索引** — 指向 README / ARCHITECTURE / harness/ / docs/ 的导航锚点
6. **禁止触碰区域** — 鉴权、加密、已应用 migration、密钥相关路径
7. **AI 行为约束** — 必做、禁止、自检三块（详见模板）
8. **标准修改路径** — 添加新接口 / 改数据模型 / 修 bug 的 step-by-step
9. **测试与启动命令** — 从 Makefile / scripts 提取

**强约束**：
- 行数 ≤300，超出部分外链到 `harness/` 或 `docs/`
- **删除**「新人快速入门」「修改导航表」「提交前检查清单」章节（这些归 README + harness/development.md）
- 必须包含 SOP v1 角色分离原则：「禁止 AI 修改已有测试断言」「禁止删除已有测试」

#### 任务 D：生成 harness/ 10 份规约

**输出路径：** `./harness/*.md`（10 份）

参考 `references/harness/` 下对应模板：

| 文件 | 参考模板 | 核心内容 |
|---|---|---|
| `dependency-map.md` | `harness/dependency-map-template.md` | 上下游依赖、调用方式、契约位置 |
| `coding-style.md` | `harness/coding-style-template.md` | 命名、错误处理、注释、日志、禁止行为 |
| `api-standards.md` | `harness/api-standards-template.md` | HTTP/RPC/MQ 命名、版本、错误码、兼容策略 |
| `testing.md` | `harness/testing-template.md` | 覆盖率门槛、单测/集成/E2E 分层、Mock 约定 |
| `database.md` | `harness/database-template.md` | 命名、迁移规则（只追加）、索引、事务边界 |
| `development.md` | `harness/development-template.md` | 本地开发环境 + 6 类常见修改场景速查表 |
| `code-review.md` | `harness/code-review-template.md` | PR ≤500 行、必关联单号、AI 代码理解后提交、checklist |
| `deployment.md` | `harness/deployment-template.md` | 测试/生产部署、灰度、回滚、健康检查 |
| `glossary.md` | `harness/glossary-template.md` | 业务术语 → 代码字段映射 |
| `failures.md` | `harness/failures-template.md` | 踩坑记录（Prompt/输出/根因/规约改进） |

**强约束**：
- 10 份文件名严格对齐 SOP v1，**不允许改名、不允许合并、不允许新增第 11 份**
- `development.md` 同时承担「本地开发环境」与「修改场景速查」两块内容，章节区分

### 🟡 强烈建议任务

#### 任务 E：生成 docs/architecture-design.md（架构深化）

**输出路径：** `./docs/architecture-design.md`

参考 `references/docs/architecture-design-template.md`。与顶层 `ARCHITECTURE.md` 互补：

- 顶层 `ARCHITECTURE.md` 是**摘要**（架构图 + 关键 ADR）
- `docs/architecture-design.md` 是**深化**（详细模块设计、性能容量、ADR 论证全文）

#### 任务 F：生成 docs/domain-model.md（领域模型）

**输出路径：** `./docs/domain-model.md`

参考 `references/docs/domain-model-template.md`：

1. 读取 model / entity / domain 目录
2. 识别核心业务实体（跳过 Response / Config 等技术性 struct）
3. 用**中文**解释每个实体的业务含义
4. 枚举字段必须说明每个值的业务状态
5. 画出实体关系图（ASCII / Mermaid）
6. 从 service 层归纳业务规则

#### 任务 G：生成 docs/api.md（接口契约）

**输出路径：** `./docs/api.md`

参考 `references/docs/api-template.md`。读取 handler / controller / router 层及 proto / openapi / MQ schema；每个接口输出：业务描述、Method+路径 / RPC 方法 / Topic、请求/响应参数表格、错误码含义、调用方、兼容性要求和注意事项。

### 🟢 可选任务

#### 任务 H：生成 docs/decision-log.md（ADR 长版）

**输出路径：** `./docs/decision-log.md`

参考 `references/docs/decision-log-template.md`。搜索 `// NOTE:` `// IMPORTANT:` `// FIXME:` 注释及关键 git commit，整理为 ADR 格式。无历史时生成空模板。

#### 任务 I：生成 docs/runbook.md（运维手册）

**输出路径：** `./docs/runbook.md`

参考 `references/docs/runbook-template.md`。从代码提取健康检查接口、错误日志关键词、超时/重试配置、DB 连接失败处理逻辑。信息不足用 `[待补充]` 占位。

### ⭐ 必选任务（装配类）

#### 任务 J：装配 AI 工具软链接

**输出路径：** `./CODEBUDDY.md` / `./.claude/CLAUDE.md` / `./.codex/instructions.md` / `./.cursor/rules.md`

参考 `references/symlinks-setup.md`。执行步骤：

1. 确认 `AGENTS.md` 已生成
2. 创建必要的子目录（`.claude` / `.codex` / `.cursor`）
3. 对每个目标文件**先检测冲突**：
   - 不存在 → 直接建立软链
   - 已是软链且指向 `AGENTS.md` → 跳过
   - 已存在且非软链 → **停止并提示人工合并**，不强行覆盖
4. 执行软链命令：
   ```bash
   ln -sf ../AGENTS.md .claude/CLAUDE.md
   ln -sf ../AGENTS.md .codex/instructions.md
   ln -sf ../AGENTS.md .cursor/rules.md
   ln -sf AGENTS.md     CODEBUDDY.md
   ```
5. **不要**把这些文件加入 `.gitignore`，需要被提交以保证团队一致性
6. Windows 用户使用 `mklink` 备选方案（见 `symlinks-setup.md`）

#### 任务 K：装配 PreCommit Hook 脚手架

**输出路径：** `./.githooks/pre-commit` + 技术栈对应子脚本

参考 `references/precommit-hook/`。执行步骤：

1. 根据探查到的技术栈选择子脚本：
   - 存在 `go.mod` → 复制 `pre-commit-go.sh`
   - 存在 `package.json` → 复制 `pre-commit-node.sh`
   - 存在 `requirements.txt` / `pyproject.toml` → 复制 `pre-commit-python.sh`
   - 混合栈 → 同时复制多个，由主脚本调度
2. 复制 `pre-commit.sh` 作为主入口到 `.githooks/pre-commit`
3. 主脚本统一执行：
   - 敏感文件检测（`.env` / `*.pem` / `*.key` / `credentials*`）
   - 生成物拦截（`vendor/` / `node_modules/` / `dist/` / `*.exe`）
   - 测试断言保护（检测 `*_test.go` / `__tests__/` 断言行变更，警告并要求人工确认）
   - 新依赖说明检查（`go.sum` / `package-lock.json` / `poetry.lock` 变更时检查 commit message）
4. **不自动启用**，只提示用户：
   ```bash
   chmod +x .githooks/pre-commit
   git config core.hooksPath .githooks
   ```
5. 写入提示：若已有 `.husky/` 等 Hook 框架，建议合并而非覆盖（见 `precommit-hook/install.md`）

### 必选任务（收尾）

#### 任务 L：装配 AI Coding Skills

**输出路径：** `./.codebuddy/skills/`

参考 `references/skills/` 下模板。执行步骤：

1. 创建 `.codebuddy/skills/` 目录
2. 按项目实际需求选择复制以下 skill 模板：
   - `fix-bug/SKILL.md` — TDD bug 修复
   - `commit/SKILL.md` — 规范 commit message 生成
   - `code-review/SKILL.md` — 三级 checklist Code Review
   - `spec-write/SKILL.md` — SpecKit 设计文档生成
   - `new-feature/SKILL.md` — 新功能全流程开发
   - `write-tests/SKILL.md` — 测试补写
3. 根据项目技术栈（Go/Node/Python）调整模板中的命令示例
4. 确保 skill 中引用的 `harness/*.md` 文件已生成

**注意**：Skill 文件需要被提交到 Git，以保证团队一致性。

#### 任务 M：文档索引一致性校验

`AGENTS.md` 的「文档索引」章节代表本仓库**目标文档集合**：

- 索引中列出的每个 `harness/*.md` 与 `docs/*.md`，对应文件必须存在（至少骨架）
- 禁止"文件不存在就从索引中删除"
- 缺失则补生成骨架（含标题、章节占位、`[待补充]` 标注）

---

## 完整执行顺序

```
Step 1:  探查仓库（技术栈、目录结构、现有文档、Hook 配置），输出理解摘要
Step 2:  生成 README.md（任务 A）
Step 3:  生成 ARCHITECTURE.md（任务 B）
Step 4:  生成 AGENTS.md（任务 C，≤300 行硬约束）
Step 5:  生成 harness/ 10 份规约（任务 D）
Step 6:  生成 docs/architecture-design.md（任务 E）
Step 7:  生成 docs/domain-model.md（任务 F）
Step 8:  生成 docs/api.md（任务 G）
Step 9:  生成 docs/decision-log.md（任务 H，可选）
Step 10: 生成 docs/runbook.md（任务 I，可选）
Step 11: 装配 AI 工具软链接（任务 J）
Step 12: 装配 PreCommit Hook 脚手架（任务 K）
Step 13: 装配 AI Coding Skills（任务 L）
Step 14: 文档索引一致性校验（任务 M），缺失补骨架
Step 15: 输出完成摘要 + 所有 [待确认] 项列表 + 软链/Hook 启用命令
Step 16: 进入待确认项交互确认流程（Phase 1→2→3），逐项与用户正反面澄清并更新文档
```

---

## 待确认项交互确认流程

生成的文档中会包含 `[待确认]`、`[需人工确认]`、`[待补充]` 占位标记。**所有文档生成完成后，必须进入本流程，逐一澄清，直至全部确认完毕。**

### Phase 1：收集与展示

扫描本次生成的所有文件，提取所有待确认标记，输出结构化确认清单：

```markdown
## 待确认项清单（共 N 项）

| # | 来源文档 | 行/章节 | 确认项内容 | 当前占位值 | 状态 |
|---|---------|---------|-----------|-----------|------|
| 1 | `AGENTS.md` | 上下游依赖 | 支付服务的调用协议 | `[待确认]` | ⏳ |
| 2 | `ARCHITECTURE.md` | 核心流程 | 订单超时取消机制 | `[待补充]` | ⏳ |
| ... | | | | | |
```

**规则：**
- 确认项内容用业务语言概括，不直接复制原文
- 按来源文档分组排序
- 状态列初始为 ⏳，确认后改为 ✅

### Phase 2：逐项确认（正反面澄清）

按清单顺序，**逐项**与用户交互确认。每项必须包含正反面澄清：

```
【确认项 #1】来源：AGENTS.md > 上下游依赖

📝 确认内容：支付服务的调用协议
当前占位：[待确认]

✅ 正面澄清：支付服务是通过 HTTP 同步调用，还是 RPC 调用？
❌ 反面澄清：是否存在支付服务是异步 MQ 消息触发的情况？
   （如果用户选"是"，则补充：消息 Topic 和触发场景是什么？）

请提供确认信息：
```

**规则：**
1. 正面澄清直接询问该项的正确/最可能值，给 2-3 个常见选项引导
2. 反面澄清提出相反或另一种可能场景，确认是否排除
3. 用户回答正面 → 用确认值替换占位符
4. 用户回答反面 → 追问具体细节再替换
5. 用户暂时无法确认 → 标注 🔶（待后续确认），不跳过不删除
6. **每确认一项，立即更新对应文档文件**

### Phase 3：完成校验

```markdown
## 待确认项确认摘要

- ✅ 已确认：N 项
- 🔶 延后确认：M 项
- ⏳ 未确认：0 项

### 已确认项变更记录
| # | 来源文档 | 确认项 | 原占位值 | 确认值 |
|---|---------|-------|---------|-------|
```

**强制规则：**
- 不允许跳过任何待确认项；每项至少经过正反面澄清
- 不允许编造确认值；用户未明确回答时保留占位
- 确认值写入后，原占位标记必须移除
- 确认过程中发现新待确认内容，追加到清单末尾

---

## 禁止行为

- ❌ 把详细业务背景写进 AGENTS.md（归 README.md）
- ❌ 把架构图写进 README.md 或 AGENTS.md（归 ARCHITECTURE.md / docs/architecture-design.md）
- ❌ 把 AI 行为约束写进 README.md 或 ARCHITECTURE.md（归 AGENTS.md）
- ❌ AGENTS.md 超过 300 行
- ❌ harness/ 文件改名、合并或新增第 11 份
- ❌ 软链接覆盖已存在的非软链文件（必须停止并提示人工合并）
- ❌ 自动启用 PreCommit Hook（必须由用户决定 `git config core.hooksPath`）
- ❌ 把软链文件加入 `.gitignore`
- ❌ 编造接口、字段、业务规则；不确定一律 `[待确认]`
- ❌ 因 `harness/` 或 `docs/` 下缺失就从 AGENTS.md 文档索引中删除条目——索引代表目标集合，缺失应补骨架

---

## 信息不足时的处理

```markdown
## 信息不足，无法确定

缺失信息：
- [缺失项]

建议补充：
- [需要哪个负责人或哪个文件补充]

可先推进的部分：
- [可生成骨架的文档]
```

不要为了完整性编造业务规则、接口字段或上下游依赖。

---

## 质量检查清单

### 通用检查
- [ ] 业务描述使用业务语言，非纯技术术语
- [ ] 不确定内容已标注 `[待确认]` / `[需人工确认]` / `[待补充]`
- [ ] 没有编造接口、字段或业务规则
- [ ] 文档间引用路径正确
- [ ] 待确认项交互确认流程已完成

### 三入口边界检查
- [ ] `README.md` 不含详细架构图、不含 AI 行为约束
- [ ] `ARCHITECTURE.md` 不含本地启动步骤、不含 AI 行为约束
- [ ] `AGENTS.md` 不含详细业务背景、不含架构演进史
- [ ] `AGENTS.md` 行数 ≤300

### harness/ 检查
- [ ] 10 份文件名严格对齐 SOP v1，无改名/合并
- [ ] `development.md` 同时包含「本地开发环境」与「修改场景速查」两块
- [ ] `failures.md` 模板包含 Prompt/输出/根因/规约改进 结构
- [ ] `code-review.md` 包含「PR ≤500 行」「必关联单号」「AI 代码理解后提交」三条硬性规则

### docs/ 检查
- [ ] `domain-model.md` 枚举字段每个值有业务含义
- [ ] `api.md` 每个接口含调用方、兼容性要求
- [ ] `decision-log.md` ADR 格式完整（日期/背景/决策/理由/影响）

### 装配检查
- [ ] 4 条软链已建立或已警告冲突
- [ ] 软链文件未被加入 `.gitignore`
- [ ] `.githooks/pre-commit` 已生成，按技术栈选择了对应子脚本
- [ ] Hook 脚本未自动启用，已给出启用命令

### AI 行为约束硬约束
- [ ] `AGENTS.md` 明确「禁止 AI 修改已有测试断言」
- [ ] `AGENTS.md` 明确「禁止删除已有测试」
- [ ] `AGENTS.md` 明确「禁止静默吞异常」
- [ ] `AGENTS.md` 明确「禁止超出任务范围的大规模重构」

---

## 参考模板（references/）

| 模板路径 | 用途 |
|---|---|
| `README-template.md` | 业务入口模板 |
| `ARCHITECTURE-template.md` | 架构入口模板 |
| `AGENTS-template.md` | AI 行为约束 + 索引模板（≤300 行） |
| `harness/dependency-map-template.md` | 上下游依赖规约 |
| `harness/coding-style-template.md` | 编码规范 |
| `harness/api-standards-template.md` | API 设计规范 |
| `harness/testing-template.md` | 测试规范 |
| `harness/database-template.md` | 数据库规范 |
| `harness/development-template.md` | 本地开发环境 + 修改场景速查 |
| `harness/code-review-template.md` | Code Review 规范 |
| `harness/deployment-template.md` | 部署运行规范 |
| `harness/glossary-template.md` | 业务术语表 |
| `harness/failures-template.md` | 踩坑记录（含 Prompt/输出/根因） |
| `docs/architecture-design-template.md` | 架构深化设计 |
| `docs/domain-model-template.md` | 领域模型 |
| `docs/api-template.md` | API 文档 |
| `docs/decision-log-template.md` | ADR 长版 |
| `docs/runbook-template.md` | 运维手册 |
| `symlinks-setup.md` | AI 工具软链装配（含 Windows mklink） |
| `precommit-hook/pre-commit.sh` | Hook 主入口 |
| `precommit-hook/pre-commit-go.sh` | Go 子脚本 |
| `precommit-hook/pre-commit-node.sh` | Node 子脚本 |
| `precommit-hook/pre-commit-python.sh` | Python 子脚本 |
| `precommit-hook/install.md` | Hook 启用步骤 |
| `skills/fix-bug-template.md` | TDD Bug 修复 Skill |
| `skills/commit-template.md` | 规范 Commit Message Skill |
| `skills/code-review-template.md` | 三级 Checklist Code Review Skill |
| `skills/spec-write-template.md` | SpecKit 设计文档 Skill |
| `skills/new-feature-template.md` | 新功能全流程开发 Skill |
| `skills/write-tests-template.md` | 测试补写 Skill |
| `skills/prototype-template.md` | 一次性原型验证 Skill |
| `skills/improve-architecture-template.md` | 架构深化 Skill |
| `skills/to-issues-template.md` | 计划转任务单 Skill |

设计哲学详见 `sop-philosophy.md`。
