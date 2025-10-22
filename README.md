## 採用分析プラットフォーム

このリポジトリには、`plan.md`で説明されている採用分析スタックの取り込みAPI、データウェアハウスSQLモデル、およびインフラストラクチャコードが含まれています。

### コンポーネント
- **FastAPIサービス (`app/`)** – Cloud Scheduler用の`/ingest/run`と`/transform/run`エンドポイントを公開
- **データウェアハウスDDL & モデル (`db/`)** – rawスキーマはSupabaseをミラーし、stagingビューでイベントを正規化し、martビューでMetabaseダッシュボードを強化
- **Terraform (`terraform/`)** – Cloud SQL、Cloud Run（アプリ + Metabase）、Schedulerジョブ、VPCコネクタ、およびサポートするIAM/シークレットをプロビジョニング

### ローカル開発
1. 依存関係をインストール:
   ```bash
   python -m venv .venv
   source .venv/bin/activate
   pip install -r app/requirements.txt
   ```
2. 環境変数を設定（`.env`テンプレートを参照）:
   - `DATABASE_URL`（例：Cloud SQL Proxy / ローカルPostgres経由）
   - `SUPABASE_URL`
   - `SUPABASE_KEY`
   - `GCP_PROJECT`, `GCP_REGION`
3. APIを実行:
   ```bash
   uvicorn app.main:app --reload --host 0.0.0.0 --port 8080
   ```
4. ローカルで取り込み/変換をトリガー:
   ```bash
   http POST :8080/ingest/run
   http POST :8080/transform/run
   ```

### データベースセットアップ
`db/sql/init`のSQLを一度適用してスキーマ/テーブルを作成し、その後変換ビューをデプロイ:
```bash
psql "$DATABASE_URL" -f db/sql/init/00_schemas.sql
psql "$DATABASE_URL" -f db/sql/init/10_raw_tables.sql
psql "$DATABASE_URL" -f db/sql/init/20_internal_tables.sql
psql "$DATABASE_URL" -f db/sql/transform/10_stg_views.sql
psql "$DATABASE_URL" -f db/sql/transform/20_mart_views.sql
```

### Cloud Run開発環境

実際のCloud Run環境で開発する場合：

#### 1. 初期セットアップ

```bash
# 1. GCPプロジェクトIDを設定
export PROJECT_ID="your-gcp-project-id"

# 2. terraform.tfvarsを設定
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# terraform/terraform.tfvarsを編集して必要な値を設定

# 3. 初回デプロイ
./scripts/deploy.sh
```

#### 2. アプリケーションの更新

コードを変更した後、以下のコマンドでアプリケーションを更新：

```bash
# コンテナイメージをビルド・プッシュしてCloud Runを更新
./scripts/update-app.sh
```

#### 3. 手動でのコンテナイメージ更新

```bash
# コンテナイメージのみをビルド・プッシュ
./scripts/build-and-push.sh

# terraform.tfvarsのapp_imageを更新してから
cd terraform
terraform apply
```

#### 4. データベース初期化

初回デプロイ後、データベースを初期化：

```bash
# Cloud SQL Proxyを使用してデータベースに接続
gcloud sql connect ha-analytics --user=app_user --database=analytics_app

# または、以下のSQLファイルを順番に実行
psql "postgresql://app_user:password@private-ip:5432/analytics_app" -f db/sql/init/00_schemas.sql
psql "postgresql://app_user:password@private-ip:5432/analytics_app" -f db/sql/init/10_raw_tables.sql
psql "postgresql://app_user:password@private-ip:5432/analytics_app" -f db/sql/init/20_internal_tables.sql
psql "postgresql://app_user:password@private-ip:5432/analytics_app" -f db/sql/transform/10_stg_views.sql
psql "postgresql://app_user:password@private-ip:5432/analytics_app" -f db/sql/transform/20_mart_views.sql
```

### デプロイメント
`terraform/`のTerraformが必要なGCPリソースをプロビジョニングします。提供する変数のリスト（コンテナイメージURI、Supabaseキー、DBパスワードなど）については`terraform/README.md`を確認してください。
