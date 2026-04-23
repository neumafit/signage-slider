---
repo: signage-slider
service: signage-slider
module: web
summary: 사이니지에서 실제 동작하는 이미지 슬라이더 정적 웹 앱. 세로형/가로형 선택 → 20초 간격 자동 슬라이드 → 한 바퀴마다 version.json 폴링으로 배포 감지 → 자동 reload.
---

# web

## 한 줄 설명
무인매장 대형 TV용 이미지 슬라이더. 세로형/가로형 선택 후 PNG 이미지를 20초 간격으로 자동 전환하며, 슬라이드 한 바퀴마다 배포 버전을 폴링해 변경 시 자체적으로 새로고침한다.

## 핵심 파일
이 모듈의 진입점과 주요 구현 위치.

| 파일 | 역할 |
|---|---|
| [src/index.html](../../src/index.html) | 진입점. 선택 화면과 슬라이더 화면(숨김)을 동시 포함. CSS/JS는 `?v=N` 쿼리로 캐시 버스팅 |
| [src/script.js](../../src/script.js) | `IMAGE_LIST`, `SLIDE_INTERVAL`, `startSlider`, `nextSlide`, `checkVersion` — 전체 런타임 로직 |
| [src/style.css](../../src/style.css) | 전체화면 레이아웃, 슬라이더 transition 및 선택 버튼 스타일 |
| [src/images/vertical/](../../src/images/vertical/) | 세로형 PNG 리스트 (현재 5장, 3840x2160 가정) |
| [src/images/horizontal/](../../src/images/horizontal/) | 가로형 PNG 리스트 (현재 5장, 3840x2160 가정) |

## 주요 흐름
페이지가 로드된 후 사용자는 한 번만 조작한다 (모드 선택). 이후는 무한 반복 + 자동 갱신으로 돌아간다.

1. `checkVersion()` 최초 호출 — `version.json`을 받아 현재 버전을 기억한다 (비교는 하지 않음).
2. URL 해시에 `#vertical` 또는 `#horizontal`이 있으면 해당 모드로 자동 시작 (reload 복귀 경로).
3. 해시가 없으면 선택 화면 표시. 사용자가 버튼 클릭 → `startSlider(mode)`.
4. `startSlider`는 `history.pushState` 후 `IMAGE_LIST[mode]`를 트랙에 삽입하고 맨 앞 이미지를 끝에 **복제**(무한 루프용)한다. `setInterval`로 20초마다 `nextSlide` 호출.
5. `nextSlide`는 CSS transition `transform: translateX(-N*100vw)`로 다음 이미지를 보여주고, 마지막 복제 이미지 도달 시 transition을 끄고 `translateX(0)`으로 순간 이동 (`setTimeout(..., 1000)`).
6. 한 바퀴 돌 때마다(`currentIndex === totalImages` 시점) `checkVersion()` 재호출.
7. `checkVersion`이 버전 차이를 감지하면 현재 모드를 `location.hash`에 기록하고 `location.reload()`.
8. 브라우저 뒤로가기(사이니지에서는 드물지만 개발 중 유용) → `popstate` 핸들러가 타이머 정리 후 선택 화면 복귀.

## 외부 인터페이스
이 모듈은 외부 서비스에 프로그래밍 인터페이스를 노출하지 않는다. 런타임 접점은 다음 네트워크 경로뿐.

| 종류 | 시그니처 | 용도 |
|---|---|---|
| HTTP GET | `GET /index.html` | 진입점 (CloudFront 서빙) |
| HTTP GET | `GET /style.css?v=N`, `GET /script.js?v=N` | 에셋 로드. `N`은 HTML에 하드코딩됨 (현재 `v=12`) |
| HTTP GET | `GET /images/{mode}/*.png` | 이미지 로드 |
| HTTP GET | `GET /version.json?t={Date.now()}` | 배포 감지용 폴링. `?t=`로 캐시 우회 |
| URL hash | `#vertical` / `#horizontal` | reload 후 모드 복귀 |

## 의존 관계
- **내부**: 없음. `src/` 내부 세 파일(HTML/CSS/JS)만으로 완결.
- **외부**:
  - CloudFront/S3 (`signage-slider.neumafit.com`) — 배포 대상이자 런타임 서빙자.
  - `version.json` — GitHub Actions가 배포 때마다 생성해 S3로 올림 (→ [docs/modules/deploy.md](./deploy.md)).
  - 런타임에 Neumafit 내 다른 서비스를 호출하지 않는다.

## Domain Knowledge
- "세로형/가로형" = 대형 TV 설치 방향. 각 모드는 서로 다른 이미지 세트(파일명·레이아웃 다름)를 쓴다.
- 이미지 파일명의 파트너 약어(`jambaekee`, `jeleve` 등) 의미는 [../domain.md](../domain.md) 참조.
- 자세한 용어/규칙은 [../domain.md](../domain.md).

## Known Quirks
이 모듈에서 건드리면 장애 가능성이 있는 부분은 [../quirks.md](../quirks.md)의 "캐시 버스팅 쿼리", "스냅백 타이밍 CSS·JS 동기화", "무한 루프 복제 이미지" 항목 참조.
