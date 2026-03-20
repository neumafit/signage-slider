# Signage Slider

## 프로젝트 개요
디지털 사이니지용 이미지 슬라이더 웹 애플리케이션.
시작 화면에서 세로형/가로형을 선택하면, `images/` 폴더의 PNG 이미지들이 20초 간격으로 자동 슬라이드되며 무한 반복된다.

## 기술 스택
- **순수 HTML/CSS/JavaScript** (프레임워크 없음)
- 별도 빌드 도구 없음 — 브라우저에서 직접 `index.html`을 열어 실행

## 프로젝트 구조
```
index.html          # 메인 페이지 (선택 화면 + 슬라이더)
style.css           # 스타일시트
script.js           # 슬라이더 로직
images/
  vertical/         # 세로형 이미지 (PNG)
  horizontal/       # 가로형 이미지 (PNG)
```

## 실행 방법
- `index.html`을 브라우저에서 열기
- 또는 Live Server 등으로 로컬 서버 실행

## 컨벤션
- 한국어 주석 사용
- 파일명은 영문 소문자, 케밥 케이스
