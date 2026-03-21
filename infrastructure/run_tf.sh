#!/usr/bin/env bash
set -euo pipefail

# -------------------------------------------------------------------
# Terraform 헬퍼 스크립트
# 사용법: ./run_tf.sh <env> [command] [extra args]
#   env:     dev | stg | prd
#   command: init | plan | apply | destroy | output (기본: plan)
#
# 예시:
#   ./run_tf.sh prd init
#   ./run_tf.sh prd plan
#   ./run_tf.sh prd apply
#   ./run_tf.sh prd output
# -------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ $# -lt 1 ]]; then
  echo "사용법: $0 <env> [command] [extra args]"
  echo "  env:     dev | stg | prd"
  echo "  command: init | plan | apply | destroy | output (기본: plan)"
  exit 1
fi

ENV="$1"
COMMAND="${2:-plan}"
shift 2 2>/dev/null || shift 1

ENV_DIR="${SCRIPT_DIR}/environments/${ENV}"

if [[ ! -d "$ENV_DIR" ]]; then
  echo "오류: 환경 디렉토리를 찾을 수 없습니다: ${ENV_DIR}"
  exit 1
fi

echo "=== ${ENV} 환경 — terraform ${COMMAND} ==="
cd "$ENV_DIR"

case "$COMMAND" in
  init)
    terraform init "$@"
    ;;
  plan)
    terraform plan -var-file=terraform.tfvars "$@"
    ;;
  apply)
    terraform apply -var-file=terraform.tfvars "$@"
    ;;
  destroy)
    terraform destroy -var-file=terraform.tfvars "$@"
    ;;
  output)
    terraform output "$@"
    ;;
  *)
    # 기타 terraform 명령 그대로 전달
    terraform "$COMMAND" "$@"
    ;;
esac
