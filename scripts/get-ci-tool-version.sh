#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <tool-name>" >&2
  exit 64
fi

tool_name="$1"
requirements_file="${REQUIREMENTS_CI_FILE:-requirements-ci.txt}"

if [[ ! -f "$requirements_file" ]]; then
  echo "Requirements file not found: $requirements_file" >&2
  exit 1
fi

version=$(sed -n "s/^# ${tool_name}: //p" "$requirements_file")

if [[ -z "$version" ]]; then
  echo "Version for '${tool_name}' is missing from $requirements_file" >&2
  exit 1
fi

if [[ $(printf '%s\n' "$version" | wc -l) -ne 1 ]]; then
  echo "Multiple versions found for '${tool_name}' in $requirements_file" >&2
  exit 1
fi

printf '%s\n' "$version"
