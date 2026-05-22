#!/usr/bin/env bash
#
# Scaffold a new Poetry-managed Python project from this template.
#
# Usage:
#   ./new_project.sh <project_name> [--py 3.12] [--desc "..."] [--docker] [--frontend]
#
# Flags:
#   --py <ver>     Pin the Python interpreter (e.g. 3.12). Default: Poetry's choice.
#   --desc <text>  One-line project description (used in README/CLAUDE.md).
#   --docker       Include Dockerfile, .dockerignore, and the build-and-push workflow.
#   --frontend     Scaffold a Next.js frontend (frontend/) + its CI + scripts/run.sh.
#
# Copyable assets live under template/ (inert here so they don't run on the
# template repo itself). This script copies them into the new project.
#
# Prereqs: poetry, pre-commit, git (+ node/npm when --frontend is used).

set -euo pipefail

usage() {
  sed -n '4,13p' "$0" | sed 's/^# \{0,1\}//'
}

# ─── arg parsing ──────────────────────────────────────────────────────────────
PROJECT_NAME=""
PY_VERSION=""
DESCRIPTION=""
WITH_DOCKER=false
WITH_FRONTEND=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --py)       PY_VERSION="$2"; shift 2 ;;
    --desc)     DESCRIPTION="$2"; shift 2 ;;
    --docker)   WITH_DOCKER=true; shift ;;
    --frontend) WITH_FRONTEND=true; shift ;;
    -h|--help)  usage; exit 0 ;;
    *)
      if [[ -z "$PROJECT_NAME" ]]; then PROJECT_NAME="$1"; shift
      else echo "Error: unexpected arg '$1'"; exit 1; fi ;;
  esac
done

if [[ -z "$PROJECT_NAME" ]]; then
  echo "Error: project name required."
  usage
  exit 1
fi
[[ -z "$DESCRIPTION" ]] && DESCRIPTION="A ${PROJECT_NAME} project."

# ─── prereq checks ────────────────────────────────────────────────────────────
REQUIRED=(poetry pre-commit git)
if $WITH_FRONTEND; then
  REQUIRED+=(node npm)
fi
for cmd in "${REQUIRED[@]}"; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "Error: '$cmd' not found on PATH. Install it and re-run."
    exit 1
  fi
done

# Locate the template/ directory. The script's own dir is the default, but a
# copy may live elsewhere (e.g. mirrored to a repos root for convenience), so
# fall back to a project_template/ subdirectory.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [[ -d "${SCRIPT_DIR}/template" ]]; then
  TEMPLATE_DIR="${SCRIPT_DIR}/template"
elif [[ -d "${SCRIPT_DIR}/project_template/template" ]]; then
  TEMPLATE_DIR="${SCRIPT_DIR}/project_template/template"
else
  echo "Error: cannot locate the template/ directory (looked in ${SCRIPT_DIR}"
  echo "       and ${SCRIPT_DIR}/project_template). Run this script from inside"
  echo "       project_template/, or beside the project_template/ directory."
  exit 1
fi

TARGET_DIR="$(pwd)/${PROJECT_NAME}"
if [[ -e "$TARGET_DIR" ]]; then
  echo "Error: '$TARGET_DIR' already exists. Pick a different name or remove it."
  exit 1
fi

# ─── scaffold ─────────────────────────────────────────────────────────────────
echo "[1/7] Creating Poetry project '${PROJECT_NAME}'..."
poetry new "${PROJECT_NAME}"
cd "${PROJECT_NAME}"

# `poetry new` writes `requires-python` from whatever interpreter Poetry runs
# under — which may be newer than what you want, and would then *block*
# `poetry env use` from selecting an older interpreter. Pin a stable range up
# front so the template's intent wins, not the ambient Python.
echo "      Pinning requires-python to >=3.11,<3.14..."
sed 's/^requires-python = .*/requires-python = ">=3.11,<3.14"/' pyproject.toml \
  > pyproject.toml.tmp && mv pyproject.toml.tmp pyproject.toml

echo "[2/7] Configuring Poetry to use an in-project .venv..."
poetry config virtualenvs.create true --local
poetry config virtualenvs.in-project true --local

if [[ -n "$PY_VERSION" ]]; then
  echo "[3/7] Selecting Python ${PY_VERSION}..."
  poetry env use "python${PY_VERSION}"
else
  echo "[3/7] Using default Python (skip with --py to pin a version)."
fi

echo "[4/7] Copying template files..."
rm -f .gitignore README.md
mkdir -p .github/workflows .github/ISSUE_TEMPLATE tests

GH="${TEMPLATE_DIR}/github"

