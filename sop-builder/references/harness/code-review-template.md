# Code Review 规范

> **规约定位**：PR 提交、Review、合并的硬性规则。SOP v1「保证代码质量，防止项目腐化」的核心门禁。
>
> **门禁联动**：分支保护 + PR 模板校验 + AI 辅助 Review + 人工 Review。

---

## 一、PR 提交硬约束

### 1.1 必须满足（违反则不允许合并）

- ❌ **禁止直接推 `main` / `master`**：必须走特性分支 + PR
- ❌ **禁止 PR 超过 500 行**未拆分（含新增、修改、删除行数）
- ❌ **禁止未关联单号**：PR 标题或描述必须包含 TAPD / Jira / GitHub Issue 单号
- ❌ **禁止 build / lint / 单测失败**
- ❌ **禁止覆盖率下降**超过阈值（CI 阻断）
- ❌ **禁止 AI 代码未经理解就提交**

### 1.2 建议遵守

- ✅ PR 标题：`[type] <scope>: <subject>`（如 `[feat] order: 支持订单合并支付`）
- ✅ PR 描述包含：变更动机、变更点、测试方法、风险评估、回滚方案
- ✅ 单个 PR 聚焦单个功能/修复，不混入无关变更

---

## 二、PR 模板（推荐）

```markdown
## 关联单号
TAPD: #xxx

## 变更动机
[为什么改]

## 变更点
- [改了什么 1]
- [改了什么 2]

## 测试方法
- [ ] 单测覆盖
- [ ] 接口测试
- [ ] 集成测试（如涉及）
- [ ] 本地手工验证

## 风险评估
- 影响范围：[模块/接口]
- 兼容性：[兼容 / 不兼容（已走 RFC #xxx）]
- 灰度策略：[是否需要灰分]

## 回滚方案
[如何回滚]

## Review 自检清单
- [ ] 我**理解**这段代码做了什么（不是 AI 机械生成）
- [ ] 我没有修改 / 删除已有测试断言
- [ ] 我没有引入新依赖（或已在 commit message 说明）
- [ ] 我没有提交敏感信息（.env / 密钥）
- [ ] 我没有提交生成物（vendor / node_modules / dist）
- [ ] 我已运行 `make test && make lint`
- [ ] 我已同步更新相关文档（AGENTS / docs/api / docs/domain-model）
```

---

## 三、Review 流程

### 3.1 Review 链路

```
开发者提 PR
   ↓
CI 自动检查（build / lint / test / 覆盖率）
   ↓ 通过
AI 辅助 Review（可选，规则集见下）
   ↓
人工 Review（≥ 1 名 Reviewer）
   ↓
Reviewer Approve
   ↓
合并（Squash Merge 推荐）
```

### 3.2 Reviewer 职责

- ✅ 检查变更是否符合 [`harness/*.md`](.) 规约
- ✅ 检查测试覆盖度与质量
- ✅ 检查文档同步
- ✅ 检查兼容性
- ❌ 不为「我理解了这段代码」打勾代查（提交人责任）

### 3.3 Review 时效

| PR 规模 | 期望 Review 完成时间 |
|---|---|
| < 100 行 | 4 小时内 |
| 100-300 行 | 1 工作日内 |
| 300-500 行 | 2 工作日内 |
| > 500 行 | 拆分，不接受 |

---

## 四、AI 辅助 Review（推荐）

### 4.1 AI Review 规则集

AI 在 Review 阶段自动检查：

- 命名是否符合 [`harness/coding-style.md`](./coding-style.md)
- 是否有 `_ = err` / 空 catch
- 是否硬编码配置
- 是否修改了已有测试断言
- 是否漏掉测试
- 接口变更是否更新 [`docs/api.md`](../docs/api.md)
- Schema 变更是否更新 [`docs/domain-model.md`](../docs/domain-model.md)

### 4.2 AI Review 结果

AI Review 结果作为**参考**，不替代人工 Review。Reviewer 可选择采纳或忽略，但忽略时应在 Review 评论中说明理由。

---

## 五、合并策略

### 5.1 推荐：Squash Merge

将多个 commit 压缩为一个，保持主分支干净。

### 5.2 合并 commit message 规范

```
[type] <scope>: <subject>

[optional body]

[optional footer: BREAKING CHANGE / Closes #xxx]
```

**type**: `feat | fix | refactor | docs | test | chore | perf | ci | build`

---

## 六、分支保护规则（强约束）

| 规则 | main/master |
|---|---|
| 禁止直推 | ✅ |
| 必须通过 PR | ✅ |
| 必须 CI 通过 | ✅ |
| 必须 ≥ 1 Approve | ✅ |
| 必须解决所有 Conversation | ✅ |
| 禁止 Force Push | ✅ |

由代码托管平台（GitHub / GitLab / 工蜂）的分支保护规则强制。

---

## 七、AI 代码 Review 特别规则

> SOP v1 强调"AI 代码未经理解就提交"是禁止的。

### 7.1 提交者必须能回答

- ✅ 这段代码**为什么**这么写？
- ✅ 我**修改了什么**？为什么修改？
- ✅ **测试**覆盖了哪些场景？
- ✅ **风险**在哪？

### 7.2 Reviewer 必问问题

- 「这一段为什么这么实现？」（验证理解）
- 「如果输入 X，结果是什么？」（验证测试覆盖）
- 「这个改动会影响哪些下游？」（验证兼容性思考）

无法回答 → 退回重做。

---

## 八、Hot Fix 流程

### 8.1 触发条件

线上 P0 / P1 故障，需立即修复。

### 8.2 简化流程

```
hotfix 分支 → 修复 → 单测通过 → 1 名核心成员 Review → 紧急合并
```

但**事后必须**：

- 补充完整测试
- 在 [`harness/failures.md`](./failures.md) 记录案例
- 评估是否需要更新规约

---

## 九、AI 行为约束（在 Review 阶段）

- AI 提交 PR 前必须**自检本规约**
- AI 必须**理解代码后再提交**，不允许"看起来差不多就提"
- AI **修改 Review 反馈**时应解释修改理由，不只默默改
- AI 不得**在 PR 描述中编造**测试结果、风险评估

---

## 十、参考

- 编码规范见 [`harness/coding-style.md`](./coding-style.md)
- 测试规范见 [`harness/testing.md`](./testing.md)
- 失败案例见 [`harness/failures.md`](./failures.md)
