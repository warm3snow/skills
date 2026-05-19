# AI 工具软链接装配指南

> **作用**：让所有主流 AI 工具（Claude Code / Cursor / Codex / CodeBuddy / Copilot / Aider）读同一份 `AGENTS.md`，修改一处全部同步生效。
>
> **SOP v1 强制要求**：软链接文件**必须提交到 Git**，不进 `.gitignore`，以保证团队协作一致性。

---

## 一、软链接清单

| 目标文件 | 指向 | 服务的 AI 工具 |
|---|---|---|
| `CODEBUDDY.md` | `AGENTS.md` | CodeBuddy |
| `.claude/CLAUDE.md` | `../AGENTS.md` | Claude Code |
| `.codex/instructions.md` | `../AGENTS.md` | Codex |
| `.cursor/rules.md` | `../AGENTS.md` | Cursor |

> Copilot / Aider 等工具直接读取根目录 `AGENTS.md`，无需软链。

---

## 二、装配步骤（macOS / Linux / WSL）

### 2.1 前置检查

```bash
# 必须先有根目录的 AGENTS.md
test -f AGENTS.md || { echo "请先生成 AGENTS.md"; exit 1; }
```

### 2.2 一键装配脚本

```bash
#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

# 创建必要目录
mkdir -p .claude .codex .cursor

# 软链清单：目标文件 → 源文件（相对路径）
declare -a links=(
  "CODEBUDDY.md:AGENTS.md"
  ".claude/CLAUDE.md:../AGENTS.md"
  ".codex/instructions.md:../AGENTS.md"
  ".cursor/rules.md:../AGENTS.md"
)

for link in "${links[@]}"; do
  target="${link%%:*}"
  source_path="${link##*:}"

  if [ -e "$target" ] && [ ! -L "$target" ]; then
    echo "⚠️  $target 已存在且非软链，跳过（请人工合并）"
    continue
  fi

  if [ -L "$target" ]; then
    current=$(readlink "$target")
    if [ "$current" = "$source_path" ]; then
      echo "✅ $target 软链已正确，跳过"
      continue
    fi
  fi

  ln -sf "$source_path" "$target"
  echo "🔗 $target → $source_path"
done

echo ""
echo "装配完成。请执行 git add 提交这些软链文件："
echo "  git add CODEBUDDY.md .claude/ .codex/ .cursor/"
```

### 2.3 验证

```bash
# 所有软链应输出 -> AGENTS.md 或 -> ../AGENTS.md
ls -la CODEBUDDY.md .claude/CLAUDE.md .codex/instructions.md .cursor/rules.md
```

---

## 三、Windows 装配（mklink 备选方案）

Windows 不支持 `ln -s`，使用 `mklink`（需**管理员权限**或开发者模式）。

### 3.1 PowerShell 脚本

```powershell
# 以管理员身份运行 PowerShell
Set-Location (git rev-parse --show-toplevel)

New-Item -ItemType Directory -Force -Path .claude, .codex, .cursor | Out-Null

# CODEBUDDY.md → AGENTS.md
cmd /c mklink CODEBUDDY.md AGENTS.md

# .claude\CLAUDE.md → ..\AGENTS.md
cmd /c mklink .claude\CLAUDE.md ..\AGENTS.md

# .codex\instructions.md → ..\AGENTS.md
cmd /c mklink .codex\instructions.md ..\AGENTS.md

# .cursor\rules.md → ..\AGENTS.md
cmd /c mklink .cursor\rules.md ..\AGENTS.md
```

### 3.2 Git 配置（Windows）

Windows 上 Git 默认不识别符号链接。启用：

```bash
git config core.symlinks true
```

新克隆仓库时也必须启用：

```bash
git clone -c core.symlinks=true [repo-url]
```

---

## 四、冲突处理

### 4.1 目标文件已存在且非软链

**绝不覆盖**。处理流程：

1. 备份现有内容：`mv CODEBUDDY.md CODEBUDDY.md.backup`
2. 评估现有内容是否应合并到 `AGENTS.md`：
   - 是：合并后 `git rm CODEBUDDY.md.backup`，再建软链
   - 否：保留 `.backup` 并讨论
3. 建立软链

### 4.2 软链指向错误

```bash
# 检查
readlink CODEBUDDY.md  # 应输出 AGENTS.md

# 修复
ln -sf AGENTS.md CODEBUDDY.md
```

### 4.3 协作者拉取后软链失效

通常发生在 Windows 未启用 `core.symlinks`：

```bash
git config --global core.symlinks true
git checkout -- CODEBUDDY.md .claude/ .codex/ .cursor/
```

---

## 五、.gitignore 规则（强约束）

**禁止**把以下内容加入 `.gitignore`：

- ❌ `CODEBUDDY.md`
- ❌ `.claude/CLAUDE.md`（但 `.claude/CLAUDE.local.md` 允许 ignore，那是个人配置）
- ❌ `.codex/instructions.md`
- ❌ `.cursor/rules.md`
- ❌ `AGENTS.md`
- ❌ `ARCHITECTURE.md`
- ❌ `harness/`

**允许**加入 `.gitignore` 的个人级配置：

```gitignore
# 个人级 AI 配置（允许 ignore）
.claude/CLAUDE.local.md
.cursor/rules.local.md
.codex/instructions.local.md
```

---

## 六、对外开源时的处理

SOP v1 规定：对外开源时，以下文件**应被移除**：

- `AGENTS.md`
- `ARCHITECTURE.md`
- `harness/`
- `CODEBUDDY.md`
- `.claude/`
- `.codex/`
- `.cursor/`

可在开源分支的 `.gitattributes` 用 `export-ignore` 控制 `git archive` 行为，或在 release 脚本中清理。

---

## 七、装配后检查清单

- [ ] 4 个软链都已建立
- [ ] `readlink` 输出指向正确
- [ ] 软链文件已 `git add`
- [ ] `.gitignore` 未包含上述文件
- [ ] Windows 用户已启用 `core.symlinks`
- [ ] 在不同 AI 工具中验证：打开任一工具，AI 应能读到 `AGENTS.md` 内容

---

## 八、AI 行为约束

- AI **不得自动覆盖**已存在的非软链文件
- AI **不得自动**把上述文件加入 `.gitignore`
- AI 装配前必须**先检测冲突**，冲突时**停止并提示人工合并**
- AI 不得**自动执行 mklink** 等需要管理员权限的命令
