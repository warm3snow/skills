---
name: commit
description: 生成符合团队规范的 Git commit message，自动关联单号，检查暂存区变更内容。触发词：帮我提交、生成 commit、写 commit message、commit 一下、提交代码。
allowed-tools: Bash(git:*)
---

# /commit — 规范 Commit Message 生成

你是团队 Git 提交规范的执行者。分析当前暂存区变更，生成符合规范的 commit message。

## 执行步骤

### Step 1：分析暂存区

```bash
git diff --cached --stat
git diff --cached
```

### Step 2：检查单号

询问用户（如未提供）：「本次提交关联的单号是？（格式：TAPD-1234 / JIRA-1234）」

如用户已在输入中提供单号，直接使用。

### Step 3：生成 commit message

**格式规范**：

```
<type>: [TAPD-XXXX] <简短描述（≤ 50 字符）>

<可选正文：说明 what 和 why，每行 ≤ 72 字符>

<可选 footer：Breaking Change 或关联 Issue>
```

**type 枚举**：

| type | 场景 |
|------|------|
| `feat` | 新功能 |
| `fix` | Bug 修复 |
| `refactor` | 重构（不影响功能） |
| `test` | 新增或修改测试 |
| `docs` | 文档变更 |
| `chore` | 构建、依赖、配置变更 |
| `perf` | 性能优化 |
| `ci` | CI/CD 配置变更 |

**示例**：

```
feat: [TAPD-1234] 新增用户身份验证模块

实现基于 JWT 的无状态认证，支持 access_token + refresh_token 双 token 机制。
选择 JWT 而非 session 的原因：兼容微服务横向扩展，无需共享 session 存储。
```

### Step 4：安全检查

提交前确认暂存区不包含以下内容（如发现，**阻断并告警**）：

- `.env`、`.pem`、`.key`、`*secret*`、`*password*` 等敏感文件
- `vendor/`、`node_modules/`、`dist/`、`build/` 等生成物
- 二进制文件（非预期情况下）

### Step 5：输出 commit 命令

输出可直接执行的命令：

```bash
git commit -m "$(cat <<'EOF'
<type>: [TAPD-XXXX] <描述>

<正文（如有）>
EOF
)"
```

## 禁止项

- 不生成没有单号的 commit（除非用户明确说明豁免原因）
- 不使用模糊描述（如 `fix bug`、`update code`、`modify`）
- 不在发现敏感文件时继续执行提交
- 不自动执行 `git push`，只生成 commit 命令供用户确认后执行
