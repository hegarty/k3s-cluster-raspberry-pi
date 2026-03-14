#!/usr/bin/env bash
set -euo pipefail

PROMPT_FILE="prompts/execute-plan.txt"

claude --dangerously-skip-permissions -p "$(cat prompts/execute-plan.txt)"
