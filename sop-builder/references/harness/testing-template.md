# 测试规范

> **规约定位**：SOP v1「代码 + 用例 + 测试，三位一体」的具体落地。**没有测试的代码不允许合并。**
>
> **门禁联动**：
> - commit 前：build + lint + 单测必须通过
> - CI：全量单测 + 覆盖率检查
> - 提测后：长程 E2E

---

## 一、测试分层

| 层次 | 范围 | 工具 | 触发时机 | 期望覆盖率 |
|---|---|---|---|---|
| **单元测试** | 单个函数 / 方法 | `go test` / `jest` / `pytest` | 每次保存 / commit / CI | ≥ 70% |
| **模块测试** | 单个模块内集成 | 同上 + sqlmock / mock | commit / CI | ≥ 50% |
| **接口测试** | HTTP/RPC 接口 | `go test` 起内嵌 server / Supertest | CI | 100% 接口覆盖 |
| **集成测试** | 多模块 + 真实中间件 | testcontainers / docker-compose | CI / 提测 | 核心场景 |
| **E2E 测试** | 全链路黑盒 | 自动化平台 / Postman | 每日冒烟 / 提测 | 核心场景 |

---

## 二、单元测试规则

### 2.1 文件位置

- Go：`xxx_test.go` 与被测文件同包
- Java：`src/test/java/...` 与主代码包结构对应
- Python：`tests/` 目录
- JS/TS：`__tests__/` 或 `*.test.ts` 邻接被测文件

### 2.2 测试函数命名

```go
// 推荐 BDD 风格
func TestOrderService_CreateOrder_WhenUserNotActive_ReturnsError(t *testing.T) {}

// 或表驱动
func TestOrderService_CreateOrder(t *testing.T) {
  cases := []struct {
    name      string
    userID    int64
    wantError error
  }{
    {"用户未激活返回 ErrUserNotActive", 100, ErrUserNotActive},
    {"商品列表为空返回 ErrEmptyItems", 200, ErrEmptyItems},
  }
  // ...
}
```

### 2.3 测试必须包含的场景

- ✅ Happy path（正常流程）
- ✅ 边界值（空值、零值、最大值）
- ✅ 错误路径（参数错误、依赖错误）
- ✅ 并发场景（如适用）

### 2.4 禁止的测试写法

- ❌ 测试无断言（assert）
- ❌ 测试依赖外部网络
- ❌ 测试依赖固定时间 / 随机数（用注入）
- ❌ 测试间共享可变状态
- ❌ `// skip` 跳过测试不说明理由

---

## 三、Mock 约定

| 依赖类型 | Mock 方式 |
|---|---|
| HTTP 调用 | `httptest.Server` 或 `gomock` |
| RPC 调用 | `gomock` 生成 mock |
| 数据库 | `sqlmock` 或 `testcontainers` 起真实 MySQL |
| Redis | `miniredis` 或 `testcontainers` |
| 时间 | 注入 `Clock` 接口，测试用 `FakeClock` |
| 随机 | 注入 `Rand` 接口 |

**禁止**直接 mock 业务类（如 `OrderService`），应 mock 它的依赖。

---

## 四、覆盖率要求

| 模块 | 行覆盖率 | 分支覆盖率 |
|---|---|---|
| `internal/service/` | ≥ 80% | ≥ 70% |
| `internal/handler/` | ≥ 70% | ≥ 60% |
| `internal/repo/` | ≥ 60% | - |
| `pkg/` | ≥ 80% | ≥ 70% |
| `internal/middleware/` | ≥ 90% | ≥ 80% |

**整体硬约束**：项目总覆盖率 ≥ `[待确认]%`，CI 阻断阈值。

```bash
make coverage
# 输出覆盖率报告到 coverage.html
```

---

## 五、AI 行为约束（P-G-E 角色分离硬约束）

> SOP v1 引入 Planner-Generator-Evaluator 角色分离。Generator（写代码的 AI）**不准修改测试**。

### 5.1 禁止行为（PreCommit Hook 拦截）

- ❌ **修改已有测试文件的断言**（即使断言"看起来"是错的）
- ❌ **删除已有测试**（除非 PR 中明确说明理由）
- ❌ **跳过测试**（`t.Skip()` / `it.skip()` / `@pytest.mark.skip`）不说明理由
- ❌ **降低断言强度**（如 `assertEqual` 改为 `assertNotNil`）
- ❌ **修改测试以适配代码**（应该让代码适配测试，而不是反过来）

### 5.2 必做行为

- ✅ **TDD 流程**：先写测试 → 测试失败 → 写实现 → 测试通过
- ✅ **Bug 修复必须附回归测试**
- ✅ 新功能 PR 必须**同时提交测试**
- ✅ 测试名称必须**描述业务场景**，不要 `TestFunc1`

### 5.3 测试失败时的正确做法

```
测试失败
  ↓
是测试错了，还是代码错了？
  ↓
代码错了 → 修代码（推荐）
  ↓
测试真的错了 → 在 PR 中说明理由 + 让代码负责人 review 测试改动
```

**绝不**：测试失败 → 改测试让它通过。

---

## 六、E2E 测试

### 6.1 触发时机

| 时机 | 范围 | 阻断 |
|---|---|---|
| 每日冒烟 | 核心场景 | 告警 |
| 提测后 | 长程全量 | 阻断发布 |
| 发布前 | 全量 + 人工验收 + Checklist | 阻断上线 |

### 6.2 E2E 用例归属

- **黑盒用例**（需求阶段）：测试团队产出
- **白盒用例**（开发完成）：测试 + 开发协作产出
- 用例存储位置：`[E2E 平台 / 代码仓库路径]`

---

## 七、性能测试

- 关键接口必须有压测基准
- 压测脚本存放：`[路径]`
- 性能 SLA：见 [`ARCHITECTURE.md`](../ARCHITECTURE.md) §七

---

## 八、AI 测试质量检查清单

提交前 AI 自检：

- [ ] 测试覆盖了 Happy path
- [ ] 测试覆盖了至少 1 个错误路径
- [ ] 测试函数名描述了业务场景
- [ ] 没有修改/删除已有测试断言
- [ ] 没有 `t.Skip` 跳过
- [ ] 测试不依赖网络/时间/随机
- [ ] `make test` 本地通过
- [ ] 覆盖率达标
