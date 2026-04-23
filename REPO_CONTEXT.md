---
repo: signage-slider
service: signage-slider
role: frontend
summary: 무인매장/시설 내 대형 TV에 전체화면으로 띄우는 디지털 사이니지 이미지 슬라이더. 순수 HTML/CSS/Vanilla JS로 작성된 정적 사이트이며 S3 + CloudFront로 배포된다. 자체 `version.json` 폴링으로 배포 시 자동 새로고침된다.
last_synced: 2026-04-23
---

# signage-slider
> ⚠️ 자동 생성 문서. 신뢰도는 각 섹션의 `human verified` 태그를 참조.

## Overview
무인매장·시설 내 대형 TV에서 Chrome 전체화면으로 구동되는 사이니지용 이미지 슬라이더. 시작 화면에서 세로형/가로형을 선택하면 `src/images/{mode}/`의 PNG들이 20초 간격으로 자동 전환되며 무한 반복된다. 배포마다 GitHub Actions가 커밋 해시로 `version.json`을 생성하고, 슬라이더는 슬라이드 한 바퀴(약 100초)마다 이 파일을 폴링해 버전이 바뀌면 현재 모드를 URL 해시에 기록한 뒤 `location.reload()` 한다. 이 때문에 이미지 교체·코드 변경 등 어떤 배포든 현장 사이니지 조작 없이 자동 반영된다.

