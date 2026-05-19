# SOP-Builder 设计理念

> 本文档说明 sop-builder skill 为什么这样设计，以及它如何把「AI 研发工作流 SOP v1」落到一个仓库的实际文件结构上。
> SKILL.md 是**工作流**（怎么做），本文是**设计哲学**（为什么这么做）。

---

## 一、底层思路：三类读者，三份入口

SOP v1 的核心矛盾是：一份 `README.md` 同时服务**业务理解、架构理解、AI 行为约束**三类需求时，必然信息过载或缺漏。sop-builder 的回答是**入口分离**：

| 入口文件 | 服务对象 | 回答的问题 | 不回答的问题 |
|---|---|---|---|
| `README.md` | 业务方、新人、外部协作者 | 这个项目是做什么的？怎么跑起来？依赖哪些上下游？ | 架构怎么演进的？AI 不准做什么？ |
| `ARCHITECTURE.md` | 架构师、Tech Lead、跨团队对接人 | 模块怎么划分？数据怎么流？为什么选这个技术栈？有什么技术债？ | 怎么本地启动？AI 行为约束？ |
| `AGENTS.md` | AI Coding Agent（Claude/Cursor/Codex/CodeBuddy 等） | 禁止触碰哪里？标准修改路径？规约索引在哪？ | 业务背景细节？架构演进史？ |

**强约束：三者内容不重叠**。任何一处需要修改时，AI 应能立刻判断归属于哪个文件，而不是「这段写哪都行」。

> 这与早期 ai-friendly skill「AGENTS.md 一份兼任入口」的方案不同。后者在小项目可行，在 SOP v1 要求的工程化场景下，AGENTS.md 行数会失控、AI 加载成本上升、人类阅读成本也上升。

---

## 二、harness/：规约库而非文档库

SOP v1 强调 `harness/` 是**规约**（rules），不是**说明**（docs）。两者根本差别：

- **规约** 是**用来阻止行为**的：违反者不应通过 Review、不应过 Hook、不应被合并。
- **说明** 是**用来帮助理解**的：缺失时项目仍可运行，只是新人/AI 上手慢。

因此 sop-builder 强制 `harness/` 与 `docs/` 双轨：

```
harness/        ← 10 份规约，每份对应一条「检查门禁」
docs/           ← 设计深化文档（architecture-design / domain-model / api / decision-log / runbook）
```

| harness 文件 | 对应门禁 | 违反后果 |
|---|---|---|
| `coding-style.md` | gofmt/prettier/lint Hook | 提交被拒 |
| `testing.md` | 覆盖率阈值、必须有测试 | CI 失败 |
| `api-standards.md` | 接口字段兼容性 | Review 阻断 |
| `database.md` | migration 只追加不修改 | Review 阻断 |
| `code-review.md` | PR ≤500 行、必关联单号 | PR 模板校验 |
| `deployment.md` | 灰度/回滚 Checklist | 发布门禁 |
| `dependency-map.md` | 上下游依赖变更通知 | RFC 流程 |
| `development.md` | 本地开发 + 修改场景速查 | 新人/AI 上手 |
| `glossary.md` | 业务术语 → 字段映射 | 编码命名一致性 |
| `failures.md` | 踩坑案例 → 规约改进 | 反馈机制闭环 |

> **dev-guide 并入 development.md**：原因是 SOP v1 的 10 份规约文件名是封闭集合，不允许增加第 11 份。`development.md` 同时承担「本地开发环境规范」与「常见修改场景速查」两块内容，章节区分。

---

## 三、AGENTS.md 极简化原则

旧版 AGENTS.md 模板（230 行）包含「新人快速入门」「修改导航表」「提交前检查清单」等章节。这些**已被 README.md 与 harness/development.md 覆盖**，留在 AGENTS.md 反而：

1. 让 AI 每次加载浪费 Token；
2. 让人类阅读时不知道究竟读哪份；
3. 修改时容易漂移到多处。

新版 AGENTS.md 模板（≤300 行硬约束）只保留：

- **服务一句话描述**（业务定位）
- **技术栈与版本**（决定 AI 用哪一套 API）
- **目录结构**（决定 AI 文件路径选择）
- **核心业务模块**（决定 AI 修改入口）
- **文档索引**（指向 README / ARCHITECTURE / harness / docs）
- **禁止触碰区域**（鉴权、加密、migration 已应用文件等）
- **AI 行为约束**（必做、禁止、自检三块）
- **标准修改路径**（添加新功能 / 改数据模型 / 修 bug 三类）
- **测试与启动命令**

所有详细内容外链到 `harness/` 与 `docs/`，AGENTS.md 自身只是**路由表**。

