# PreCommit Hook 安装与启用指南

> **作用**：把 SOP v1 §3.2 的禁止项变成**提交时强制门禁**，覆盖：
> - 测试断言保护（P-G-E 角色分离）
> - 敏感文件 / 生成物拦截
> - 新依赖说明
> - 按技术栈的 build / lint / 单测

## 方案选择

| 方案 | 适用场景 | 优势 |
|---|---|---|
| **方案 A：lefthook**（推荐） | 所有项目 | 声明式配置、并行执行、跨平台 |
| **方案 B：.githooks/** | 不想引入额外依赖 | 零依赖、纯 shell |

### 方案 A：使用 lefthook（推荐）

```bash
# 安装 lefthook
brew install lefthook  # macOS
# 或 go install github.com/evilmartians/lefthook@latest

# 复制模板到项目根目录
cp [skill-path]/references/precommit-hook/lefthook-template.yml ./lefthook.yml

# 按项目技术栈取消注释对应命令，注释不适用的

# 安装 hook
lefthook install
```

验证：`lefthook run pre-commit`

### 方案 B：使用 .githooks/（见下文）

---

## 一、Hook 脚本结构

```
.githooks/
├── pre-commit                # 主入口（必装）
├── pre-commit-go.sh          # Go 子脚本（go.mod 存在时启用）
├── pre-commit-node.sh        # Node 子脚本（package.json 存在时启用）
└── pre-commit-python.sh      # Python 子脚本（requirements.txt 或 pyproject.toml 存在时启用）
```

主入口检测技术栈后自动调用对应子脚本。混合栈项目会**并行执行**所有匹配的子脚本。

---

## 二、安装步骤

### 2.1 复制脚本

```bash
mkdir -p .githooks

# 复制本 skill references/precommit-hook/ 下的所有脚本到目标项目 .githooks/
# 主入口必装
cp [skill-path]/references/precommit-hook/pre-commit.sh .githooks/pre-commit

# 按项目技术栈复制对应子脚本
cp [skill-path]/references/precommit-hook/pre-commit-go.sh     .githooks/  # Go 项目
cp [skill-path]/references/precommit-hook/pre-commit-node.sh   .githooks/  # Node 项目
cp [skill-path]/references/precommit-hook/pre-commit-python.sh .githooks/  # Python 项目
```

### 2.2 赋予执行权限

```bash
chmod +x .githooks/pre-commit
chmod +x .githooks/pre-commit-*.sh
```

### 2.3 启用 Hook

```bash
# 关键：让 Git 使用 .githooks/ 而不是默认的 .git/hooks/
git config core.hooksPath .githooks
```

> **为什么不直接放 `.git/hooks/`？**
> `.git/hooks/` 不进 Git，每个协作者要重新装。`.githooks/` 提交到仓库，所有人 clone 后只需运行 `git config core.hooksPath .githooks` 一次。

### 2.4 验证

```bash
# 测试 Hook 是否生效
echo "test" > /tmp/.env
git add /tmp/.env
git commit -m "test" 2>&1 | grep -q "敏感文件" && echo "✅ Hook 已生效"
git reset HEAD /tmp/.env
```

---

## 三、推荐：在 Makefile 中提供一键安装

在目标项目的 `Makefile` 中加入：

```makefile
.PHONY: install-hooks
install-hooks:
	@chmod +x .githooks/*
	@git config core.hooksPath .githooks
	@echo "✅ Git hooks installed"
```

新人 clone 后：

```bash
make install-hooks
```

---

## 四、与已有 Hook 框架集成

### 4.1 与 husky（Node 项目）集成

如果项目已用 husky，**两种选择**：

**方案 A：完全切换到 .githooks/**

```bash
# 删除 husky 配置
npm uninstall husky
rm -rf .husky
# 启用 .githooks/
git config core.hooksPath .githooks
```

**方案 B：在 husky 中调用 .githooks/**

在 `.husky/pre-commit` 中加入：

```sh
#!/usr/bin/env sh
. "$(dirname -- "$0")/_/husky.sh"

exec .githooks/pre-commit "$@"
```

### 4.2 与 pre-commit (Python 框架) 集成

`.pre-commit-config.yaml` 中加入本地 hook：

```yaml
repos:
  - repo: local
    hooks:
      - id: sop-precommit
        name: SOP v1 PreCommit Checks
        entry: .githooks/pre-commit
        language: system
        pass_filenames: false
        stages: [commit]
```

### 4.3 与 lefthook 集成

`lefthook.yml`：

```yaml
pre-commit:
  commands:
    sop:
      run: .githooks/pre-commit
```

---

## 五、紧急情况绕过 Hook

**强烈不建议**绕过 Hook，但在 P0 故障紧急修复时可临时使用：

```bash
git commit --no-verify -m "[hotfix] xxx"
```

事后必须：
1. 立即补充本应通过的检查（lint / 单测）
2. 在 [`harness/failures.md`](../harness/failures.md) 记录绕过原因
3. 评估是否需要改进 Hook 规则

---

## 六、Hook 自身的更新

Hook 脚本本身随仓库演进。更新流程：

1. 修改 `.githooks/*.sh`
2. 在 PR 描述中说明 Hook 变更
3. Review 重点关注：是否会产生大量误报、是否过严阻塞协作
4. 合并后所有协作者自动生效（已启用 `core.hooksPath`）

---

## 七、常见问题

### 7.1 Hook 报权限错误

```bash
chmod +x .githooks/*
```

### 7.2 Windows 上 Hook 不执行

Windows Git Bash 应能正常执行 POSIX sh 脚本。若不行：

```bash
git config --global core.hooksPath .githooks
```

或在 WSL 中开发。

### 7.3 Hook 太慢

- 子脚本只检查暂存文件（已实现）
- `go test` 用 `-short`（已实现）
- 大项目可拆分为 pre-commit（快速）+ pre-push（完整）

### 7.4 Hook 误报

- 在 commit message 中按约定加前缀：`[test-modify]` / `[test-delete]` / `[hotfix]`
- 修改 Hook 脚本调整规则
- 极端情况 `--no-verify` 临时绕过 + 事后复盘

---

## 八、AI 行为约束

- AI **不得自动执行** `git config core.hooksPath`（需用户授权）
- AI **不得绕过** Hook 直接 `--no-verify`
- AI **不得修改** Hook 脚本来让自己的代码通过
- AI 装配 Hook 时必须**先检测**是否已有 husky / pre-commit 框架，冲突时**停下来与用户确认**

---

## 九、CI 与 Hook 的关系

| 检查 | Hook（本地） | CI（远端） |
|---|---|---|
| 格式化 | ✅ | ✅ |
| Lint | ✅（仅暂存文件） | ✅（全量） |
| 单测 | ✅（快速） | ✅（全量 + 覆盖率） |
| 集成测试 | ❌ | ✅ |
| 敏感文件 | ✅ | ✅ |
| 测试断言保护 | ✅（警告） | ✅（阻断） |

**原则**：
- Hook 提供**快速反馈**（本地秒级）
- CI 提供**完整保障**（提交后分钟级）
- Hook 失败 ≈ CI 必失败，所以 Hook 通过 ≠ 一定能合并

---

## 十、参考

- SOP v1 §3.2 禁止项清单
- [`harness/code-review.md`](../harness/code-review.md) Review 规范
- [`harness/testing.md`](../harness/testing.md) 测试规范（P-G-E 原则）