`neumafit-signage-manager`(C# WPF 앱)와는 무관한 별개 시스템이다. <!-- human verified:2026-04 : manager와 연관 없음 -->

## Commands
리포를 로컬에서 빌드·테스트·배포할 때 사용하는 실제 커맨드. 빌드 도구가 없어 install/build/test 단계는 없다.

```bash
# 로컬 개발 — 브라우저에서 직접 열거나 Live Server 등으로 서빙
open src/index.html

# Terraform 인프라 (환경별)
./infrastructure/run_tf.sh prd plan
./infrastructure/run_tf.sh prd apply

# Secret 설정 (대화형, Terraform output 자동 로드)
./infrastructure/secret.sh prd

# 배포 — 태그 푸시로 GitHub Actions 트리거
git tag -d prd/web 2>/dev/null; git push origin :refs/tags/prd/web 2>/dev/null
git tag prd/web && git push origin prd/web

# 수동 배포
gh workflow run deploy.yml -f environment=prd
```

배포 태그 형식은 `{env}/web` 이며 `dev|stg|prd` 세 환경을 지원하도록 워크플로우가 작성되어 있으나 **현재 `prd` 환경만 실제로 구축되어 있다**. <!-- human verified:2026-04 : prd 외 환경은 추후 확장 가능 -->

## Tech Stack
버전이 명시된 주요 기술 스택.

| 분류 | 기술 |
|---|---|
| 언어 | HTML5, CSS3, Vanilla JavaScript (ES5 호환 스타일) |
| 프레임워크 | 없음 (프레임워크·번들러·빌드 도구 모두 사용 안 함) |
| 호스팅 | AWS S3 + CloudFront |
| IaC | Terraform >= 1.0, AWS provider ~> 5.0 |
| 공유 모듈 | `github.com/neumafit/terraform-aws-s3-cloudfront-deployment` |
| CI/CD | GitHub Actions (`.github/workflows/deploy.yml`) |
| 배포 설정 저장소 | AWS Secrets Manager — `/neumafit/signage-slider/{env}` |
| DNS/TLS | Route53 (`neumafit.com`) + ACM 인증서 (us-east-1) |
| AWS Region | ap-northeast-2 (CloudFront 인증서는 us-east-1) |

## Project Structure
리포의 디렉토리 구조와 각 디렉토리의 책임. 상세는 각 모듈 문서 참조.

```
signage-slider/
├── src/                     # 배포 대상 정적 에셋 (S3에 통째로 sync)
│   ├── index.html
│   ├── style.css
│   ├── script.js
│   └── images/
│       ├── vertical/        # 세로형 PNG (현재 5장)
│       └── horizontal/      # 가로형 PNG (현재 5장)
├── infrastructure/          # Terraform (S3 + CloudFront + Secrets)
│   ├── environments/
│   │   └── prd/             # 환경별 backend/tfvars (현재 prd만)
│   ├── modules/
│   │   └── signage-slider/  # 공통 모듈
│   ├── run_tf.sh            # Terraform 실행 래퍼
│   └── secret.sh            # Secrets Manager 값 대화형 설정
├── .github/workflows/
│   └── deploy.yml           # 태그 푸시 시 S3 sync + CF invalidation
├── CLAUDE.md                # 프로젝트 가이드
└── README.md
```

| 경로 | 역할 | 상세 문서 |
|---|---|---|
| [src/](./src/) | 슬라이더 웹 앱 본체 (HTML/CSS/JS/이미지) | [docs/modules/web.md](./docs/modules/web.md) |
| [infrastructure/](./infrastructure/) | Terraform IaC + 배포 설정 스크립트 | [docs/modules/deploy.md](./docs/modules/deploy.md) |
| [.github/workflows/](./.github/workflows/) | S3 sync + CloudFront 무효화 파이프라인 | [docs/modules/deploy.md](./docs/modules/deploy.md) |

## Data I/O
이 리포가 다루는 데이터의 입출력 요약. 서비스 간 상세는 dev-memory `architecture/data-flow.md` 참조 — 단 이 리포는 런타임에 **다른 Neumafit 서비스와 통신하지 않는다**.

| 방향 | 데이터 | 저장소 | 포맷 | 비고 |
|---|---|---|---|---|
| 배포 → 런타임 | 정적 에셋 (HTML/CSS/JS/PNG) | S3 `neumafit-signage-slider-web-{env}` | 파일 | GitHub Actions가 `aws s3 sync --delete`로 업로드 |
| 배포 → 런타임 | 배포 식별자 | S3 `src/version.json` | `{"version":"<git sha>"}` | 배포 때마다 GitHub Actions가 생성, 리포에 커밋 안 됨 |
| 런타임 → 클라이언트 | 정적 에셋 | CloudFront (캐시 앞단) | HTTP | 배포 후 `/*` 전체 invalidation |
| 배포 설정 | S3 버킷명·CloudFront ID·ACM ARN | Secrets Manager `/neumafit/signage-slider/{env}` | JSON | Terraform이 생성·머지, workflow가 읽음 |
| Terraform state | tfstate | S3 `neumafit-terraform-state` key `signage-slider/{env}/terraform.tfstate` | tfstate | backend 설정은 `environments/{env}/main.tf` |

## Known Quirks 요약
잘못 수정 시 장애 가능성이 있는 코드. 전체는 [docs/quirks.md](./docs/quirks.md).

- ⚠️ `src/index.html`의 `?v=N` 캐시 버스팅 쿼리 — CSS/JS 수정 시 **수동으로 번호를 올려야** 브라우저 캐시가 갱신된다.
- ⚠️ `src/script.js`의 `setTimeout(..., 1000)` 스냅백 타이밍은 `src/style.css`의 `transition: transform 1s` 값과 반드시 일치해야 한다 — 한 쪽만 바꾸면 마지막 슬라이드에서 튀어 보인다.
- ⚠️ 이미지 파일명에 하드코딩된 `3840x2160` 4K 기준 — 다른 해상도를 넣어도 `object-fit: contain`으로 보이긴 하지만 검은 여백이 생길 수 있다.

## Where to Look
작업 키워드별 첫 확인 문서와 구체 파일 경로.

| 작업 키워드 | 첫 확인 | 상세 파일 |
|---|---|---|
| 이미지 교체/추가 | [CLAUDE.md](./CLAUDE.md) "이미지 변경 방법" | [src/script.js](./src/script.js) (`IMAGE_LIST`), [src/images/](./src/images/) |
| 슬라이드 간격/전환 속도 | [docs/modules/web.md](./docs/modules/web.md) | [src/script.js](./src/script.js) (`SLIDE_INTERVAL`), [src/style.css](./src/style.css) (`transition`) |
| 자동 새로고침 로직 | [docs/modules/web.md](./docs/modules/web.md) | [src/script.js](./src/script.js) (`checkVersion`) |
| 배포 트리거/파이프라인 | [docs/modules/deploy.md](./docs/modules/deploy.md) | [.github/workflows/deploy.yml](./.github/workflows/deploy.yml) |
| 인프라·도메인·버킷 | [docs/modules/deploy.md](./docs/modules/deploy.md) | [infrastructure/modules/signage-slider/main.tf](./infrastructure/modules/signage-slider/main.tf), [infrastructure/environments/prd/terraform.tfvars](./infrastructure/environments/prd/terraform.tfvars) |
| 배포 설정값(ACM/버킷/CF) | [README.md](./README.md) "인프라 초기 설정" | [infrastructure/secret.sh](./infrastructure/secret.sh) |

## Boundaries
이 리포 특유의 지켜야 할 규칙. 팀 전역 규칙(lint, commit convention 등)은 neumafit-dev-guide 플러그인 참조.

- ✅ **Always**:
  - `src/script.js`의 `IMAGE_LIST`는 실제 `src/images/{mode}/` 파일 목록과 정확히 일치해야 한다. 파일만 추가/제거하고 목록을 반영하지 않으면 404 또는 누락 발생.
  - `src/index.html`의 `style.css?v=N`, `script.js?v=N` 쿼리 넘버는 CSS/JS 수정 시 함께 올린다 (CloudFront 캐시 + 브라우저 캐시 대응).
  - `src/script.js` `SLIDE_INTERVAL`(ms)과 `src/style.css` `#slider-track { transition: transform 1s }`의 1초 값, `setTimeout(..., 1000)` 세 값은 동시에 조정해야 애니메이션이 깨지지 않는다.
- ⚠️ **Ask first**:
  - 프레임워크/번들러 도입 — 현재 "빌드 없음"이 의도된 단순함이다. 도입 시 배포 파이프라인도 다시 설계해야 한다.
  - 환경 추가 (dev/stg) — 워크플로우는 3환경을 지원하지만 현재 `prd`만 구축. 추가 시 `infrastructure/environments/{env}/`, Secrets Manager, ACM 인증서까지 함께 세팅 필요.
- 🚫 **Never**:
  - `src/version.json`을 직접 커밋하지 말 것 — 항상 GitHub Actions가 배포 시 `git sha`로 덮어쓴다.
  - `neumafit-signage-manager`(WPF 앱)와 연결 코드를 넣지 말 것 — 현재 연관 없는 별개 시스템이다. <!-- human verified:2026-04 -->
  - `oldAssets/`를 커밋하지 말 것 — 로컬 이미지 백업용이며 `.gitignore` 처리되어 있다.

## Deployment
환경별 배포 정보.

| 환경 | URL | 배포 트리거 |
|---|---|---|
| prd | https://signage-slider.neumafit.com | `git tag prd/web && git push origin prd/web` 또는 `gh workflow run deploy.yml -f environment=prd` |
| dev, stg | (미구축) | 워크플로우는 지원. 인프라는 추후 필요 시 구축 |

배포 시퀀스: 태그 푸시 → GitHub Actions → Secrets Manager에서 `S3_BUCKET`·`CLOUDFRONT_DISTRIBUTION_ID` 로드 → `src/version.json` 생성 → `aws s3 sync src/` (`--delete`) → `aws cloudfront create-invalidation --paths "/*"`. 현장 사이니지는 최대 한 슬라이드 사이클(≈100초) 이내에 새 버전을 감지하고 자체 reload 한다.
