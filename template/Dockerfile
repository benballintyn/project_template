# Multi-stage build for a Poetry-managed Python project.
# Stage 1 installs deps into a venv; stage 2 copies just the venv + source.

ARG PYTHON_VERSION=3.12-slim
FROM python:${PYTHON_VERSION} AS builder

ENV POETRY_VERSION=1.8.5 \
    POETRY_HOME=/opt/poetry \
    POETRY_VIRTUALENVS_CREATE=true \
    POETRY_VIRTUALENVS_IN_PROJECT=true \
    POETRY_NO_INTERACTION=1 \
    PIP_NO_CACHE_DIR=1

RUN apt-get update && apt-get install -y --no-install-recommends curl build-essential \
    && rm -rf /var/lib/apt/lists/* \
    && curl -sSL https://install.python-poetry.org | python3 - \
    && ln -s /opt/poetry/bin/poetry /usr/local/bin/poetry

WORKDIR /app
COPY pyproject.toml poetry.lock ./
RUN poetry install --no-root --without dev

COPY src ./src
COPY README.md ./
RUN poetry install --without dev

# ---

FROM python:${PYTHON_VERSION} AS runtime
ENV PATH="/app/.venv/bin:$PATH" \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1
WORKDIR /app
COPY --from=builder /app/.venv ./.venv
COPY --from=builder /app/src ./src
# COPY scripts ./scripts  # uncomment if you have an entrypoint script

# Default to the package-script entrypoint defined in pyproject.toml.
# Override per service: e.g. CMD ["uvicorn", "myapp.web:app", "--host", "0.0.0.0"]
CMD ["python", "-m", "__PACKAGE_NAME__"]
