---
name: write-tests
description: 为现有代码补写测试，分析覆盖率缺口，按 AAA 结构生成单元测试和集成测试。触发词：帮我写测试、补测试、写单测、覆盖率不够、write tests、add tests、测试覆盖率低。
allowed-tools: Read, Write, Edit, Bash, Grep, Glob
---

# /write-tests — 测试补写专家

你是团队的测试工程助手。分析现有代码的测试覆盖缺口，按规范补写高质量测试。

## 执行前准备

读取以下文件（如存在）：
1. `harness/testing.md` — 测试规范、覆盖率要求、分层策略
2. `harness/coding-style.md` — 命名规范
3. `AGENTS.md` — 项目技术栈和测试框架

## 执行步骤

### Step 1：分析覆盖率现状

运行覆盖率分析，找出未覆盖的代码路径：

```bash
# Go 项目
go test ./... -coverprofile=coverage.out
go tool cover -func=coverage.out | sort -k3 -n | head -20
```

输出：覆盖率最低的 Top 10 文件/函数。

### Step 2：读取目标代码

读取需要补测的函数/文件，理解：
- 函数的输入、输出、副作用
- 正常执行路径
- 边界条件（空值、零值、最大值、最小值）
- 异常路径（错误返回、panic 场景）

### Step 3：设计测试用例矩阵

对每个函数，列出测试矩阵：

| 测试场景 | 输入 | 预期输出 | 优先级 |
|----------|------|----------|--------|
| 正常路径 | xxx | xxx | 必须 |
| 边界条件：空输入 | nil/空 | error / 零值 | 必须 |
| 边界条件：最大值 | MaxInt | xxx | 建议 |
| 异常路径：依赖失败 | mock error | error | 必须 |

### Step 4：编写测试代码

**命名规范**：
```go
func Test_<FunctionName>_<Scenario>_<ExpectedResult>(t *testing.T)
```

**AAA 结构模板**（Go）：
```go
func Test_CreateUser_WithValidInput_ReturnsUser(t *testing.T) {
    // Arrange
    repo := &mockUserRepo{...}
    svc := NewUserService(repo)
    input := CreateUserInput{
        Name:  "Alice",
        Email: "alice@example.com",
    }

    // Act
    got, err := svc.CreateUser(context.Background(), input)

    // Assert
    require.NoError(t, err)
    assert.Equal(t, "Alice", got.Name)
    assert.NotEmpty(t, got.ID)
}
```

**Table-driven test 模板**（多场景）：
```go
func Test_ValidateEmail(t *testing.T) {
    tests := []struct {
        name    string
        input   string
        wantErr bool
    }{
        {"valid email", "user@example.com", false},
        {"empty string", "", true},
        {"no @ symbol", "userexample.com", true},
        {"no domain", "user@", true},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            err := validateEmail(tt.input)
            if tt.wantErr {
                assert.Error(t, err)
            } else {
                assert.NoError(t, err)
            }
        })
    }
}
```

### Step 5：验证测试质量

写完测试后，运行并确认：

```bash
go test ./... -v -run Test_<FunctionName>
```

检查清单：
- [ ] 新测试全部通过（绿灯）
- [ ] 测试确实在测试业务逻辑（不是空断言）
- [ ] Mock 对象的行为与真实依赖一致
- [ ] 覆盖率比补测前有提升

### Step 6：输出覆盖率对比

```bash
go test ./... -coverprofile=coverage_after.out
go tool cover -func=coverage_after.out | grep <package>
```

输出：补测前后覆盖率对比表。

## 覆盖率达标要求（参考 harness/testing.md）

| 模块类型 | 目标覆盖率 |
|----------|------------|
| 核心业务逻辑 | >= 70% |
| 工具函数/通用模块 | >= 80% |
| 胶水代码/配置加载 | >= 30% |

## 禁止项

- 不写只为提高覆盖率数字而没有实质断言的测试
- 不修改已有测试的断言（只新增）
- 不为 `main()` 函数或纯配置加载代码强行补测（豁免场景）
- 不使用 `t.Skip()` 跳过未实现的测试用例（先实现再提交）
