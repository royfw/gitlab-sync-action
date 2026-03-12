#!/usr/bin/env bash
set -euo pipefail

: "${GITLAB_PUSH_HOST:?GITLAB_PUSH_HOST is required}"
: "${GITLAB_PROJECT_PATH:?GITLAB_PROJECT_PATH is required}"
: "${GITLAB_REF:?GITLAB_REF is required}"
: "${GITLAB_PUSH_TOKEN:?GITLAB_PUSH_TOKEN is required}"

GIT_REMOTE_NAME="${GIT_REMOTE_NAME:-gitlab}"
FORCE_PUSH="${FORCE_PUSH:-true}"

REMOTE_URL="https://oauth2:${GITLAB_PUSH_TOKEN}@${GITLAB_PUSH_HOST}/${GITLAB_PROJECT_PATH}.git"

if git remote get-url "${GIT_REMOTE_NAME}" >/dev/null 2>&1; then
  git remote set-url "${GIT_REMOTE_NAME}" "${REMOTE_URL}"
else
  git remote add "${GIT_REMOTE_NAME}" "${REMOTE_URL}"
fi

echo "Pushing HEAD to GitLab ref: ${GITLAB_REF}"

# Unshallow the repository if it's a shallow clone
if git rev-parse --is-shallow-repository 2>/dev/null | grep -q "true"; then
  echo "Detected shallow clone, unshallowing..."
  git fetch --unshallow
fi

PUSH_ARGS=(-o ci.skip "${GIT_REMOTE_NAME}" "HEAD:${GITLAB_REF}")

if [[ "${FORCE_PUSH}" == "true" ]]; then
  git push --force "${PUSH_ARGS[@]}"
else
  git push "${PUSH_ARGS[@]}"
fi