#!/usr/bin/env bash
# -------------------------------------------------------------------
# secret.sh
#
# SM Secret(/neumafit/signage-slider/{env})을 관리한다.
# Secret 자체는 Terraform이 생성하므로, 이 스크립트는 값만 업데이트한다.
#
# 사용법:
#   ./infrastructure/secret.sh <env>          # 대화형 설정
# -------------------------------------------------------------------
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AWS_REGION="ap-northeast-2"

# --- 인자 검증 ---

ENV="${1:-}"
COMMAND="${2:-setup}"

if [[ -z "$ENV" || ! "$ENV" =~ ^(dev|stg|prd)$ ]]; then
  echo "사용법: $0 <env>"
  echo "  env: dev, stg, prd"
  exit 1
fi

SECRET_ID="/neumafit/signage-slider/$ENV"

# --- 공통 함수 ---

read_sm_secret() {
  aws secretsmanager get-secret-value \
    --secret-id "$SECRET_ID" \
    --query SecretString --output text \
    --region "$AWS_REGION" 2>/dev/null || echo "{}"
}

# ===================================================================
# setup: 대화형 설정
# ===================================================================

ENV_DIR="$SCRIPT_DIR/environments/$ENV"

echo "=== Signage Slider — deploy-config Secret 설정 ($ENV) ==="
echo ""

# --- Terraform output 읽기 ---

echo "[1/3] Terraform output 읽기 ($ENV_DIR)..."

if ! terraform -chdir="$ENV_DIR" output -json > /dev/null 2>&1; then
  echo "  ⚠ Terraform state를 읽을 수 없습니다. 수동 입력 모드로 전환합니다."
  echo ""
  TF_AVAILABLE=false
else
  TF_AVAILABLE=true
  TF_OUTPUT=$(terraform -chdir="$ENV_DIR" output -json)
fi

read_tf_output() {
  local key="$1"
  if [[ "$TF_AVAILABLE" == "true" ]]; then
    echo "$TF_OUTPUT" | jq -r ".$key.value // empty"
  fi
}

# --- 값 수집 ---

echo "[2/3] 설정 값 수집..."
echo ""

S3_BUCKET=$(read_tf_output "web_s3_bucket_name")
CLOUDFRONT_DISTRIBUTION_ID=$(read_tf_output "cloudfront_distribution_id")

# 기존 SM Secret에서 현재 값 읽기
echo "  기존 Secret 값 읽기 ($SECRET_ID)..."
EXISTING_CONFIG=$(read_sm_secret)

ACM_CERTIFICATE_ARN=$(echo "$EXISTING_CONFIG" | jq -r '.ACM_CERTIFICATE_ARN // empty')

# --- 값 프롬프트 ---

prompt_value() {
  local var_name="$1"
  local current_value="$2"
  local description="$3"

  if [[ -n "$current_value" ]]; then
    read -rp "  $var_name [$current_value]: " input_value
    if [[ -z "$input_value" ]]; then
      eval "$var_name=\"$current_value\""
    else
      eval "$var_name=\"$input_value\""
    fi
  else
    read -rp "  $var_name ($description): " input_value
    eval "$var_name=\"$input_value\""
  fi
}

prompt_value "S3_BUCKET" "$S3_BUCKET" "웹 S3 버킷 이름"
prompt_value "CLOUDFRONT_DISTRIBUTION_ID" "$CLOUDFRONT_DISTRIBUTION_ID" "CloudFront Distribution ID"
prompt_value "ACM_CERTIFICATE_ARN" "$ACM_CERTIFICATE_ARN" "ACM 인증서 ARN (us-east-1)"

echo ""

# --- JSON 생성 ---

echo "[3/3] Secret JSON 생성..."

SECRET_JSON=$(jq -n \
  --arg acm "$ACM_CERTIFICATE_ARN" \
  --arg s3 "$S3_BUCKET" \
  --arg cf "$CLOUDFRONT_DISTRIBUTION_ID" \
  '{
    ACM_CERTIFICATE_ARN: $acm,
    S3_BUCKET: $s3,
    CLOUDFRONT_DISTRIBUTION_ID: $cf
  }')

echo "$SECRET_JSON" | jq .
echo ""

# --- Secret 갱신 ---

echo "Secrets Manager 업데이트 ($SECRET_ID)..."

aws secretsmanager put-secret-value \
  --secret-id "$SECRET_ID" \
  --secret-string "$SECRET_JSON" \
  --region "$AWS_REGION"
echo "  ✓ Secret 갱신 완료"

echo ""
echo "=== 완료 ==="
echo "Secret ID: $SECRET_ID"
