#!/usr/bin/env sh
# .githooks/pre-commit-python.sh
# Python 项目专用检查：ruff / mypy / pytest

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

# 暂存的 Python 文件
staged_py=$(git diff --cached --name-only --diff-filter=ACMR | grep -E '\.py$' || true)

# ---------------- ruff format ----------------
if command -v ruff >/dev/null 2>&1; then
  step "ruff format --check"
  if [ -n "$staged_py" ]; then
    if ! ruff format --check $staged_py 2>&1; then
      printf "      %s请执行: ruff format <文件>%s\n" "$RED" "$RESET"
      fail "ruff format 未通过"
    fi
  fi
  ok "ruff format 通过"

  # ---------------- ruff check ----------------
  step "ruff check"
  if [ -n "$staged_py" ]; then
    if ! ruff check $staged_py 2>&1; then
      fail "ruff check 未通过"
    fi
  fi
  ok "ruff check 通过"
else
  printf "%s    ⚠ 未安装 ruff，跳过 lint/format（建议 pip install ruff）%s\n" "$YELLOW" "$RESET"
fi

# ---------------- mypy（可选） ----------------
if command -v mypy >/dev/null 2>&1 && { [ -f "mypy.ini" ] || grep -q '\[tool.mypy\]' pyproject.toml 2>/dev/null; }; then
  step "mypy"
  if [ -n "$staged_py" ]; then
    if ! mypy $staged_py 2>&1; then
      fail "mypy 类型检查未通过"
    fi
  fi
  ok "mypy 通过"
fi

# ---------------- pytest ----------------
if command -v pytest >/dev/null 2>&1; then
  step "pytest（仅快速测试，标记 -m \"not slow\"）"
  # 优先尝试 quick / unit / smoke 标记，回退到默认
  if pytest --collect-only -q -m "quick" 2>/dev/null | grep -q "test"; then
    pytest -m "quick" --tb=short 2>&1 || fail "pytest quick 未通过"
  elif pytest --collect-only -q -m "unit" 2>/dev/null | grep -q "test"; then
    pytest -m "unit" --tb=short 2>&1 || fail "pytest unit 未通过"
  else
    pytest -m "not slow" --tb=short --timeout=60 2>&1 || fail "pytest 未通过"
  fi
  ok "pytest 通过"
else
  printf "%s    ⚠ 未安装 pytest，跳过测试%s\n" "$YELLOW" "$RESET"
fi
