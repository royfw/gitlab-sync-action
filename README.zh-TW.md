[English](README.md) | 繁體中文

# GitLab 同步觸發器

[![GitHub Action](https://img.shields.io/badge/GitHub-Action-blue?logo=github)](https://github.com/features/actions)
[![GitLab](https://img.shields.io/badge/GitLab-Integration-green?logo=gitlab)](https://gitlab.com)

將程式碼推送到 GitLab，可選擇觸發 Pipeline，並可選擇等待結果。

## 功能特點

- **推送程式碼到 GitLab**：使用 OAuth2 Token 認證將本地程式碼變更同步到指定的 GitLab 分支
- **觸發 GitLab Pipeline**：可選擇使用自訂變數（SOURCE_REF、SOURCE_SHA、DEPLOY_ENV）觸發 GitLab CI/CD Pipeline
- **等待 Pipeline 完成**：可選擇輪詢 GitLab API 以等待 Pipeline 完成並回報最終狀態

## 使用需求

- **GitLab 推送 Token**：具有 `write_repository` 權限範圍的 GitLab 個人存取 Token 或專案存取 Token
- **GitLab 觸發 Token**：Pipeline 觸發 Token（僅當 `trigger_pipeline: true` 時需要）
- **GitLab API Token**：具有 `read_api` 權限範圍的個人存取 Token（僅當 `wait_for_pipeline: true` 時需要）

> [!IMPORTANT]
> 將所有 Token 儲存在 GitHub Secrets 中，切勿將其提交到您的儲存庫。

## 輸入參數

| 輸入參數 | 必填 | 預設值 | 說明 |
|----------|------|--------|------|
| `gitlab_push_host` | 是 | - | GitLab 主機位址（不含協定，例如：`gitlab.example.com`） |
| `gitlab_project_path` | 是 | - | GitLab 專案路徑（例如：`namespace/project-name`） |
| `gitlab_project_id` | 是 | - | GitLab 數值專案 ID |
| `gitlab_ref` | 是 | - | GitLab 目標分支或 Ref |
| `deploy_env` | 否 | `dev` | 傳遞給 GitLab Pipeline 的部署環境變數 `DEPLOY_ENV` |
| `trigger_pipeline` | 否 | `true` | 是否觸發 GitLab Pipeline（`true` 或 `false`） |
| `wait_for_pipeline` | 否 | `true` | 是否等待 GitLab Pipeline 完成（`true` 或 `false`） |
| `poll_interval` | 否 | `10` | 等待 Pipeline 時的輪詢間隔（秒） |
| `gitlab_push_token` | 是 | - | 具有 `write_repository` 權限範圍的 GitLab Token |
| `gitlab_trigger_token` | 否 | - | GitLab Pipeline 觸發 Token（當 `trigger_pipeline: true` 時需要） |
| `gitlab_api_token` | 否 | - | 具有 `read_api` 權限範圍的 GitLab API Token（當 `wait_for_pipeline: true` 時需要） |
| `git_remote_name` | 否 | `gitlab` | GitLab 的 Git Remote 名稱 |
| `force_push` | 否 | `true` | 是否強制推送到 GitLab（`true` 或 `false`） |

## 輸出

| 輸出參數 | 說明 |
|----------|------|
| `pipeline_id` | 觸發的 GitLab Pipeline ID |
| `pipeline_status` | GitLab Pipeline 最終狀態（`success`、`failed`、`canceled`、`skipped` 等） |
| `pipeline_web_url` | GitLab Pipeline 網頁網址 |

## 使用範例

### 範例 1：最小使用方式（僅推送）

僅推送程式碼到 GitLab，不觸發 Pipeline：

```yaml
- name: Sync to GitLab
  uses: royfw/gitlab-sync-action@v1
  with:
    gitlab_push_host: gitlab.example.com
    gitlab_project_path: my-namespace/my-project
    gitlab_project_id: "12345"
    gitlab_ref: ${{ github.ref_name }}
    gitlab_push_token: ${{ secrets.GITLAB_PUSH_TOKEN }}
    trigger_pipeline: false
    wait_for_pipeline: false
```

### 範例 2：完整使用方式（推送 + 觸發 + 等待）

推送程式碼、觸發 Pipeline 並等待完成：

```yaml
- name: Sync to GitLab and Wait
  uses: royfw/gitlab-sync-action@v1
  with:
    gitlab_push_host: gitlab.example.com
    gitlab_project_path: my-namespace/my-project
    gitlab_project_id: "12345"
    gitlab_ref: ${{ github.ref_name }}
    deploy_env: production
    gitlab_push_token: ${{ secrets.GITLAB_PUSH_TOKEN }}
    gitlab_trigger_token: ${{ secrets.GITLAB_TRIGGER_TOKEN }}
    gitlab_api_token: ${{ secrets.GITLAB_API_TOKEN }}
    trigger_pipeline: true
    wait_for_pipeline: true
    poll_interval: 15
```

### 範例 3：完整工作流程搭配輸出

在完整工作流程中使用此 Action 並引用輸出：

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
          gitlab_ref: ${{ github.ref_name }}
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

## 安全性注意事項

- 將所有 GitLab Token 儲存在 **GitHub Secrets** 中：
  - `GITLAB_PUSH_TOKEN` - 用於推送程式碼
  - `GITLAB_TRIGGER_TOKEN` - 用於觸發 Pipeline
  - `GITLAB_API_TOKEN` - 用於讀取 Pipeline 狀態
- 切勿將 Token 提交到您的儲存庫
- 使用具有適當存取限制的儲存庫 Secrets
- 考慮為生產環境部署使用環境特定的 Secrets
