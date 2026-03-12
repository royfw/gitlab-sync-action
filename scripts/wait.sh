#!/usr/bin/env bash
set -euo pipefail

: "${GITLAB_PUSH_HOST:?GITLAB_PUSH_HOST is required}"
: "${GITLAB_PROJECT_ID:?GITLAB_PROJECT_ID is required}"
: "${GITLAB_API_TOKEN:?GITLAB_API_TOKEN is required}"
: "${PIPELINE_ID:?PIPELINE_ID is required}"

POLL_INTERVAL="${POLL_INTERVAL:-10}"
MAX_POLL_ATTEMPTS="${MAX_POLL_ATTEMPTS:-60}"
PIPELINE_URL="https://${GITLAB_PUSH_HOST}/api/v4/projects/${GITLAB_PROJECT_ID}/pipelines/${PIPELINE_ID}"

echo "Waiting for GitLab pipeline: ${PIPELINE_ID}"
echo "Polling URL: ${PIPELINE_URL}"
echo "Poll interval: ${POLL_INTERVAL}s"
echo "Max poll attempts: ${MAX_POLL_ATTEMPTS}"

ATTEMPT=0

while true; do
  ATTEMPT=$((ATTEMPT + 1))
  
  if [[ ${ATTEMPT} -gt ${MAX_POLL_ATTEMPTS} ]]; then
    echo "Error: Max poll attempts (${MAX_POLL_ATTEMPTS}) exceeded" >&2
    exit 1
  fi
  
  RESPONSE="$(
    curl --silent --show-error --fail \
      --header "PRIVATE-TOKEN: ${GITLAB_API_TOKEN}" \
      "${PIPELINE_URL}"
  )"

  STATUS="$(echo "${RESPONSE}" | jq -r '.status')"
  WEB_URL="$(echo "${RESPONSE}" | jq -r '.web_url // empty')"

  echo "Pipeline status: ${STATUS}"
  [[ -n "${WEB_URL}" ]] && echo "Pipeline web URL: ${WEB_URL}"

  case "${STATUS}" in
    success)
      echo "GitLab pipeline succeeded"
      exit 0
      ;;
    failed|canceled|skipped)
      echo "GitLab pipeline finished unsuccessfully: ${STATUS}" >&2
      exit 1
      ;;
    created|waiting_for_resource|preparing|pending|running|scheduled|manual)
      sleep "${POLL_INTERVAL}"
      ;;
    *)
      echo "Unknown pipeline status: ${STATUS}" >&2
      sleep "${POLL_INTERVAL}"
      ;;
  esac
done