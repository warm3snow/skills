# 编码规范

> **规约定位**：本服务的编码硬性规则。违反者 Lint Hook 阻断，Code Review 不通过。
>
> **门禁联动**：保存时 lint 提示 → commit 时 lint 阻断 → CI lint 阻断合并。

---

## 一、命名规范

### 1.1 通用原则

- **完整业务语义**，禁止缩写
  - ❌ `calcTaxAmt` / `usrCnt` / `getOrdInfo`
  - ✅ `calculateTaxAmount` / `userCount` / `getOrderInfo`
- **不出现拼音**（除非是业务领域专有名词，如 `huabei`）
- **不出现 magic 字符串/数字**，提取为常量

### 1.2 [按语言填充]

> Go 项目示例：

| 实体 | 风格 | 示例 |
|---|---|---|
| 包名 | 小写单词，无下划线 | `order`, `payment` |
| 接口 | 大驼峰 + `er` 后缀（单方法接口） | `Reader`, `OrderCreator` |
| 结构体 | 大驼峰 | `OrderService` |
| 公开方法 | 大驼峰 | `CreateOrder` |
| 私有方法 | 小驼峰 | `validateInput` |
| 常量 | 大驼峰或全大写 | `MaxRetryCount` |
| 错误变量 | `Err` 前缀 | `ErrOrderNotFound` |

---

## 二、错误处理

### 2.1 硬性规则

- ❌ 禁止 `_ = err`（静默吞）
- ❌ 禁止 `catch (Exception e) { }`（空 catch）
- ❌ 禁止 `except: pass`
- ✅ 所有错误必须**显式处理**：要么 return 上抛，要么记日志后降级
- ✅ 错误必须**带业务上下文**：`fmt.Errorf("create order failed for user %d: %w", userID, err)`

### 2.2 错误分类

| 类型 | 处理方式 | 示例 |
|---|---|---|
| 业务错误（用户输入错误） | 返回业务错误码 + 友好消息 | `ErrInvalidPhoneNumber` |
| 系统错误（DB 连接失败） | 记日志 + 上抛 + 触发告警 | `ErrDBConnection` |
| 第三方错误 | 重试 + 降级 + 告警 | `ErrPaymentTimeout` |

---

## 三、注释规范

### 3.1 注释写"为什么"，不写"做了什么"

```go
// ❌ 不好
// 把订单状态设为 2
order.Status = 2

// ✅ 好
// 订单创建后立即进入待支付状态（业务方要求 5 分钟内必须支付，否则自动取消，见 ADR-007）
order.Status = StatusPendingPayment
```

### 3.2 特殊注释标记

| 标记 | 含义 | 使用场景 |
|---|---|---|
| `// NOTE:` | 解释非常规设计的理由 | 反直觉的实现 |
| `// IMPORTANT:` | 强警告，修改前必须理解 | 易踩坑的逻辑 |
| `// FIXME:` | 已知问题，待修复 | 临时绕过的 bug |
| `// TODO:` | 计划性工作 | 后续优化 |
| `// HACK:` | 临时方案，非长期解 | 临时绕过 |

> 这些标记会被 [`docs/decision-log.md`](../docs/decision-log.md) 与 [`harness/failures.md`](./failures.md) 工具化扫描。

### 3.3 公开接口/方法必须有文档注释

```go
// CreateOrder 创建订单。
//
// 业务规则：
//   - userID 必须是已激活用户
//   - items 不能为空
//   - 同一用户 1 秒内最多创建 1 笔订单（限流由调用方保证）
//
// 错误：
//   - ErrUserNotActive: 用户未激活
//   - ErrEmptyItems:    商品列表为空
//   - ErrRateLimited:   命中限流
func (s *OrderService) CreateOrder(ctx context.Context, userID int64, items []Item) (*Order, error) {
```

---

## 四、日志规范

### 4.1 硬性规则

- ❌ 禁止 `fmt.Println` / `console.log` / `print`
- ✅ 使用项目统一日志库（如 `pkg/logger`）
- ✅ 日志必须**结构化**（key-value），便于检索

### 4.2 日志级别

| 级别 | 使用场景 | 示例 |
|---|---|---|
| DEBUG | 详细调试信息，生产关闭 | 入参出参 |
| INFO | 关键业务事件 | 订单创建成功 |
| WARN | 异常但可恢复 | 第三方超时已降级 |
| ERROR | 业务错误或系统错误 | DB 写入失败 |
| FATAL | 服务不可用 | 启动配置错误 |

### 4.3 不允许的日志内容

- ❌ 密码、Token、密钥、身份证号、银行卡号
- ❌ 完整请求体（含敏感字段）
- ✅ 必须脱敏：手机号 `138****1234`、邮箱 `a***@example.com`

---

## 五、配置规范

- ❌ 禁止硬编码 URL、端口、超时、阈值
- ✅ 所有可变值放 `config/`
- ✅ 敏感配置走环境变量或配置中心，**不能提交到 Git**

详见 [`harness/deployment.md`](./deployment.md) 配置管理章节。

---

## 六、代码结构规范

### 6.1 分层调用规则（强约束）

```
Handler → Service → Repo
   ↑        ↑
   只能从上往下调用，禁止反向
```

- ❌ Handler 直接调 Repo（绕过 Service）
- ❌ Service 包之间循环依赖
- ❌ Repo 调 Service

### 6.2 文件长度

- 单文件 ≤ 500 行（特殊情况除外，需在文件顶部说明）
- 单函数 ≤ 80 行（圈复杂度 ≤ 10）

---

## 七、格式化与 Lint

| 语言 | 必须通过 |
|---|---|
| Go | `gofmt`, `goimports`, `golangci-lint run` |
| Java | `google-java-format`, `checkstyle`, `spotbugs` |
| Python | `ruff format`, `ruff check`, `mypy` |
| TypeScript / JS | `prettier --check`, `eslint` |

PreCommit Hook 会在提交前自动检查。

---

## 八、AI 行为约束

- AI 生成代码后必须**自检本规约**
- AI 不得**静默吞异常**
- AI 不得**新增硬编码配置**
- AI 不得**修改已有错误处理为静默吞**

---

## 九、违反案例（取自 failures.md）

| # | 违反点 | 根因 | 修复方式 |
|---|---|---|---|
| 1 | `[待补充]` | | |
