#!/bin/bash

# Cloud Run開発環境のデプロイスクリプト

set -e

# 設定
TERRAFORM_DIR="terraform"
PROJECT_ID=${PROJECT_ID:-"your-gcp-project-id"}

# 色付きのログ出力
log_info() {
    echo -e "\033[32m[INFO]\033[0m $1"
}

log_error() {
    echo -e "\033[31m[ERROR]\033[0m $1"
}

log_warn() {
    echo -e "\033[33m[WARN]\033[0m $1"
}

# プロジェクトIDの確認
if [ "$PROJECT_ID" = "your-gcp-project-id" ]; then
    log_error "PROJECT_IDが設定されていません。環境変数PROJECT_IDを設定するか、スクリプト内のPROJECT_IDを変更してください。"
    exit 1
fi

log_info "プロジェクトID: $PROJECT_ID"

# terraform.tfvarsの存在確認
if [ ! -f "$TERRAFORM_DIR/terraform.tfvars" ]; then
    log_error "terraform.tfvarsファイルが見つかりません。"
    log_info "以下の手順で設定してください:"
    echo "1. cp $TERRAFORM_DIR/terraform.tfvars.example $TERRAFORM_DIR/terraform.tfvars"
    echo "2. $TERRAFORM_DIR/terraform.tfvarsを編集して必要な値を設定"
    exit 1
fi

# Terraformディレクトリに移動
cd $TERRAFORM_DIR

# Terraformの初期化
log_info "Terraformを初期化中..."
terraform init

# Terraformプランの確認
log_info "Terraformプランを確認中..."
terraform plan

# ユーザーに確認
echo ""
log_warn "上記のプランでリソースを作成/更新しますか？ (y/N)"
read -r response
if [[ ! "$response" =~ ^[Yy]$ ]]; then
    log_info "デプロイをキャンセルしました。"
    exit 0
fi

# Terraformの適用
log_info "Terraformを適用中..."
terraform apply -auto-approve

# 出力の表示
log_info "デプロイ完了！"
echo ""
log_info "=== デプロイ結果 ==="
terraform output

echo ""
log_info "=== 次のステップ ==="
echo "1. アプリケーションURL: $(terraform output -raw app_service_url)"
echo "2. Metabase URL: $(terraform output -raw metabase_service_url)"
echo "3. データベース初期化:"
echo "   psql \"\$(terraform output -raw cloud_sql_private_ip)\" -f db/sql/init/00_schemas.sql"
echo "   psql \"\$(terraform output -raw cloud_sql_private_ip)\" -f db/sql/init/10_raw_tables.sql"
echo "   psql \"\$(terraform output -raw cloud_sql_private_ip)\" -f db/sql/init/20_internal_tables.sql"
echo "   psql \"\$(terraform output -raw cloud_sql_private_ip)\" -f db/sql/transform/10_stg_views.sql"
echo "   psql \"\$(terraform output -raw cloud_sql_private_ip)\" -f db/sql/transform/20_mart_views.sql"
