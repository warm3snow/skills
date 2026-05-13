---
name: cross-service-ai-collaboration
description: 跨微服务、跨团队需求协作 skill。当用户需要分析一个需求涉及哪些微服务、判断跨服务影响面、生成跨服务 RFC、拆分小组任务单、分析接口/RPC/MQ 契约变更、生成交给各小组 AI 的 vibe coding prompt 时使用。该 skill 不保存业务事实，只消费 ai-system-context/ 下的系统上下文。
---

# Cross-Service AI Collaboration Skill

本 skill 用于消费 `ai-system-context/` 中的系统事实，指导 AI Agent 进行跨微服务影响面分析、RFC 生成、小组任务拆分和 vibe coding prompt 生成。

## 定位

- **本 skill 负责工作流**：任务分类、上下文加载、输出格式、禁止行为、推进顺序。
- **`ai-system-context/` 负责事实**：服务目录、服务关系、契约、功能路由、服务卡片。
- **不直接跨团队改代码**：跨团队场景默认只生成分析、RFC、任务单和 prompt。

## 触发场景

在用户提出以下需求时使用本 skill：

- 判断一个功能涉及哪些微服务或小组
- 分析跨服务影响面
- 生成跨服务 RFC
- 拆分各小组 / 各服务任务单
- 分析接口、RPC、MQ、字段语义变更影响
- 生成给单个服务 AI 的 vibe coding prompt
- 推进跨服务联调、灰度、回滚计划

## 上下文根目录

默认上下文目录：

```text
ai-system-context/
```

如果该目录不存在，先提示需要生成或提供跨服务上下文，不要猜测系统结构。

## 文件职责

| 文件 | 职责 | 何时读取 |
|---|---|---|
| `ai-system-context/CONTEXT-MAP.md` | 上下文地图，说明文件职责和读取策略 | 任何跨服务任务开始前优先读取 |
| `ai-system-context/SYSTEM.md` | 系统整体目标、核心业务域、全局边界 | 需要理解业务背景时 |
| `ai-system-context/SERVICE-CATALOG.md` | 服务清单、归属小组、职责边界 | 判断服务归属和候选服务时 |
| `ai-system-context/SERVICE-GRAPH.md` | 服务、DB、MQ、外部系统依赖 | 分析调用链和影响面时 |
| `ai-system-context/CONTRACTS.md` | HTTP/RPC/MQ 契约和兼容规则 | 涉及接口、字段、事件变更时 |
| `ai-system-context/FEATURE-ROUTING.md` | 功能域到服务的映射 | 新需求影响面分析时 |
| `ai-system-context/CHANGE-PLAYBOOKS.md` | 跨服务变更 SOP | 生成 RFC、联调、发布、回滚计划时 |
| `ai-system-context/VIBE-CODING-PROMPTS.md` | AI prompt 模板 | 生成给各小组 AI 的 prompt 时 |
| `ai-system-context/services/<service>.md` | 单服务职责、边界、能力和风险 | 拆分具体服务任务时 |

## 工作流 1：跨服务影响面分析

### 读取顺序

1. `ai-system-context/CONTEXT-MAP.md`，如存在
2. `ai-system-context/FEATURE-ROUTING.md`
3. `ai-system-context/SERVICE-CATALOG.md`
4. `ai-system-context/SERVICE-GRAPH.md`
5. `ai-system-context/CONTRACTS.md`
6. 候选服务对应的 `ai-system-context/services/<service>.md`

### 输出格式

```markdown
## 任务理解
[用业务语言复述需求]

## 涉及服务判断
| 服务 | 小组 | 涉及原因 | 置信度 | 待确认项 |
|---|---|---|---|---|

## 调用链 / 数据流
[Mermaid 或步骤列表]

## 契约影响
| 契约 | 提供方 | 消费方 | 变更类型 | 兼容性风险 |
|---|---|---|---|---|

## 推荐推进顺序
1. [步骤]

## 待确认问题
- [问题]
```

## 工作流 2：生成跨服务 RFC

### 前置条件

必须先完成影响面分析。若涉及服务、小组或契约不明确，先输出待确认项，不要直接生成确定性方案。

### 读取顺序

1. 影响面分析结果
2. `ai-system-context/CHANGE-PLAYBOOKS.md`
3. `ai-system-context/CONTRACTS.md`
4. 相关 `ai-system-context/services/<service>.md`

### 输出路径

```text
ai-system-context/rfcs/<feature-name>.md
```

### RFC 必须包含

- 需求背景
- 业务目标
- 非目标
- 涉及服务和小组
- 跨服务数据流
- 契约变更
- 小组任务拆分
- 联调计划
- 发布和回滚
- 风险和待确认项

## 工作流 3：生成小组 / 服务任务单

### 读取顺序

1. 已确认的 `ai-system-context/rfcs/<feature-name>.md`
2. 对应 `ai-system-context/services/<service>.md`
3. `ai-system-context/CONTRACTS.md` 中相关契约
4. `ai-system-context/VIBE-CODING-PROMPTS.md`

### 输出路径

```text
ai-system-context/tasks/<feature-name>/<service-or-team>.md
```

### 任务单原则

- 一个任务单只面向一个小组或一个服务。
- 只描述该服务需要交付的内容。
- 不要求该小组修改其他小组服务。
- 如果该服务只需确认兼容性，也生成“确认型任务单”。

## 工作流 4：生成单服务 vibe coding prompt

### 读取顺序

1. 小组任务单
2. 对应服务卡片
3. 相关契约
4. `ai-system-context/VIBE-CODING-PROMPTS.md`

### Prompt 必须强调

- 只负责当前服务
- 不跨仓库修改其他服务
- 先输出修改计划、契约影响、测试计划和风险点
- 涉及契约变更时先停下来确认

## 契约变更默认规则

- 新增字段优先，避免修改旧字段语义。
- 删除字段默认禁止，必须走 RFC。
- 修改字段语义默认禁止，必须走 RFC、灰度和消费者确认。
- 新增枚举值必须通知所有消费方确认兜底逻辑。
- MQ 消息必须考虑老消费者和重复消费幂等。

## 禁止行为

- 禁止在未确认服务归属时指定某个小组改代码。
- 禁止猜测字段、枚举、接口的业务语义。
- 禁止跳过 `CONTRACTS.md` 直接给出接口变更方案。
- 禁止把跨服务需求直接拆成代码修改，而不生成 RFC 或任务单。
- 禁止要求一个小组修改其他小组负责的服务。
- 禁止一次性大范围重构多个服务。

## 信息不足时的处理

如果上下文缺失，输出：

```markdown
## 信息不足，无法确定

缺失信息：
- [缺失项]

建议补充：
- [需要哪个小组或哪个文件补充]

可先推进的部分：
- [可做的分析或任务]
```

不要为了完整性编造服务关系、契约字段或小组归属。
