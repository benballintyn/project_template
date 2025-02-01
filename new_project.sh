#!/usr/bin/env bash
#
# Usage: ./init_project.sh <project_name>
#
# 1. Create conda environment named <project_name> with Python 3.11.
# 2. Create new Poetry project <project_name>.
# 3. Initialize a Git repository.
# 4. Copy:
#      - .github/workflows from project_template
#      - .gitignore from project_template
#      - .pre-commit-config.yaml from project_template
# 5. Check if pre-commit is installed; if not, exit with an error. If yes, install the hooks.
#
# Prerequisites:
#   - Conda installed and available on PATH
#   - Poetry installed
#   - pre-commit installed
#   - A sibling directory named 'project_template' containing:
#       .github/workflows/
#       .gitignore
#       .pre-commit-config.yaml

set -e  # Exit immediately if any command fails

# Check usage
if [ -z "$1" ]; then
  echo "Error: No project name provided."
  echo "Usage: $0 <project_name>"
  exit 1
fi

PROJECT_NAME="$1"

# Check for conda
if ! command -v conda &> /dev/null; then
  echo "Error: conda not found. Please install it or ensure it's on your PATH."
  exit 1
fi

echo "Creating conda environment '$PROJECT_NAME' with Python 3.11..."
conda create -y -n "$PROJECT_NAME" python=3.11

echo "Activating conda environment '$PROJECT_NAME'..."
# Adjust this path if your conda installation is elsewhere
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate "$PROJECT_NAME"

echo "Creating a new Poetry project: $PROJECT_NAME"
poetry new "$PROJECT_NAME"

cd "$PROJECT_NAME"

# Remove the default .gitignore created by Poetry (if you want to replace it fully)
if [ -f ".gitignore" ]; then
  rm .gitignore
fi

echo "Initializing a Git repository..."
git init

echo "Adding project files to Git..."
git add .

echo "Committing the initial Poetry scaffold..."
git commit -m "Initial commit (Poetry scaffold)"

echo "Copying GitHub Actions workflows from project_template..."
mkdir -p .github/workflows
cp ../project_template/.github/workflows/* .github/workflows/

echo "Copying .gitignore from project_template..."
cp ../project_template/.gitignore .gitignore

echo "Copying .pre-commit-config.yaml from project_template..."
cp ../project_template/.pre-commit-config.yaml .pre-commit-config.yaml

echo "Adding new project files to Git..."
git add .github/workflows .gitignore .pre-commit-config.yaml
git commit -m "Add GitHub Actions workflows, .gitignore, and pre-commit config"

# Check if pre-commit is installed
if ! command -v pre-commit &> /dev/null; then
  echo "Error: pre-commit not found. Please install it and run this script again."
  echo "Exiting..."
  exit 1
fi

echo "Setting up pre-commit..."
pre-commit install

echo
echo "=================================================="
echo "Project '$PROJECT_NAME' setup complete!"
echo "Conda environment '$PROJECT_NAME' is active."
echo "Next steps:"
echo "1. Review .gitignore and .pre-commit-config.yaml as needed."
echo "2. Start developing in the $PROJECT_NAME folder."
echo "3. If you installed pre-commit just now, it is set up and ready to run."
echo "=================================================="