# Always: CI, release automation, config, docs, GitHub templates, smoke test.
cp "${GH}/workflows/run_tests.yml"          .github/workflows/
cp "${GH}/workflows/release_please.yml"     .github/workflows/
cp "${GH}/workflows/pr_title.yml"           .github/workflows/
cp "${GH}/ISSUE_TEMPLATE/"*.md              .github/ISSUE_TEMPLATE/
cp "${GH}/pull_request_template.md"         .github/
cp "${TEMPLATE_DIR}/gitignore"              .gitignore
cp "${TEMPLATE_DIR}/pre-commit-config.yaml" .pre-commit-config.yaml
cp "${TEMPLATE_DIR}/release-please-config.json"   release-please-config.json
cp "${TEMPLATE_DIR}/release-please-manifest.json" .release-please-manifest.json
cp "${TEMPLATE_DIR}/README.md.template"     README.md
cp "${TEMPLATE_DIR}/CLAUDE.md.template"     CLAUDE.md
cp "${TEMPLATE_DIR}/tests/test_smoke.py"    tests/test_smoke.py

# CHANGELOG.md is owned by release-please; ship a minimal stub for it to grow.
printf '# Changelog\n\nAll notable changes are recorded here automatically by release-please.\n' \
  > CHANGELOG.md

# Token-substitution targets, extended as optional pieces are added.
TARGETS=(
  "README.md"
  "CLAUDE.md"
  "tests/test_smoke.py"
)

if $WITH_DOCKER; then
  echo "      + Docker (Dockerfile, .dockerignore, build_and_push.yml)"
  cp "${TEMPLATE_DIR}/Dockerfile"             Dockerfile
  cp "${TEMPLATE_DIR}/dockerignore"           .dockerignore
  cp "${GH}/workflows/build_and_push.yml"     .github/workflows/
  TARGETS+=("Dockerfile" ".github/workflows/build_and_push.yml")
fi

if $WITH_FRONTEND; then
  echo "      + Next.js frontend (this runs create-next-app, may take a minute)"
  npx --yes create-next-app@latest frontend \
    --typescript --tailwind --eslint --app --no-src-dir \
    --import-alias "@/*" --use-npm --turbopack
  # create-next-app initializes its own git repo; drop it so the parent repo
  # tracks frontend/ as plain files instead of an embedded gitlink.
  rm -rf frontend/.git
  cp "${GH}/workflows/frontend_ci.yml"        .github/workflows/
  mkdir -p scripts
  cp "${TEMPLATE_DIR}/scripts/run.sh.template" scripts/run.sh
  chmod +x scripts/run.sh
  TARGETS+=("scripts/run.sh")
  cat >> .gitignore <<'EOF'

# Node / Next.js (frontend/)
node_modules/
.next/
.turbo/
next-env.d.ts
*.tsbuildinfo
EOF
fi

echo "[5/7] Substituting __PACKAGE_NAME__ / __DESCRIPTION__ tokens..."
PKG_IMPORT="${PROJECT_NAME//-/_}"
for f in "${TARGETS[@]}"; do
  [[ -f "$f" ]] || continue
  sed "s|__PACKAGE_NAME__|${PKG_IMPORT}|g; s|__DESCRIPTION__|${DESCRIPTION}|g" \
      "$f" > "$f.tmp" && mv "$f.tmp" "$f"
done

# Starter pyproject.toml config block for ruff/mypy/pytest.
cat >> pyproject.toml <<EOF

[tool.poetry.group.dev.dependencies]
pytest = "^8.3"
pytest-cov = "^5.0"
pytest-mock = "^3.14"
ruff = "^0.8"
mypy = "^1.13"
pre-commit = "^4.0"

[tool.ruff]
line-length = 100
target-version = "py311"

[tool.ruff.lint]
select = ["E", "F", "I", "W", "UP", "B", "SIM", "RUF"]

[tool.pytest.ini_options]
addopts = "-ra --strict-markers --cov=${PKG_IMPORT} --cov-report=term-missing"
testpaths = ["tests"]

[tool.mypy]
python_version = "3.11"
EOF

echo "[6/7] Running 'poetry install'..."
poetry install --no-interaction

echo "[7/7] Initializing git, installing pre-commit hooks, first commit..."
git init -q -b main
git add -A
git commit -q -m "Initial scaffold from project_template" || true
pre-commit install >/dev/null
if ! git diff --cached --quiet || ! git diff --quiet; then
  git add -A
  git commit -q -m "Apply pre-commit auto-fixes" || true
fi

DOCKER_LABEL=no
$WITH_DOCKER && DOCKER_LABEL=yes
FRONTEND_LABEL=no
$WITH_FRONTEND && FRONTEND_LABEL=yes

cat <<EOF

================================================================================
✓ '${PROJECT_NAME}' scaffolded at ${TARGET_DIR}
   docker:   ${DOCKER_LABEL}
   frontend: ${FRONTEND_LABEL}

Next steps:
  cd ${PROJECT_NAME}
  poetry run pytest
EOF
if $WITH_FRONTEND; then
  echo "  ./scripts/run.sh                              # frontend dev server"
fi
cat <<EOF
  gh repo create ${PROJECT_NAME} --private --source=. --remote=origin --push
================================================================================
EOF
