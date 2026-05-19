#!/usr/bin/env sh
# .githooks/pre-commit-go.sh
# Go 项目专用检查：gofmt / goimports / golangci-lint / go build / go test（仅快速单测）

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

# 仅检查暂存的 .go 文件
staged_go=$(git diff --cached --name-only --diff-filter=ACMR | grep -E '\.go$' || true)

# ---------------- gofmt ----------------
step "gofmt"
if [ -n "$staged_go" ]; then
  unformatted=""
  for f in $staged_go; do
    [ -f "$f" ] || continue
    diff_out=$(gofmt -l "$f" 2>/dev/null || true)
    [ -n "$diff_out" ] && unformatted="$unformatted $f"
  done
  if [ -n "$unformatted" ]; then
    printf "%s未格式化的 Go 文件:%s\n" "$RED" "$RESET"
    for f in $unformatted; do printf "      %s\n" "$f"; done
    printf "      请执行: gofmt -w %s\n" "$unformatted"
    fail "gofmt 未通过"
  fi
fi
ok "gofmt 通过"

# ---------------- goimports（可选） ----------------
if command -v goimports >/dev/null 2>&1 && [ -n "$staged_go" ]; then
  step "goimports"
  unimported=""
  for f in $staged_go; do
    [ -f "$f" ] || continue
    diff_out=$(goimports -l "$f" 2>/dev/null || true)
    [ -n "$diff_out" ] && unimported="$unimported $f"
  done
  if [ -n "$unimported" ]; then
    printf "%s import 未规范化:%s\n" "$RED" "$RESET"
    for f in $unimported; do printf "      %s\n" "$f"; done
    fail "goimports 未通过"
  fi
  ok "goimports 通过"
fi

# ---------------- golangci-lint ----------------
if command -v golangci-lint >/dev/null 2>&1; then
  step "golangci-lint（仅暂存文件）"
  if [ -n "$staged_go" ]; then
    if ! golangci-lint run --new-from-rev=HEAD --timeout=2m $staged_go 2>&1; then
      fail "golangci-lint 未通过"
    fi
  fi
  ok "golangci-lint 通过"
else
  printf "%s    ⚠ 未安装 golangci-lint，跳过%s\n" "$YELLOW" "$RESET"
fi

# ---------------- go build ----------------
step "go build ./..."
if ! go build ./... 2>&1; then
  fail "go build 未通过"
fi
ok "go build 通过"

# ---------------- go test（仅短测试） ----------------
step "go test -short ./..."
if ! go test -short -timeout=60s ./... 2>&1; then
  fail "go test 未通过"
fi
ok "go test 通过"
