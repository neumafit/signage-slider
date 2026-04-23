---
repo: signage-slider
service: signage-slider
module: deploy
summary: Terraform으로 S3 + CloudFront + Route53 + Secrets Manager를 구성하고, GitHub Actions가 태그 푸시 시 S3 sync + CloudFront invalidation으로 배포한다. 배포 설정값은 Secrets Manager에 보관.
---

# deploy

## 한 줄 설명
태그 `{env}/web` 푸시 → GitHub Actions → Secrets Manager에서 배포 설정 로드 → `version.json` 생성 → `aws s3 sync` → CloudFront 전체 무효화. 인프라는 Terraform으로 관리.

## 핵심 파일
이 모듈의 진입점과 주요 구현 위치.

| 파일 | 역할 |
|---|---|
| [.github/workflows/deploy.yml](../../.github/workflows/deploy.yml) | 태그 push(`*/web`) 및 workflow_dispatch 트리거. Secrets 로드 → version.json 생성 → S3 sync → CF invalidation |
| [infrastructure/modules/signage-slider/main.tf](../../infrastructure/modules/signage-slider/main.tf) | 공통 모듈. `aws_secretsmanager_secret` + `terraform-aws-s3-cloudfront-deployment` 사용, Terraform output을 다시 secret에 머지 |
| [infrastructure/modules/signage-slider/variables.tf](../../infrastructure/modules/signage-slider/variables.tf) | `environment`, `hosted_zone_name`, `web_domain` |
| [infrastructure/modules/signage-slider/outputs.tf](../../infrastructure/modules/signage-slider/outputs.tf) | S3 버킷명, CloudFront ID, 배포 명령 출력 |
| [infrastructure/environments/prd/main.tf](../../infrastructure/environments/prd/main.tf) | backend(S3 tfstate), provider(ap-northeast-2 + us-east-1 alias), 모듈 호출 |
| [infrastructure/environments/prd/terraform.tfvars](../../infrastructure/environments/prd/terraform.tfvars) | prd 고유 값 (도메인, 호스팅존) |
| [infrastructure/run_tf.sh](../../infrastructure/run_tf.sh) | Terraform 실행 래퍼 (`./run_tf.sh <env> <cmd>`) |
| [infrastructure/secret.sh](../../infrastructure/secret.sh) | 대화형으로 Secrets Manager 값 설정. Terraform output을 기본값으로 프롬프트 |

## 주요 흐름
### 인프라 최초 구축
1. `./infrastructure/run_tf.sh prd apply -target=module.this.aws_secretsmanager_secret.deploy_config -target=module.this.aws_secretsmanager_secret_version.deploy_config_initial` — Secret 껍데기 먼저 생성.
2. `./infrastructure/secret.sh prd` — 대화형으로 ACM 인증서 ARN(us-east-1) 등 수동 값 입력.
3. `./infrastructure/run_tf.sh prd apply` — S3 버킷·CloudFront·Route53 레코드 생성. Terraform이 S3 버킷명·CF Distribution ID를 다시 Secret에 머지.

### 코드/이미지 배포
1. 개발자가 `src/` 하위를 수정하고 커밋 → push.
2. `git tag -d prd/web` 후 `git tag prd/web && git push origin prd/web` (기존 태그 있으면 삭제 후 재생성).
3. GitHub Actions `deploy.yml`이 태그 기준으로 환경 이름 추출(`prd/web` → `prd`).
4. `aws secretsmanager get-secret-value --secret-id /neumafit/signage-slider/prd` 로 `S3_BUCKET`, `CLOUDFRONT_DISTRIBUTION_ID` 로드.
5. `echo '{"version":"${github.sha}"}' > src/version.json` — 커밋 해시를 버전으로 기록.
6. `aws s3 sync src/ s3://${S3_BUCKET}/ --delete` — 배포 대상 전체 동기화.
7. `aws cloudfront create-invalidation --paths "/*"` — 엣지 캐시 무효화.
8. 현장 사이니지는 최대 ~100초 이내에 `version.json` 변경을 감지하고 자체 `location.reload()` (→ [web.md](./web.md)).

### 수동 배포
`gh workflow run deploy.yml -f environment=prd` — 태그 없이 `workflow_dispatch`로 동일 파이프라인 실행. `github.ref_name`이 아닌 `inputs.environment`를 환경 이름으로 사용한다.

## 외부 인터페이스
이 모듈은 인프라/배포 경로를 구성하며, 노출하는 "인터페이스"는 외부 트리거와 AWS 리소스 이름뿐.

| 종류 | 시그니처 | 용도 |
|---|---|---|
| 배포 트리거 | git tag `{env}/web` push | GitHub Actions `deploy.yml` 기동 |
| 배포 트리거 | `gh workflow run deploy.yml -f environment={env}` | 수동 `workflow_dispatch` |
| AWS 리소스 | S3 `neumafit-signage-slider-web-{env}` | 정적 에셋 버킷 |
| AWS 리소스 | CloudFront (Distribution ID는 Secret 내) | 웹 서빙 |
| AWS 리소스 | Secrets Manager `/neumafit/signage-slider/{env}` | `ACM_CERTIFICATE_ARN`, `S3_BUCKET`, `CLOUDFRONT_DISTRIBUTION_ID` |
| AWS 리소스 | S3 `neumafit-terraform-state` key `signage-slider/{env}/terraform.tfstate` | Terraform state backend |
| 도메인 | `signage-slider.neumafit.com` (prd) | 호스팅존 `neumafit.com` + ACM (us-east-1) |

## 의존 관계
- **내부**: [src/](../../src/) — 배포 대상 디렉토리.
- **외부**:
  - `github.com/neumafit/terraform-aws-s3-cloudfront-deployment` — 공용 Terraform 모듈 (S3 OAC + CloudFront + Route53 레코드 생성).
  - AWS: S3, CloudFront, Secrets Manager, Route53, ACM (us-east-1), IAM.
  - GitHub Actions Secrets: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`.
  - `actions/checkout@v4`, `aws-actions/configure-aws-credentials@v4`.

## Domain Knowledge
- 태그 네이밍 컨벤션 `{env}/web`은 추후 `{env}/api` 같은 백엔드 배포와 분리할 수 있도록 남겨둔 것. 현재 이 리포에는 web만 존재.
- ACM 인증서는 CloudFront 요구로 **반드시 `us-east-1`**에 있어야 한다 — provider alias `us_east_1` 참조.

## Known Quirks
- Secret의 `ACM_CERTIFICATE_ARN`은 `lifecycle { ignore_changes = [secret_string] }`로 초기값 공백이며 **수동 입력 후 Terraform이 덮어쓰지 않는다**. 반면 `S3_BUCKET`, `CLOUDFRONT_DISTRIBUTION_ID`는 Terraform이 매번 `merge`로 갱신한다 → [../quirks.md](../quirks.md) "Secret 초기화 2단계".
- 환경 추가 시 워크플로우는 이미 dev/stg를 지원하지만 `infrastructure/environments/{env}/`, ACM 인증서, Secrets가 모두 사전 구축돼 있어야 한다. 하나라도 빠지면 배포가 반쯤 진행되다 실패한다.
