#!/bin/bash

# コンテナイメージのビルドとプッシュスクリプト

set -e

# 設定
PROJECT_ID=${PROJECT_ID:-"your-gcp-project-id"}
IMAGE_TAG=${IMAGE_TAG:-"latest"}
IMAGE_NAME="ha-app"

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

# GCP認証の確認
log_info "GCP認証を確認中..."
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    log_error "GCPにログインしていません。'gcloud auth login'を実行してください。"
    exit 1
fi

# Docker認証の設定
log_info "Docker認証を設定中..."
gcloud auth configure-docker

# コンテナイメージのビルド
log_info "コンテナイメージをビルド中..."
docker build -t gcr.io/$PROJECT_ID/$IMAGE_NAME:$IMAGE_TAG .

# コンテナイメージのプッシュ
log_info "コンテナイメージをプッシュ中..."
docker push gcr.io/$PROJECT_ID/$IMAGE_NAME:$IMAGE_TAG

log_info "完了！イメージURI: gcr.io/$PROJECT_ID/$IMAGE_NAME:$IMAGE_TAG"

# terraform.tfvarsの更新提案
log_info "terraform.tfvarsのapp_imageを以下に更新してください:"
echo "app_image = \"gcr.io/$PROJECT_ID/$IMAGE_NAME:$IMAGE_TAG\""
