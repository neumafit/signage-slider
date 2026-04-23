---
repo: signage-slider
service: signage-slider
doc_type: quirks
summary: 슬라이더/배포 파이프라인에서 잘못 건드리면 장애가 나는 타이밍·캐시·인프라 이슈 모음.
---

# Known Quirks

⚠️ 이 문서의 항목은 **건드리면 장애 가능성**이 있는 것만 기록한다. 일반적인 코드 스멜이나 취향 문제는 포함하지 않는다.

## 구조 불일치
대부분의 모듈이 따르는 패턴에서 벗어나 있는 부분.

<!-- human verified:2026-04 -->

### 이미지 목록이 파일 시스템이 아닌 JS 상수
`src/script.js`의 `IMAGE_LIST`가 실제 배포 소스. `src/images/{mode}/` 디렉토리를 스캔하지 않으므로 **파일만 추가하거나 삭제하면 런타임에서 404 또는 누락이 발생**한다. 이미지 작업 시 반드시 `IMAGE_LIST`를 함께 수정해야 한다.

### 환경별 분리가 워크플로우에만 존재
`.github/workflows/deploy.yml`은 `dev|stg|prd` 3환경을 지원하지만 `infrastructure/environments/` 아래에는 `prd`만 존재한다. `workflow_dispatch`에서 dev/stg를 선택하면 **Secrets Manager ID 조회 단계에서 실패**한다. 환경 추가 시 tfvars + Secrets Manager + ACM 인증서를 모두 준비해야 한다. <!-- human verified:2026-04 : 현재는 prd 단독 운영이 의도 -->

## 위험한 코드
잘못 수정 시 장애로 이어질 수 있는 코드.

<!-- human verified:2026-04 -->

### 캐시 버스팅 쿼리 `?v=N` 수동 관리
`src/index.html`의 `<link href="style.css?v=12">`, `<script src="script.js?v=12">` 번호를 **CSS/JS 수정 시 수동으로 올려야** 브라우저 캐시 갱신이 보장된다. CloudFront는 배포마다 `/*` 무효화로 처리되지만, 브라우저는 쿼리가 같으면 캐시된 스크립트를 그대로 쓴다. CLAUDE.md에도 명시되어 있다.

### 스냅백 타이밍 — CSS transition · JS setTimeout · SLIDE_INTERVAL 연동
- `src/style.css` `#slider-track { transition: transform 1s ease-in-out; }`
- `src/script.js` `nextSlide`의 `setTimeout(..., 1000)` ([src/script.js:110](../src/script.js#L110))
- `src/script.js` `SLIDE_INTERVAL = 20000` ([src/script.js:19](../src/script.js#L19))

이 세 값 중 "transition 시간 = setTimeout 시간"이 반드시 일치해야 마지막 복제 이미지에서 첫 이미지로 **순간이동**이 자연스럽다. 한 쪽만 바꾸면 snap 타이밍이 어긋나 튄다. `SLIDE_INTERVAL`은 transition보다 커야 하지만 동기화까지는 필요 없다.

### `version.json` 변경 감지 시 `location.reload()` — 최초 로드 때는 비교 안 함
`checkVersion()`은 `knownVersion === null`이면 현재 버전을 그냥 저장한다. 즉 페이지 최초 로드는 무조건 현재 버전을 받아들이고, 이후 폴링에서만 비교한다. **S3가 업로드 중간 상태**(version.json은 새 값인데 일부 이미지는 아직 옛 값)일 때 reload하면 깨진 화면이 나올 수 있지만, 현재 워크플로우는 `aws s3 sync` 한 번에 모두 올린 뒤 CloudFront invalidation을 하므로 실전 영향은 작다. 배포 파이프라인을 변경할 때 업로드 순서에 유의할 것.

### 캐시 Meta 태그는 `version.json` 신선도에 도움 안 됨
`src/index.html`의 `<meta http-equiv="Cache-Control" content="no-cache, ...">`는 HTML 자체에 대한 힌트일 뿐, CloudFront와 브라우저의 `version.json` 캐시에는 영향이 없다. 실제로 `checkVersion`은 `?t=Date.now()` 쿼리로 캐시를 우회한다 ([src/script.js:28](../src/script.js#L28)). 이 쿼리를 제거하면 사이니지가 갱신을 영원히 놓칠 수 있다.

### Secret 초기화 2단계 절차
`infrastructure/modules/signage-slider/main.tf`는:
1. `aws_secretsmanager_secret_version.deploy_config_initial` — 빈 `ACM_CERTIFICATE_ARN`을 기록하고 `lifecycle { ignore_changes = [secret_string] }`.
2. `aws_secretsmanager_secret_version.deploy_config` — Terraform output(`S3_BUCKET`, `CLOUDFRONT_DISTRIBUTION_ID`)을 `merge`로 다시 씀.

따라서 **ACM ARN을 반드시 `terraform apply` 전에 `./infrastructure/secret.sh` 또는 콘솔로 수동 입력**해야 한다 (README "인프라 초기 설정" 참조). 순서를 어기면 S3/CloudFront를 만들려는 단계에서 빈 ACM ARN으로 실패한다.

### CloudFront 인증서는 us-east-1 전용
`environments/prd/main.tf`에 `provider "aws" { alias = "us_east_1" }`가 있는 이유. ACM 인증서를 ap-northeast-2에 만들면 CloudFront에 붙지 않는다.

## 의도 불명확
TODO/FIXME, 주석 처리된 블록, 용도가 불확실한 함수.

<!-- human verified:2026-04 -->

현재 이 리포에서는 발견된 항목이 없다. TODO/FIXME 주석, 주석 처리된 코드, 사용되지 않는 함수 모두 없는 상태.
