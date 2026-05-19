#!/usr/bin/env sh
# .githooks/pre-commit-node.sh
# Node / TypeScript 项目专用检查：prettier / eslint / build / test
#
# 自动检测 npm / yarn / pnpm 包管理器。

set -eu

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

YELLOW=$(printf '\033[0;33m')
GREEN=$(printf '\033[0;32m')
RED=$(printf '\033[0;31m')
RESET=$(printf '\033[0m')

step() { printf "%s  → %s%s\n" "$YELLOW" "$1" "$RESET"; }
ok()   { printf "%s    ✓ %s%s\n" "$GREEN"  "$1" "$RESET"; }
fail() { printf "%s    ✗ %s%s\n" "$RED"    "$1" "$RESET"; exit 1; }

# 检测包管理器
if [ -f "pnpm-lock.yaml" ]; then
  PM="pnpm"
elif [ -f "yarn.lock" ]; then
  PM="yarn"
else
  PM="npm"
fi
RUN="$PM run"
[ "$PM" = "npm" ] && RUN="npm run"

printf "%s    使用包管理器: %s%s\n" "$YELLOW" "$PM" "$RESET"

# 暂存的 JS/TS 文件
staged_js=$(git diff --cached --name-only --diff-filter=ACMR | grep -E '\.([cm]?[jt]sx?)$' || true)

# ---------------- prettier ----------------
if [ -f "node_modules/.bin/prettier" ] || [ -f ".prettierrc" ] || [ -f ".prettierrc.json" ] || [ -f "prettier.config.js" ]; then
  step "prettier --check"
  if [ -n "$staged_js" ]; then
    if ! npx --no-install prettier --check $staged_js 2>&1; then
      printf "      %s请执行: npx prettier --write <文件>%s\n" "$RED" "$RESET"
      fail "prettier 未通过"
    fi
  fi
  ok "prettier 通过"
else
  printf "%s    ⚠ 未配置 prettier，跳过%s\n" "$YELLOW" "$RESET"
fi

# ---------------- eslint ----------------
if [ -f "node_modules/.bin/eslint" ] || [ -f ".eslintrc" ] || [ -f ".eslintrc.json" ] || [ -f ".eslintrc.js" ] || [ -f "eslint.config.js" ] || [ -f "eslint.config.mjs" ]; then
  step "eslint"
  if [ -n "$staged_js" ]; then
    if ! npx --no-install eslint $staged_js 2>&1; then
      fail "eslint 未通过"
    fi
  fi
  ok "eslint 通过"
else
  printf "%s    ⚠ 未配置 eslint，跳过%s\n" "$YELLOW" "$RESET"
fi

# ---------------- 类型检查（TypeScript） ----------------
if [ -f "tsconfig.json" ]; then
  step "tsc --noEmit"
  if ! npx --no-install tsc --noEmit 2>&1; then
    fail "TypeScript 类型检查未通过"
  fi
  ok "tsc 通过"
fi

# ---------------- build ----------------
if grep -q '"build"' package.json 2>/dev/null; then
  step "$RUN build"
  if ! $RUN build 2>&1; then
    fail "build 未通过"
  fi
  ok "build 通过"
else
  printf "%s    ⚠ package.json 无 build 脚本，跳过%s\n" "$YELLOW" "$RESET"
fi

# ---------------- test ----------------
if grep -q '"test"' package.json 2>/dev/null; then
  step "$RUN test（仅快速测试）"
  # 优先尝试 test:ci / test:quick / test:unit，回退到 test
  if grep -q '"test:quick"' package.json 2>/dev/null; then
    $RUN test:quick 2>&1 || fail "test:quick 未通过"
  elif grep -q '"test:unit"' package.json 2>/dev/null; then
    $RUN test:unit 2>&1 || fail "test:unit 未通过"
  else
    $RUN test 2>&1 || fail "test 未通过"
  fi
  ok "test 通过"
else
  printf "%s    ⚠ package.json 无 test 脚本，跳过%s\n" "$YELLOW" "$RESET"
fi