---

## 四、AI 行为禁止项的硬约束

SOP v1 引入了 P-G-E（Planner-Generator-Evaluator）角色分离原则。当前阶段虽然由单个 AI 兼任三角色，但**通过 Hook 与 Review 强制模拟角色边界**：

| 边界 | 强制方式 | 体现位置 |
|---|---|---|
| Generator 不准修改测试 | PreCommit Hook 检测 `*_test.go` / `__tests__/` 的断言行变更 | `precommit-hook/pre-commit.sh` |
| Generator 不准删除测试 | Hook 检测测试文件删除 | 同上 |
| Generator 不准吞异常 | lint 规则 + Review checklist | `harness/coding-style.md` |
| 任何角色不准提交敏感文件 | Hook 检测 `.env`/`.pem`/`.key`/`credentials*` | 同上 |
| 任何角色不准提交生成物 | Hook 检测 `vendor/`/`node_modules/`/`dist/`/`*.exe` | 同上 |
| 新依赖必须说明 | Hook 检测依赖文件变更 + commit message 关键词 | 同上 |
| AI 代码必须理解后提交 | Review checklist | `harness/code-review.md` |

这些约束同时写入 `AGENTS.md` 的「AI 行为约束」章节，让 AI 在生成代码前就**主动规避**，而不是依赖 Hook 在提交时**被动拦截**。

---

## 五、软链接策略：一份事实，多处入口

不同 AI IDE 读不同入口文件：

| IDE | 默认读取 |
|---|---|
| Claude Code | `CLAUDE.md` / `AGENTS.md` |
| Cursor | `.cursor/rules` / `AGENTS.md` |
| Codex | `.codex/instructions.md` / `AGENTS.md` |
| CodeBuddy | `CODEBUDDY.md` / `AGENTS.md` |
| Copilot | `AGENTS.md` |
| Aider | `AGENTS.md` |

sop-builder 的做法：**所有工具入口都指向同一份 `AGENTS.md`**，通过软链接实现。

```bash
ln -sf ../AGENTS.md .claude/CLAUDE.md
ln -sf ../AGENTS.md .codex/instructions.md
ln -sf ../AGENTS.md .cursor/rules.md
ln -sf AGENTS.md     CODEBUDDY.md
```

好处：

1. 修改一处，所有工具同步生效；
2. 团队成员可以自由选择工具，无切换成本；
3. 软链接文件提交到 Git（**不进 .gitignore**），跨成员协作；
4. 个人化配置走 `.claude/CLAUDE.local.md` 等用户级文件，不污染团队配置。

冲突处理：若 `CODEBUDDY.md` 等文件已存在且非软链，sop-builder 提示**人工合并**而非覆盖，避免丢失既有内容。

---

## 六、与 SOP v1 章节的映射

| SOP v1 章节 | sop-builder 落地方式 |
|---|---|
| 一、项目 AI 友好化 1.1 | 顶层三入口 + harness/10 份 + 一键启动 `make dev` 在 README 中校验 |
| 一、项目 AI 友好化 1.2 目录结构 | `references/` 下完整提供模板骨架，SKILL.md 探查后按需填充 |
| 一、项目 AI 友好化 1.2 软链接 | `references/symlinks-setup.md` + SKILL.md「任务 K」自动装配 |
| 二、开发模式（SOLO / P-G-E） | 在 AGENTS.md「AI 行为约束」与 harness/code-review.md 中体现角色分离 |
| 三、质量检查与反馈机制 3.1 | `references/precommit-hook/` 脚本按技术栈生成 |
| 三、质量检查与反馈机制 3.2 禁止项 | Hook 脚本 + AGENTS.md 双层约束 |
| 三、反馈机制 3.3 | `harness/failures.md` 模板包含 Prompt/输出/根因/规约改进 结构 |
| 四、Spec 驱动开发 | 本 skill 不直接生成 SpecKit/OpenSpec 目录，但在 AGENTS.md 文档索引中预留 `specs/` `openspec/` 引用位 |
| 五、公共资料库 | 在 README.md 模板中预留「外部参考资料」章节 |
| 六、度量机制 | 本 skill 不负责度量，由外部度量平台扫描 `harness/` 完整性给出成熟度评分 |

---

## 七、一句话总结

- **README** 解决「这是什么」、**ARCHITECTURE** 解决「怎么建的」、**AGENTS** 解决「AI 怎么干」；
- **harness/** 是规约（用来阻止），**docs/** 是说明（用来理解）；
- **软链接 + Hook** 把规约从「写在文档上」变成「卡在工具链上」；
- **失败案例 → 规约改进** 是这个体系自我进化的唯一闭环。
