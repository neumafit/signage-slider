# Signage Slider

## 프로젝트 개요
디지털 사이니지용 이미지 슬라이더 웹 애플리케이션.
시작 화면에서 세로형/가로형을 선택하면, `images/` 폴더의 PNG 이미지들이 20초 간격으로 자동 슬라이드되며 무한 반복된다.

## 기술 스택
- **순수 HTML/CSS/JavaScript** (프레임워크 없음)
- 별도 빌드 도구 없음 — 브라우저에서 직접 `index.html`을 열어 실행

## 프로젝트 구조
```
src/                    # 배포 대상 소스 (S3에 이 폴더가 통째로 업로드됨)
  index.html            # 메인 페이지 (선택 화면 + 슬라이더)
  style.css             # 스타일시트
  script.js             # 슬라이더 로직
  images/
    vertical/           # 세로형 이미지 (PNG)
    horizontal/         # 가로형 이미지 (PNG)
infrastructure/         # Terraform (S3 + CloudFront)
.github/workflows/      # GitHub Actions 배포
```

## 배포 방법
- 커밋 → 푸시 → 태그 푸시로 배포 트리거
  ```bash
  git push origin main && git tag -f prd/web && git push origin prd/web -f
  ```
- **수동 트리거**: `gh workflow run deploy.yml -f environment=prd`
- 태그 형식: `{환경}/web` (prd, stg, dev)
- 배포 파이프라인: GitHub Actions → S3 sync → CloudFront 캐시 무효화

## 자동 갱신 (version.json)
- 배포마다 GitHub Actions가 커밋 해시로 `version.json`을 자동 생성 (별도 작업 불필요)
- 사이니지의 슬라이더는 슬라이드 한 바퀴(~80초)마다 `version.json`을 fetch
- 버전이 바뀌면 현재 모드(vertical/horizontal)를 URL 해시에 저장 후 `location.reload()`
- 페이지 reload 시 해시를 읽어 자동으로 해당 모드 슬라이더 재시작 (선택 화면으로 돌아가지 않음)
- 따라서 이미지 교체, 코드 변경 등 어떤 배포든 사이니지 조작 없이 자동 반영됨

## 이미지 변경 방법
1. `src/images/vertical/` 또는 `src/images/horizontal/`에 이미지 추가/교체
2. `src/script.js`의 `IMAGE_LIST`에 파일명 반영
3. 커밋 → 푸시 → 배포하면 사이니지가 자동 갱신

## 실행 방법
- `src/index.html`을 브라우저에서 열기
- 또는 Live Server 등으로 로컬 서버 실행

## 컨벤션
- 한국어 주석 사용
- 파일명은 영문 소문자, 케밥 케이스
- `index.html`의 CSS/JS 참조에 `?v=N` 캐시 버스팅 포함 — 코드 변경 시 번호를 올릴 것

<!-- doc-sync plugin: do not edit manually -->
- 코드 작성 시 어쩔 수 없는 트레이드오프는 docs/quirks.md에 기록
- 작업 완료 후 /doc-sync 업데이트 여부 판단
- 문서에 없는 정보를 발견하면 코드를 직접 읽고 추론 후 즉시 문서에 기록
- 문서를 맹신하지 말 것. human verified 날짜를 보고 신뢰도를 스스로 판단
- 섹션이 비어있으면 코드에서 추론하되, 불확실하면 작업 완료 후 개발자에게 확인 요청
- 외부 파일 참조는 상대 경로로만 작성 (브랜치 머지 안전)
- 모듈 추가·제거 시 해당 module.md와 REPO_CONTEXT.md의 Project Structure 표를 함께 갱신
<!-- /doc-sync plugin -->
