// 이미지 목록 설정
const IMAGE_LIST = {
  vertical: [
    'images/vertical/3840x2160 - 1.png',
    'images/vertical/3840x2160 - 2.png',
    'images/vertical/3840x2160-3-neumafit.png',
    'images/vertical/3840x2160-4-jambaekee.png',
    'images/vertical/3840x2160-5-jeleve.png',
  ],
  horizontal: [
    'images/horizontal/3840x2160 - 1.png',
    'images/horizontal/3840x2160 - 2.png',
    'images/horizontal/3840x2160-3-neumafit.png',
    'images/horizontal/3840x2160-4-jambaekee.png',
    'images/horizontal/3840x2160-5-jeleve.png',
  ],
};

const SLIDE_INTERVAL = 20000; // 20초

let currentIndex = 0;
let timer = null;
let currentMode = null;
let knownVersion = null;

// 배포 버전 확인 (슬라이드 한 바퀴마다 호출)
function checkVersion() {
  fetch('version.json?t=' + Date.now())
    .then(function (res) { return res.json(); })
    .then(function (data) {
      if (knownVersion === null) {
        // 최초 로드 시 버전 기록
        knownVersion = data.version;
      } else if (data.version !== knownVersion) {
        // 버전 변경 감지 → 현재 모드를 해시에 저장 후 새로고침
        if (currentMode) {
          location.hash = currentMode;
        }
        location.reload();
      }
    })
    .catch(function () {});
}

// 페이지 로드 시 현재 버전 기록
checkVersion();

// 해시에 모드가 있으면 자동 시작 (버전 갱신 후 복귀)
(function () {
  var hash = location.hash.replace('#', '');
  if (hash === 'vertical' || hash === 'horizontal') {
    startSlider(hash);
  }
})();

function startSlider(mode) {
  currentMode = mode;
  var images = IMAGE_LIST[mode];
  if (images.length === 0) {
    alert('이미지가 없습니다. images/' + mode + '/ 폴더에 이미지를 넣어주세요.');
    return;
  }

  // 브라우저 히스토리에 상태 추가
  history.pushState({ screen: 'slider' }, '');

  // 화면 전환
  document.getElementById('select-screen').classList.add('hidden');
  document.getElementById('slider-screen').classList.remove('hidden');

  // 슬라이더 트랙에 이미지 삽입 (무한 루프를 위해 첫 이미지를 끝에 복제)
  var track = document.getElementById('slider-track');
  track.innerHTML = '';

  images.forEach(function (src) {
    var img = document.createElement('img');
    img.src = src;
    img.alt = '';
    track.appendChild(img);
  });

  var cloneImg = document.createElement('img');
  cloneImg.src = images[0];
  cloneImg.alt = '';
  track.appendChild(cloneImg);

  currentIndex = 0;
  track.style.transform = 'translateX(0)';

  // 자동 슬라이드 시작
  timer = setInterval(function () {
    nextSlide(images.length);
  }, SLIDE_INTERVAL);
}

function nextSlide(totalImages) {
  var track = document.getElementById('slider-track');
  currentIndex++;

  // 슬라이드 애니메이션
  track.style.transition = 'transform 1s ease-in-out';
  track.style.transform = 'translateX(-' + (currentIndex * 100) + 'vw)';

  // 마지막 복제 슬라이드에 도달하면 첫 슬라이드로 순간 이동
  if (currentIndex === totalImages) {
    setTimeout(function () {
      track.style.transition = 'none';
      currentIndex = 0;
      track.style.transform = 'translateX(0)';
    }, 1000);

    // 한 바퀴 돌았을 때 배포 버전 확인
    checkVersion();
  }
}

// 브라우저 뒤로가기로 선택 화면 복귀
window.addEventListener('popstate', function () {
  if (timer) {
    clearInterval(timer);
    timer = null;
  }
  currentIndex = 0;
  var track = document.getElementById('slider-track');
  track.style.transition = 'none';
  track.style.transform = 'translateX(0)';
  track.innerHTML = '';

  document.getElementById('slider-screen').classList.add('hidden');
  document.getElementById('select-screen').classList.remove('hidden');
});
