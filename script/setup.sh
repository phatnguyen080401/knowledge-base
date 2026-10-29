#!/usr/bin/env bash
# Link .skill/ into one coding agent's skills folder so the skills become slash commands.
# Usage: script/setup.sh CLAUDE|GEMINI|COPILOT
set -euo pipefail

usage() { echo "Usage: $0 CLAUDE|GEMINI|COPILOT" >&2; exit 1; }
[ $# -eq 1 ] || usage

case "$(printf '%s' "$1" | tr '[:lower:]' '[:upper:]')" in
  CLAUDE)  dir=.claude ;;
  GEMINI)  dir=.gemini ;;
  COPILOT) dir=.copilot ;;
  *)       usage ;;
esac

cd "$(dirname "$0")/.."
link="$dir/skills"

if [ -L "$link" ] && [ "$(readlink "$link")" = "../.skill" ]; then
  echo "Already linked: $link -> ../.skill"
  exit 0
fi
if [ -e "$link" ] || [ -L "$link" ]; then
  echo "Refusing to overwrite existing $link; remove it first." >&2
  exit 1
fi

mkdir -p "$dir"
ln -s ../.skill "$link"
echo "Linked $link -> ../.skill"
