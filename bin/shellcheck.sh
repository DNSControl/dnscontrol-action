#!/usr/bin/env bash

set -eo pipefail

# This script checks all project shell scripts for common errors and style
# issues. It extracts each bash run step from action.yml and all workflows and
# runs them through shellcheck for safety. requires yq and shellcheck in $PATH

# Run locally with: [bash|zsh] bin/shellcheck.sh

FAILS=0
IFS="
"

# Create an array of YAML files (recent bash and zsh supported here)
if [[ -n "$BASH_VERSION" ]]; then
  scripts=()
  while read -r script; do
      scripts+=("$script")
  done < <(find action.yml .github/workflows bin -type f -name \*sh -print -o -name \*yml -print -o -name \*yaml -print)
else
  if [[ -n "$ZSH_VERSION" ]]; then
    # shellcheck disable=SC2296
    scripts=("${(@f)$(find action.yml .github/workflows bin -type f -name \*sh -print -o -name \*yml -print -o -name \*yaml -print)}")
  else
    echo "This script requires a recent bash or zsh shell"
    exit 1
  fi
fi

errors=""

for script in "${scripts[@]}"; do

  echo "Checking $script"

  if [[ "${script##*.}" == "sh" ]]; then
    set +e
    if ! shellcheck --shell bash -S warning "$script"; then
      errors="$errors\n$script did not pass shellcheck"
      ((FAILS++))
    fi
    set -e
  fi

  if [[ "${script##*.}" == "yml" ]] || [[ "${script#*.}" == "yaml" ]]; then
    # find bash run steps in workflow jobs.*.steps[] and action runs.steps[]
    for n in $(yq '.. | select(has("steps")) | .steps[] | select(.shell == "bash") | .name' < "$script")
    do
      # do not error out while in this inner loop: we want to find all problems
      set +e

      # prepare a safe location to create a temporary script for evaluation
      tmpscript=$(mktemp)

      # extract the *.steps[].run elements into the temp file
      yq ".. | select(has(\"steps\")) | .steps[] | select(.name == \"$n\") | .run" < "$script" > "$tmpscript"

      # run the checks
      if ! shellcheck --shell bash -S warning "$tmpscript"; then
        errors="$errors\n$script step \"$n\" did not pass shellcheck"
        ((FAILS++))
      fi
      rm "$tmpscript"
      set -e
    done
  fi
done

if [[ $FAILS -ne 0 ]]; then
  echo "$FAILS error(s) or warning(s) detected, please fix and run bin/shellcheck.sh again"
  echo "issues:$errors"
  exit 1
fi