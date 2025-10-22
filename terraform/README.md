# Hiring Analytics Platform - Terraform Infrastructure

このディレクトリには、Hiring Analytics Platformのインフラストラクチャを定義するTerraformコードが含まれています。

## 構造

```
terraform/
├── modules/           # 再利用可能なモジュール
│   ├── network/       # VPC、サブネット、VPC Access Connector
│   ├── database/      # Cloud SQL インスタンスとデータベース
│   ├── app/          # FastAPI アプリケーションとスケジューラー
│   └── metabase/     # Metabase サービス
├── envs/             # 環境別の設定
│   └── dev/          # 開発環境
└── README.md
```

## モジュール

### Network Module
- VPC ネットワーク
- サブネット
- VPC Access Connector（サーバーレスサービス用）

### Database Module
- Cloud SQL PostgreSQL インスタンス
- アプリケーション用データベース
- Metabase用データベース
- データベースユーザー

### App Module
- FastAPI アプリケーション（Cloud Run）
- Cloud Scheduler ジョブ（データ取り込み・変換）
- サービスアカウント
- Secret Manager シークレット

### Metabase Module
- Metabase サービス（Cloud Run）
- サービスアカウント
- データベース接続設定

## 使用方法

### 開発環境のデプロイ

1. `envs/dev/` ディレクトリに移動：
   ```bash
   cd envs/dev
   ```

2. `terraform.tfvars.example` をコピーして設定：
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

3. `terraform.tfvars` を編集して必要な値を設定

4. Terraform を初期化：
   ```bash
   terraform init
   ```

5. プランを確認：
   ```bash
   terraform plan
   ```

6. デプロイ：
   ```bash
   terraform apply
   ```

## 必要な変数

- `project_id`: GCP プロジェクト ID
- `app_image`: FastAPI アプリケーションのコンテナイメージ
- `database_password`: アプリケーションデータベースのパスワード
- `metabase_database_password`: Metabase データベースのパスワード
- `supabase_url`: Supabase プロジェクトの URL
- `supabase_service_role_key`: Supabase サービスロールキー

## 出力

デプロイ後、以下の情報が出力されます：

- `app_service_url`: FastAPI アプリケーションの URL
- `metabase_service_url`: Metabase サービスの URL
- `cloud_sql_private_ip`: Cloud SQL インスタンスのプライベート IP
- `cloud_sql_instance_connection_name`: Cloud SQL インスタンスの接続名