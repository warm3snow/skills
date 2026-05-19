#!/usr/bin/env sh
# .githooks/pre-commit
#
# SOP v1 PreCommit Hook 主入口。
# 按 AI 研发工作流 SOP v1 §3.2 实现强制门禁：
#   - 测试断言保护（P-G-E 角色分离原则）
#   - 敏感文件拦截
#   - 生成物拦截
#   - 新依赖说明检查
#   - 按技术栈调用对应子脚本（build / lint / 单测）
#
# 设计原则：POSIX sh，不依赖 bash-only 语法，便于跨平台。

set -eu

REPO_ROOT="$(git rev-parse --show-toplevel)"
HOOKS_DIR="$REPO_ROOT/.githooks"
RED=$(printf '\033[0;31m')
GREEN=$(printf '\033[0;32m')
YELLOW=$(printf '\033[0;33m')
RESET=$(printf '\033[0m')

# ----------------------------------------------------------------------
# 工具函数
# ----------------------------------------------------------------------

print_step()   { printf "%s▶ %s%s\n" "$YELLOW" "$1" "$RESET"; }
print_ok()     { printf "%s✓ %s%s\n"  "$GREEN"  "$1" "$RESET"; }
print_fail()   { printf "%s✗ %s%s\n"  "$RED"    "$1" "$RESET"; }
fail()         { print_fail "$1"; exit 1; }

# 已暂存（staged）的文件
staged_files() {
  git diff --cached --name-only --diff-filter=ACMR
}

# 已暂存且已删除的文件
staged_deleted() {
  git diff --cached --name-only --diff-filter=D
}

# ----------------------------------------------------------------------
# 检查 1：敏感文件拦截
# ----------------------------------------------------------------------
check_sensitive_files() {
  print_step "检查敏感文件"

  sensitive_patterns='\.env$|\.env\.|\.pem$|\.key$|\.p12$|\.pfx$|credentials|secret|^id_rsa|^id_ed25519'

  bad=$(staged_files | grep -E "$sensitive_patterns" || true)
  if [ -n "$bad" ]; then
    print_fail "检测到敏感文件:"
    printf '%s\n' "$bad" | sed 's/^/  - /'
    printf "\n%s如确实需要提交（如示例文件），请改名（例如 .env.example）或单独说明。%s\n" "$YELLOW" "$RESET"
    exit 1
  fi
  print_ok "无敏感文件"
}

# ----------------------------------------------------------------------
# 检查 2：生成物拦截
# ----------------------------------------------------------------------
check_generated_artifacts() {
  print_step "检查生成物"

  artifact_patterns='^vendor/|^node_modules/|^dist/|^build/|\.exe$|\.class$|\.pyc$|__pycache__/'

  bad=$(staged_files | grep -E "$artifact_patterns" || true)
  if [ -n "$bad" ]; then
    print_fail "检测到生成物:"
    printf '%s\n' "$bad" | sed 's/^/  - /'
    printf "\n%s请加入 .gitignore，或在 commit message 中明确说明。%s\n" "$YELLOW" "$RESET"
    exit 1
  fi
  print_ok "无生成物"
}

