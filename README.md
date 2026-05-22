# project_template

Scaffolding for new Poetry-managed Python projects. `new_project.sh` stamps out
a fresh repo with CI, pre-commit, and optional Docker / Next.js pieces.

## Usage

```bash
./new_project.sh <project_name> [--py 3.12] [--desc "..."] [--docker] [--frontend]
```

| Flag | Effect |
|---|---|
| `--py <ver>` | Pin the Python interpreter (e.g. `3.12`). Default: Poetry's choice. |
| `--desc <text>` | One-line description, substituted into README and CLAUDE.md. |
| `--docker` | Add `Dockerfile`, `.dockerignore`, and the build-and-push workflow. |
| `--frontend` | Scaffold a Next.js app under `frontend/`, its CI, and `scripts/run.sh`. |

Run it from the directory where the new project folder should be created
(typically `~/personal/repos/`). A copy of the script also lives there for
convenience.

## What every project gets

- **Poetry** with an in-project `.venv` (no conda).
- **CI** (`run_tests.yml`): ruff lint + format check, mypy, pytest with coverage,
  across Python 3.11–3.13.
- **Automated releases** (`release_please.yml`): release-please maintains a
  standing release PR; merging it bumps the version, updates `CHANGELOG.md`,
  tags `vX.Y.Z`, and publishes a GitHub Release.
- **PR title lint** (`pr_title.yml`): enforces Conventional Commits on PR titles.
- **pre-commit**: ruff (lint + format), mypy, detect-secrets, standard hygiene hooks.
- **GitHub templates**: bug / feature issue templates, PR template.
- **`CLAUDE.md`** stub for project-specific Claude Code guidance.
- A starter `[tool.ruff]` / `[tool.mypy]` / `[tool.pytest]` block in `pyproject.toml`.

## Release flow (release-please)

Releases are driven by [release-please](https://github.com/googleapis/release-please),
not manual tags. The flow:

1. PRs are **squash-merged**; the **PR title must be a Conventional Commit**
   (`feat:` → minor, `fix:` → patch, `feat!:` / `BREAKING CHANGE:` → major).
   `pr_title.yml` fails the PR if the title doesn't conform.
2. release-please watches `main` and keeps an open **release PR** that bumps
   the version in `pyproject.toml` and updates `CHANGELOG.md`.
3. Merge the release PR when you want to ship — it tags `vX.Y.Z` and cuts the
   GitHub Release. (`build_and_push.yml`, if `--docker` was used, fires on that tag.)

**One-time setup per repo:** Settings → Actions → General → Workflow permissions
→ enable *"Allow GitHub Actions to create and approve pull requests"*, and set
the repo to **squash-merge only** under Settings → Pull Requests.

State lives in `release-please-config.json` (release type) and
`.release-please-manifest.json` (current version).

## Maintaining the template

The pinned hook/action versions drift over time. Periodically bump:

- `.pre-commit-config.yaml` — ruff, mypy, detect-secrets revs
- `.github/workflows/*.yml` — action versions (`actions/*`, `docker/*`,
  `googleapis/release-please-action`, `amannn/action-semantic-pull-request`)
