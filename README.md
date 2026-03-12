English | [繁體中文](README.zh-TW.md)

# GitLab Sync Trigger

[![GitHub Action](https://img.shields.io/badge/GitHub-Action-blue?logo=github)](https://github.com/features/actions)
[![GitLab](https://img.shields.io/badge/GitLab-Integration-green?logo=gitlab)](https://gitlab.com)

Push code to GitLab, optionally trigger pipeline, and optionally wait for result.

## Features

- **Push Code to GitLab**: Synchronize local code changes to a specified GitLab branch using OAuth2 token authentication
- **Trigger GitLab Pipeline**: Optionally trigger a GitLab CI/CD pipeline with custom variables (SOURCE_REF, SOURCE_SHA, DEPLOY_ENV)
- **Wait for Pipeline Completion**: Optionally poll GitLab API to wait for pipeline completion and report final status

## Prerequisites

- **GitLab Push Token**: A GitLab personal access token or project access token with `write_repository` scope
- **GitLab Trigger Token**: A pipeline trigger token (required only if `trigger_pipeline: true`)
- **GitLab API Token**: A personal access token with `read_api` scope (required only if `wait_for_pipeline: true`)

> [!IMPORTANT]
> Store all tokens in GitHub Secrets and never commit them to your repository.

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `gitlab_push_host` | Yes | - | GitLab host (without protocol, e.g., `gitlab.example.com`) |
| `gitlab_project_path` | Yes | - | GitLab project path (e.g., `namespace/project-name`) |
| `gitlab_project_id` | Yes | - | GitLab numeric project ID |
| `gitlab_ref` | Yes | - | Target branch or ref in GitLab |
| `deploy_env` | No | `dev` | Deploy environment passed to GitLab pipeline as `DEPLOY_ENV` variable |
| `trigger_pipeline` | No | `true` | Whether to trigger GitLab pipeline (`true` or `false`) |
| `wait_for_pipeline` | No | `true` | Whether to wait for GitLab pipeline completion (`true` or `false`) |
| `poll_interval` | No | `10` | Poll interval in seconds when waiting for pipeline |
| `gitlab_push_token` | Yes | - | GitLab token with `write_repository` scope |
| `gitlab_trigger_token` | No | - | GitLab pipeline trigger token (required if `trigger_pipeline: true`) |
| `gitlab_api_token` | No | - | GitLab API token with `read_api` scope (required if `wait_for_pipeline: true`) |
| `git_remote_name` | No | `gitlab` | Git remote name for GitLab |
| `force_push` | No | `true` | Whether to force push to GitLab (`true` or `false`) |

## Outputs

| Output | Description |
|--------|-------------|
| `pipeline_id` | Triggered GitLab pipeline ID |
| `pipeline_status` | GitLab pipeline final status (`success`, `failed`, `canceled`, `skipped`, etc.) |
| `pipeline_web_url` | GitLab pipeline web URL |

## Usage

### Example 1: Minimal Usage (Push Only)

Push code to GitLab without triggering a pipeline:

```yaml
- name: Sync to GitLab
  uses: royfw/gitlab-sync-action@v1
  with:
    gitlab_push_host: gitlab.example.com
    gitlab_project_path: my-namespace/my-project
    gitlab_project_id: "12345"
    gitlab_ref: main
    gitlab_push_token: ${{ secrets.GITLAB_PUSH_TOKEN }}
    trigger_pipeline: false
    wait_for_pipeline: false
```

### Example 2: Full Usage (Push + Trigger + Wait)

Push code, trigger pipeline, and wait for completion:

```yaml
- name: Sync to GitLab and Wait
  uses: royfw/gitlab-sync-action@v1
  with:
    gitlab_push_host: gitlab.example.com
    gitlab_project_path: my-namespace/my-project
    gitlab_project_id: "12345"
    gitlab_ref: main
    deploy_env: production
    gitlab_push_token: ${{ secrets.GITLAB_PUSH_TOKEN }}
    gitlab_trigger_token: ${{ secrets.GITLAB_TRIGGER_TOKEN }}
    gitlab_api_token: ${{ secrets.GITLAB_API_TOKEN }}
    trigger_pipeline: true
    wait_for_pipeline: true
    poll_interval: 15
```

### Example 3: Full Workflow with Outputs

Use the action in a complete workflow and reference outputs:

```yaml
name: Deploy to GitLab

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Sync to GitLab
        id: sync
        uses: royfw/gitlab-sync-action@v1
        with:
          gitlab_push_host: gitlab.example.com
          gitlab_project_path: my-namespace/my-project
          gitlab_project_id: "12345"
          gitlab_ref: main
          deploy_env: production
          gitlab_push_token: ${{ secrets.GITLAB_PUSH_TOKEN }}
          gitlab_trigger_token: ${{ secrets.GITLAB_TRIGGER_TOKEN }}
          gitlab_api_token: ${{ secrets.GITLAB_API_TOKEN }}

      - name: Display Pipeline Info
        run: |
          echo "Pipeline ID: ${{ steps.sync.outputs.pipeline_id }}"
          echo "Pipeline Status: ${{ steps.sync.outputs.pipeline_status }}"
          echo "Pipeline URL: ${{ steps.sync.outputs.pipeline_web_url }}"

      - name: Deploy if Pipeline Succeeded
        if: steps.sync.outputs.pipeline_status == 'success'
        run: |
          echo "Pipeline succeeded! Proceeding with deployment..."
```

## Security

- Store all GitLab tokens in **GitHub Secrets**:
  - `GITLAB_PUSH_TOKEN` - for pushing code
  - `GITLAB_TRIGGER_TOKEN` - for triggering pipelines
  - `GITLAB_API_TOKEN` - for reading pipeline status
- Never commit tokens to your repository
- Use repository secrets with appropriate access restrictions
- Consider using environment-specific secrets for production deployments
