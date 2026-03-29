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

## 배포
- **태그 푸시**: `git tag -f prd/web && git push origin prd/web -f` → GitHub Actions 트리거
- **수동 트리거**: `gh workflow run deploy.yml -f environment=prd`
- 배포 시 `version.json`이 커밋 해시로 자동 생성됨

## 자동 갱신 (version.json)
- 배포마다 GitHub Actions가 `version.json`에 커밋 해시를 기록
- 사이니지의 슬라이더는 슬라이드 한 바퀴(~80초)마다 `version.json`을 fetch
- 버전이 바뀌면 `location.reload()`로 자동 새로고침
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
