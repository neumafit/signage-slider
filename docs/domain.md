---
repo: signage-slider
service: signage-slider
doc_type: domain_knowledge
summary: 사이니지 슬라이더가 쓰는 모드/파트너/파일명 컨벤션과 배포·자동갱신 관련 도메인 규칙.
---

# Domain Knowledge

이 리포에서 쓰이는 도메인 용어, 규칙, 데이터 흐름을 기록한다. 용어는 dev-memory의 `shared/glossary.md`와 일관성을 유지한다.

## 용어/약어
이 리포 코드에서 등장하는 용어와 약어. 일반 단어인데 도메인 특화 의미인 것을 우선 기록.

| 용어 | 의미 | 맥락 | 출처 |
|---|---|---|---|
| 세로형 / vertical | 대형 TV를 세로 방향으로 설치한 사이니지 모드 | `IMAGE_LIST.vertical`, `src/images/vertical/` | `src/script.js` |
| 가로형 / horizontal | 대형 TV를 가로 방향으로 설치한 사이니지 모드 | `IMAGE_LIST.horizontal`, `src/images/horizontal/` | `src/script.js` |
| `3840x2160` (파일명 prefix) | 4K UHD 원본 해상도 가정. 실제 디스플레이 해상도가 다르면 `object-fit: contain`으로 검은 여백 생김 | 이미지 파일명 컨벤션 | <!-- human verified:2026-04 : 4K 기본 가정 -->  |
| `neumafit` (파일명) | Neumafit 자체 브랜딩 이미지 | `3840x2160-3-neumafit.png` | 파일명 |
| `jambaekee` (파일명) | 파트너/입점사 잼백희 | `3840x2160-4-jambaekee.png` | <!-- human verified:2026-04 : 파트너/입점사 --> |
| `jeleve` (파일명) | 파트너/입점사 제레브 | `3840x2160-5-jeleve.png` | <!-- human verified:2026-04 : 파트너/입점사 --> |
| `version.json` | 배포 식별자. 내용은 `{"version":"<git sha>"}` 한 줄 | 루트 경로에 배포 시 자동 생성 | `.github/workflows/deploy.yml` |
| `{env}/web` 태그 | 배포 트리거 태그 형식. `env ∈ {dev, stg, prd}` | `on.push.tags: ["*/web"]` | `.github/workflows/deploy.yml` |
| `prd` 단독 운영 | 현재 `infrastructure/environments/` 아래 `prd`만 존재. `dev`, `stg`는 미구축 | 워크플로우는 3환경 지원, 인프라만 prd 운영 | <!-- human verified:2026-04 : 현재만 prd, 추후 확장 가능 --> |

## 비즈니스 규칙
측정/처리/저장 조건에 대한 규칙.

<!-- human verified:2026-04 -->

- **슬라이드 간격 20초, 전환 1초.** `SLIDE_INTERVAL = 20000` ([src/script.js:19](../src/script.js#L19)) + CSS `transition: transform 1s` ([src/style.css:82](../src/style.css#L82)). 5장 기준 한 바퀴 ≈ 5 × 20s = 100초.
- **자동 새로고침 주기는 한 바퀴마다.** `nextSlide`에서 마지막 복제 이미지 도달 시 `checkVersion()` 재호출 ([src/script.js:113](../src/script.js#L113)). 따라서 배포 후 현장 반영까지 최대 ~100초.
- **모드 상태는 URL 해시에 저장.** 버전 변경 감지 시 `location.hash = currentMode` 후 `location.reload()`. 다음 로드에서 해시를 읽어 선택 화면을 건너뛰고 슬라이더 재시작 ([src/script.js:49-54](../src/script.js#L49-L54)).
- **이미지 목록은 `IMAGE_LIST` 상수에서만 관리.** 파일 시스템 스캔이 아니므로 파일을 넣어도 `script.js`에 추가하지 않으면 노출되지 않는다. 제거 시에도 마찬가지.
- **배포 대상은 `src/` 하위 전체.** `aws s3 sync src/ ... --delete`이므로 `src/`에서 빠진 파일은 즉시 S3에서도 제거된다.
- **이 리포는 `neumafit-signage-manager`(WPF 앱)와 연결되지 않는다.** 각 사이니지는 브라우저에서 URL을 여는 방식으로 독립 실행된다. <!-- human verified:2026-04 : manager와 연관 없음 -->

## 데이터 흐름
이 리포가 다루는 데이터의 입출력 경로. 서비스 간 상세는 dev-memory `architecture/data-flow.md` 참조. 이 리포는 **Neumafit 내부 서비스와 런타임 통신이 없다**.

<!-- human verified:2026-04 -->

```
[개발자] --git tag {env}/web--> [GitHub Actions]
                                       |
                                       v
                          [Secrets Manager /neumafit/signage-slider/{env}]
                                       | (S3_BUCKET, CF_DIST_ID, ACM_ARN)
                                       v
                          [S3 neumafit-signage-slider-web-{env}] <-- aws s3 sync src/
                                       |       (version.json 포함, --delete)
                                       v
                          [CloudFront (invalidation /*)]
                                       |
                                       v
                          [브라우저 (사이니지 Chrome 전체화면)]
                                       |
                                       v--GET version.json (한 바퀴마다) --> 변경 감지 시 reload
```

- 브라우저 → CloudFront로만 통신. 다른 Neumafit 서비스(fatmax, analysis-server, neuerra 등)와 아무 연결이 없다.
- `version.json`은 git에 커밋하지 않는다. 매 배포 때 Actions가 생성하므로 로컬에서 빌드해도 파일이 없다.
