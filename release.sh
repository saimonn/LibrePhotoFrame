#!/usr/bin/env bash
set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

cd "$(dirname "$0")"

# Check git
if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo -e "${RED}Error: Not a git repository${NC}"
  exit 1
fi

# Check uncommitted
if ! git diff-index --quiet HEAD --; then
  echo -e "${RED}Error: Uncommitted changes. Commit or stash first.${NC}"
  git status --short
  exit 1
fi

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

# Get current version
CURRENT_VERSION_FULL=$(grep '^version:' pubspec.yaml | sed 's/version: //' | tr -d ' ')
CURRENT_VERSION=$(echo "$CURRENT_VERSION_FULL" | sed 's/+.*//')
CURRENT_BUILD=$(echo "$CURRENT_VERSION_FULL" | grep '+' | sed 's/.*+//' || echo "0")

echo -e "${BLUE}Current: ${CURRENT_VERSION_FULL} on ${CURRENT_BRANCH}${NC}"

# New version input
if [ $# -eq 1 ]; then
  NEW_VERSION_INPUT="$1"
else
  echo -e "${YELLOW}New version (X.Y.Z, empty to auto-patch):${NC}"
  read -r -p "" NEW_VERSION_INPUT
fi

if [ -z "$NEW_VERSION_INPUT" ]; then
  IFS='.' read -r -a parts <<< "$CURRENT_VERSION"
  MAJOR="${parts[0]:-0}"
  MINOR="${parts[1]:-0}"
  PATCH="${parts[2]:-0}"
  NEW_VERSION="${MAJOR}.${MINOR}.$((PATCH+1))"
  echo -e "${GREEN}Auto-increment -> ${NEW_VERSION}${NC}"
else
  NEW_VERSION=$(echo "$NEW_VERSION_INPUT" | sed 's/^v//')
fi

if ! echo "$NEW_VERSION" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.-]+)?$'; then
  echo -e "${RED}Invalid version format${NC}"
  exit 1
fi

NEW_BUILD=$((CURRENT_BUILD + 1))
NEW_VERSION_FULL="${NEW_VERSION}+${NEW_BUILD}"

if git tag -l | grep -q "^v${NEW_VERSION}$"; then
  echo -e "${RED}Tag v${NEW_VERSION} already exists${NC}"
  exit 1
fi

echo ""
echo -e "${YELLOW}Will update pubspec to ${NEW_VERSION_FULL}, commit, tag v${NEW_VERSION}, push${NC}"
echo -e "${YELLOW}Continue? (y/N)${NC}"
read -r confirm
[[ "$confirm" =~ ^[Yy]$ ]] || { echo -e "${RED}Aborted${NC}"; exit 1; }

echo -e "${BLUE}[1/5] Update pubspec${NC}"
sed -i "s/^version: .*/version: ${NEW_VERSION_FULL}/" pubspec.yaml
echo -e "${GREEN}OK${NC}"

echo -e "${BLUE}[2/5] Tests${NC}"
if command -v flutter >/dev/null 2>&1; then
  flutter test >/tmp/release_flutter_test.log 2>&1 || { echo -e "${RED}Tests failed (see /tmp/release_flutter_test.log)${NC}"; exit 1; }
  echo -e "${GREEN}All tests passed${NC}"
else
  echo -e "${YELLOW}Flutter not in PATH - skipping tests${NC}"
fi

echo -e "${BLUE}[3/5] Commit${NC}"
git add pubspec.yaml
git commit -m "chore: bump version to ${NEW_VERSION_FULL}"
echo -e "${GREEN}OK${NC}"

echo -e "${BLUE}[4/5] Tag${NC}"
git tag "v${NEW_VERSION}"
echo -e "${GREEN}OK${NC}"

echo -e "${BLUE}[5/5] Push${NC}"
git push origin "$CURRENT_BRANCH"
git push origin "v${NEW_VERSION}"
echo -e "${GREEN}OK${NC}"

echo ""
echo -e "${GREEN}Release v${NEW_VERSION} initiated${NC}"
echo -e "${BLUE}CI will build APKs and create GitHub release${NC}"
