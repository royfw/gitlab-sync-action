#!/usr/bin/env bash
set -euo pipefail

: "${GITLAB_PUSH_HOST:?GITLAB_PUSH_HOST is required}"
: "${GITLAB_PROJECT_ID:?GITLAB_PROJECT_ID is required}"
: "${GITLAB_REF:?GITLAB_REF is required}"
: "${GITLAB_TRIGGER_TOKEN:?GITLAB_TRIGGER_TOKEN is required}"
: "${DEPLOY_ENV:?DEPLOY_ENV is required}"
: "${SOURCE_REF:?SOURCE_REF is required}"
: "${SOURCE_SHA:?SOURCE_SHA is required}"
: "${TRIGGER_SOURCE:?TRIGGER_SOURCE is required}"
: "${GITHUB_OUTPUT:?GITHUB_OUTPUT is required}"

TRIGGER_URL="https://${GITLAB_PUSH_HOST}/api/v4/projects/${GITLAB_PROJECT_ID}/trigger/pipeline"

echo "Triggering GitLab pipeline:"
echo "  URL: ${TRIGGER_URL}"
echo "  ref: ${GITLAB_REF}"
echo "  DEPLOY_ENV: ${DEPLOY_ENV}"
echo "  SOURCE_REF: ${SOURCE_REF}"
echo "  SOURCE_SHA: ${SOURCE_SHA}"

RESPONSE="$(
  curl --silent --show-error --fail --request POST \
    --form "token=${GITLAB_TRIGGER_TOKEN}" \
    --form "ref=${GITLAB_REF}" \
    --form "variables[SOURCE_REF]=${SOURCE_REF}" \
    --form "variables[SOURCE_SHA]=${SOURCE_SHA}" \
    --form "variables[DEPLOY_ENV]=${DEPLOY_ENV}" \
    --form "variables[TRIGGER_SOURCE]=${TRIGGER_SOURCE}" \
    "${TRIGGER_URL}"
)"

echo "${RESPONSE}"

PIPELINE_ID="$(echo "${RESPONSE}" | jq -r '.id')"
PIPELINE_STATUS="$(echo "${RESPONSE}" | jq -r '.status // empty')"
PIPELINE_WEB_URL="$(echo "${RESPONSE}" | jq -r '.web_url // empty')"

if [[ -z "${PIPELINE_ID}" || "${PIPELINE_ID}" == "null" ]]; then
  echo "Failed to parse pipeline_id from GitLab trigger response" >&2
  exit 1
fi

echo "Triggered GitLab pipeline ID: ${PIPELINE_ID}"
[[ -n "${PIPELINE_STATUS}" ]] && echo "Initial pipeline status: ${PIPELINE_STATUS}"
[[ -n "${PIPELINE_WEB_URL}" ]] && echo "Pipeline URL: ${PIPELINE_WEB_URL}"

{
  echo "pipeline_id=${PIPELINE_ID}"
  echo "pipeline_status=${PIPELINE_STATUS}"
  echo "pipeline_web_url=${PIPELINE_WEB_URL}"
} >> "${GITHUB_OUTPUT}"