# ----------------------------------------------------------------------
# 检查 3：测试断言保护（P-G-E 角色分离原则）
# ----------------------------------------------------------------------
check_test_modifications() {
  print_step "检查测试断言保护（P-G-E 原则）"

  # 测试文件 pattern
  test_patterns='_test\.go$|\.test\.[tj]sx?$|\.spec\.[tj]sx?$|^tests?/.*\.py$|/__tests__/'

  modified_tests=$(staged_files | grep -E "$test_patterns" || true)
  deleted_tests=$(staged_deleted | grep -E "$test_patterns" || true)

  # 删除测试 → 阻断
  if [ -n "$deleted_tests" ]; then
    print_fail "检测到测试文件被删除:"
    printf '%s\n' "$deleted_tests" | sed 's/^/  - /'
    printf "\n%s如确需删除，请在 commit message 中以 [test-delete] 前缀说明理由。%s\n" "$YELLOW" "$RESET"
    if ! git log -1 --format=%B 2>/dev/null | grep -q '\[test-delete\]'; then
      exit 1
    fi
  fi

  # 修改断言行 → 警告（不强制阻断，但需 commit message 说明）
  if [ -n "$modified_tests" ]; then
    assertion_pattern='assert|expect|should|require\.|t\.(Error|Fatal|Fail)|self\.assert'
    suspicious=""
    for f in $modified_tests; do
      diff=$(git diff --cached -- "$f" || true)
      if printf '%s' "$diff" | grep -E "^[-+]" | grep -E "$assertion_pattern" >/dev/null 2>&1; then
        suspicious="$suspicious $f"
      fi
    done
    if [ -n "$suspicious" ]; then
      printf "%s⚠ 检测到测试断言可能被修改:%s\n" "$YELLOW" "$RESET"
      for f in $suspicious; do printf "  - %s\n" "$f"; done
      printf "\n%sP-G-E 原则：Generator 不准动 Evaluator 的测试。\n" "$YELLOW"
      printf "若确为合理修改（如重命名、新增 case），请在 commit message 中以 [test-modify] 前缀说明：%s\n" "$RESET"
      if ! git log -1 --format=%B 2>/dev/null | grep -q '\[test-modify\]' \
         && ! git diff --cached --no-renames -- /dev/null 2>/dev/null; then
        printf "%s（提示：本地校验阶段无 commit message，按 [test-modify] 约定继续提交）%s\n" "$YELLOW" "$RESET"
      fi
    fi
  fi

  print_ok "测试断言保护检查通过"
}

# ----------------------------------------------------------------------
# 检查 4：新依赖说明
# ----------------------------------------------------------------------
check_dependency_changes() {
  print_step "检查新依赖说明"

  dep_files='go\.mod$|go\.sum$|package\.json$|package-lock\.json$|yarn\.lock$|pnpm-lock\.yaml$|requirements\.txt$|poetry\.lock$|pyproject\.toml$|Cargo\.toml$|Cargo\.lock$|pom\.xml$|build\.gradle$'

  changed=$(staged_files | grep -E "$dep_files" || true)
  if [ -n "$changed" ]; then
    printf "%s⚠ 依赖文件有变更:%s\n" "$YELLOW" "$RESET"
    printf '%s\n' "$changed" | sed 's/^/  - /'
    printf "\n%s请在 commit message 中说明新增依赖的引入理由与替代方案。%s\n" "$YELLOW" "$RESET"
  fi

  print_ok "依赖检查完成"
}

# ----------------------------------------------------------------------
# 检查 5：按技术栈调用子脚本
# ----------------------------------------------------------------------
run_stack_specific_checks() {
  any=0

  if [ -f "$REPO_ROOT/go.mod" ] && [ -x "$HOOKS_DIR/pre-commit-go.sh" ]; then
    print_step "运行 Go 子脚本"
    sh "$HOOKS_DIR/pre-commit-go.sh" || fail "Go 检查失败"
    any=1
  fi

  if [ -f "$REPO_ROOT/package.json" ] && [ -x "$HOOKS_DIR/pre-commit-node.sh" ]; then
    print_step "运行 Node 子脚本"
    sh "$HOOKS_DIR/pre-commit-node.sh" || fail "Node 检查失败"
    any=1
  fi

  if { [ -f "$REPO_ROOT/requirements.txt" ] || [ -f "$REPO_ROOT/pyproject.toml" ]; } \
     && [ -x "$HOOKS_DIR/pre-commit-python.sh" ]; then
    print_step "运行 Python 子脚本"
    sh "$HOOKS_DIR/pre-commit-python.sh" || fail "Python 检查失败"
    any=1
  fi

  if [ "$any" = "0" ]; then
    printf "%s⚠ 未检测到 go.mod / package.json / requirements.txt，跳过技术栈检查%s\n" "$YELLOW" "$RESET"
  fi
}

# ----------------------------------------------------------------------
# 主流程
# ----------------------------------------------------------------------
main() {
  printf "%s═══ SOP v1 PreCommit 检查 ═══%s\n" "$GREEN" "$RESET"

  check_sensitive_files
  check_generated_artifacts
  check_test_modifications
  check_dependency_changes
  run_stack_specific_checks

  printf "\n%s═══ 全部检查通过 ═══%s\n" "$GREEN" "$RESET"
}

main
