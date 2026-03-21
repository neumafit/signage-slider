# Signage Slider

디지털 사이니지용 이미지 슬라이더. 세로형/가로형을 선택하면 PNG 이미지들이 20초 간격으로 자동 슬라이드되며 무한 반복된다.

## 환경별 접속 정보

| 환경 | URL | 배포 트리거 |
|------|-----|-------------|
| **prd** | https://signage-slider.neumafit.com | `git tag prd/web && git push origin prd/web` |

> 배포 설정(S3 버킷, CloudFront ID 등)은 AWS Secrets Manager(`/neumafit/signage-slider/{env}`)에서 관리됩니다.

## 기술 스택

- **순수 HTML/CSS/JavaScript** (프레임워크 없음, 빌드 도구 없음)
- **호스팅**: S3 + CloudFront
- **IaC**: Terraform (`infrastructure/`)

## 개발

`src/index.html`을 브라우저에서 직접 열거나, Live Server 등으로 로컬 서버를 실행합니다.

## 배포

`{env}/web` 태그 push 시 GitHub Actions(`.github/workflows/deploy.yml`)로 자동 배포됩니다.
수동 배포는 GitHub Actions의 `workflow_dispatch`에서 환경을 선택하여 실행할 수 있습니다.

```bash
# prd 배포 예시 (기존 태그 삭제 후 재생성)
git tag -d prd/web 2>/dev/null; git push origin :refs/tags/prd/web 2>/dev/null
git tag prd/web && git push origin prd/web
```

## 인프라 초기 설정

```bash
# 1. Secret 먼저 생성
./infrastructure/run_tf.sh prd apply \
  -target=module.this.aws_secretsmanager_secret.deploy_config \
  -target=module.this.aws_secretsmanager_secret_version.deploy_config_initial

# 2. ACM 인증서 ARN 등 설정
./infrastructure/secret.sh prd

# 3. 전체 인프라 생성
./infrastructure/run_tf.sh prd apply
```
