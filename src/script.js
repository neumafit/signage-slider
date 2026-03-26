// 전체 이미지 목록 (모든 이미지 포함)
const ALL_IMAGES = {
  vertical: [
    'images/vertical/3840x2160 - 1.png',
    'images/vertical/3840x2160 - 2.png',
    'images/vertical/3840x2160 - 3.png',
    'images/vertical/3840x2160 - 4.png',
  ],
  horizontal: [
    'images/horizontal/3840x2160 - 1.png',
    'images/horizontal/3840x2160 - 2.png',
    'images/horizontal/3840x2160 - 3.png',
    'images/horizontal/3840x2160 - 4.png',
    'images/horizontal/3840x2160 - 5.png',
  ],
};

// localStorage에서 비활성화된 이미지 목록 불러오기
function getDisabledImages() {
  try {
    return JSON.parse(localStorage.getItem('disabledImages')) || [];
  } catch (e) {
    return [];
  }
}

function setDisabledImages(list) {
  localStorage.setItem('disabledImages', JSON.stringify(list));
}

// 활성화된 이미지만 반환
function getActiveImages(mode) {
  var disabled = getDisabledImages();
  return ALL_IMAGES[mode].filter(function (src) {
    return disabled.indexOf(src) === -1;
  });
}

const SLIDE_INTERVAL = 20000; // 20초

let currentIndex = 0;
let timer = null;

function startSlider(mode) {
  var images = getActiveImages(mode);
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
  const track = document.getElementById('slider-track');
  track.innerHTML = '';

  images.forEach(function (src) {
    const img = document.createElement('img');
    img.src = src;
    img.alt = '';
    track.appendChild(img);
  });

  // 무한 루프용: 첫 번째 이미지를 끝에 복제
  const cloneImg = document.createElement('img');
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
  const track = document.getElementById('slider-track');
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
    }, 1000); // 애니메이션 완료 후
  }
}

// 오른쪽 모서리 5회 클릭으로 설정 패널 열기
(function () {
  var tapCount = 0;
  var tapTimer = null;
  var tapArea = document.getElementById('secret-tap-area');

  tapArea.addEventListener('click', function (e) {
    e.stopPropagation();
    tapCount++;
    if (tapTimer) clearTimeout(tapTimer);

    if (tapCount >= 5) {
      tapCount = 0;
      openSettings();
    } else {
      // 5초 내로 5회 클릭해야 함
      tapTimer = setTimeout(function () {
        tapCount = 0;
      }, 5000);
    }
  });
})();

// 설정 패널 열기
function openSettings() {
  var panel = document.getElementById('settings-panel');
  panel.classList.remove('hidden');
  renderToggleList('vertical');
  renderToggleList('horizontal');
}

// 설정 패널 닫기
function closeSettings() {
  document.getElementById('settings-panel').classList.add('hidden');
}

// 토글 목록 렌더링
function renderToggleList(mode) {
  var container = document.getElementById('toggle-list-' + mode);
  var disabled = getDisabledImages();
  container.innerHTML = '';

  ALL_IMAGES[mode].forEach(function (src) {
    var isActive = disabled.indexOf(src) === -1;
    // 파일명만 추출하여 표시
    var fileName = src.split('/').pop();

    var item = document.createElement('div');
    item.className = 'toggle-item';

    var label = document.createElement('span');
    label.className = 'toggle-label';
    label.textContent = fileName;

    var toggle = document.createElement('button');
    toggle.className = 'toggle-btn ' + (isActive ? 'active' : 'inactive');
    toggle.textContent = isActive ? 'ON' : 'OFF';
    toggle.addEventListener('click', function () {
      var currentDisabled = getDisabledImages();
      var idx = currentDisabled.indexOf(src);
      if (idx === -1) {
        currentDisabled.push(src);
      } else {
        currentDisabled.splice(idx, 1);
      }
      setDisabledImages(currentDisabled);
      renderToggleList(mode);
    });

    item.appendChild(label);
    item.appendChild(toggle);
    container.appendChild(item);
  });
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
