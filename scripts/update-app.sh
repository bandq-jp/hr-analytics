#!/bin/bash

# アプリケーションの更新スクリプト（コード変更後の再デプロイ用）

set -e

# 設定
PROJECT_ID=${PROJECT_ID:-"your-gcp-project-id"}
IMAGE_TAG=${IMAGE_TAG:-"$(date +%Y%m%d-%H%M%S)"}
TERRAFORM_DIR="terraform"

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
log_info "イメージタグ: $IMAGE_TAG"

# 1. コンテナイメージのビルドとプッシュ
log_info "コンテナイメージをビルド・プッシュ中..."
./scripts/build-and-push.sh

# 2. terraform.tfvarsの更新
log_info "terraform.tfvarsを更新中..."
sed -i.bak "s|app_image = \".*\"|app_image = \"gcr.io/$PROJECT_ID/ha-app:$IMAGE_TAG\"|" $TERRAFORM_DIR/terraform.tfvars

# 3. Terraformの適用
cd $TERRAFORM_DIR
log_info "Terraformを適用中..."
terraform apply -auto-approve

log_info "アプリケーションの更新が完了しました！"
log_info "新しいイメージタグ: $IMAGE_TAG"
