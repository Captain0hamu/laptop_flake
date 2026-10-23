(() => {
  'use strict';
  const data = window.NIX_SHOWCASE;
  if (!data) return;
  const $ = selector => document.querySelector(selector);
  const $$ = selector => [...document.querySelectorAll(selector)];

  const stages = {
    grub: {
      tag: '01 / SYSTEM SELECTION',
      eyebrow: '01 / GRUB',
      title: 'Choose your entry point.',
      text: 'Grand Theft Gentoo artwork, BankGothic type, and a cool-blue selection. A small GRUB patch keeps the selected menu visible until the kernel takes over. Menu entries here are examples.',
      sources: ['modules/nixos/bootloader.nix', 'files/grub/keep-menu-on-boot.patch']
    },
    plymouth: {
      tag: '02 / BOOT SPLASH',
      eyebrow: '02 / PLYMOUTH',
      title: 'Even the wait has a soundtrack.',
      text: 'A custom Plymouth theme with a radio panel, spinning vinyl, hints, and a progress bar. This recreation layers a browser-rendered HUD over the actual generated background.',
      sources: ['modules/nixos/plymouth.nix', 'files/plymouth/gtg/gtg.script']
    },
    sddm: {
      tag: '03 / LOGIN',
      eyebrow: '03 / SDDM',
      title: 'Still frames. Moving atmosphere.',
      text: `${data.frames.length} crossfading frames. Slow pans and zooms, scanlines, and a radio HUD, built in QML. BankGothic ties the login screen to the rest of the boot sequence. The same frames return on the lock and splash screens.`,
      sources: [
        'files/sddm/Gently-Blur-SDDM-6/AnimatedBackground.qml',
        'files/sddm/Gently-Blur-SDDM-6/Main.qml',
        'files/sddm/Gently-Blur-SDDM-6/IntroOverlay.qml',
        'files/sddm/Gently-Blur-SDDM-6/SplashHud.qml'
      ]
    },
    shared: {
      tag: '04 / LOCK + SPLASH',
      eyebrow: '04 / SHARED SCENE',
      title: 'One scene. Three surfaces.',
      text: 'SDDM hands off to the Plasma lock screen and KSplash. A 24 px blur, a 0.32 veil, and the same clock keep the scene continuous. Native authentication, fingerprint, and session controls stay in Plasma\'s hands.',
      sources: [
        'files/plasma/SharedScene.qml',
        'files/plasma/Splash.qml',
        'files/plasma/patch-lockscreen.py',
        'modules/nixos/plasma-customisation.nix',
        'home/plasma.nix'
      ]
    },
    desktop: {
      tag: '05 / PLASMA',
      eyebrow: '05 / PLASMA',
      title: 'The scene hands over.',
      text: 'The shared scene scales into the session. In this browser it becomes a title card; in Plasma, the same 850 ms zoom reveals the desktop.',
      sources: ['home/plasma.nix', 'files/plasma/Splash.qml']
    }
  };

  // Every entry is a chapter on the timeline. Shared mode splits the lock and
  // splash half of the scene without adding another stage tab.
  const sequence = [
    { stage: 'grub', start: 0, end: 2.2, label: 'GRUB' },
    { stage: 'plymouth', start: 2.2, end: 5.4, label: 'Plymouth' },
    { stage: 'sddm', start: 5.4, end: 9, label: 'SDDM' },
    { stage: 'shared', mode: 'lock', start: 9, end: 11.5, label: 'Lock / splash' },
    { stage: 'shared', mode: 'splash', start: 11.5, end: 13.5 },
    { stage: 'desktop', start: 13.5, end: 15.2, label: 'Plasma' }
  ];
  const total = sequence[sequence.length - 1].end;
  const stageStart = name => sequence.find(segment => segment.stage === name)?.start ?? 0;
  const segmentAt = time => sequence.find(segment => time < segment.end) || sequence[sequence.length - 1];

  let stage = 'grub';
  let sharedMode = 'lock';
  let sequenceTime = 0;
  let sequencePlaying = false;
  let playStartedAt = 0;
  const motionPreference = matchMedia('(prefers-reduced-motion: reduce)');
  let paused = motionPreference.matches;
  let index = 0, front = $('#frame-a'), back = $('#frame-b');
  let last = performance.now(), introTimer, transitioning = false;
  const url = name => `../files/sddm/Gently-Blur-SDDM-6/anim/${name}`;
  front.src = url(data.frames[0]);
  back.src = url(data.frames[1 % data.frames.length]);

  const player = $('#sequence-play');
  const scrub = $('#sequence-scrub');
  const fill = $('#sequence-fill');
  const clock = $('#sequence-clock');
  const loginScene = $('.login-scene');
  const sharedSceneChrome = $('#shared-chrome');
  const track = $('#sequence-track');
  const marks = $('#sequence-marks');
  let unlockTimer;

  const timeFormat = new Intl.DateTimeFormat('en-GB', { hour: '2-digit', minute: '2-digit', hour12: false });
  const dateFormat = new Intl.DateTimeFormat('en-GB', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' });
  function updateClock() {
    const now = new Date();
    $('#shared-time').textContent = timeFormat.format(now);
    $('#shared-date').textContent = dateFormat.format(now);
  }
  updateClock();
  setInterval(updateClock, 30000);

  function formatTime(value) {
    const seconds = Math.max(0, Math.round(value));
    return `${String(Math.floor(seconds / 60)).padStart(2, '0')}:${String(seconds % 60).padStart(2, '0')}`;
  }

  function buildTimeline() {
    if (track) {
      track.replaceChildren(...sequence.map(segment => {
        const bar = document.createElement('i');
        bar.style.flex = String(segment.end - segment.start);
        return bar;
      }));
    }
    if (marks) {
      marks.replaceChildren(...sequence.filter(segment => segment.label).map(segment => {
        const mark = document.createElement('span');
        mark.style.left = `${(segment.start / total) * 100}%`;
        mark.textContent = segment.label;
        return mark;
      }));
    }
    scrub.max = String(total);
    scrub.step = '0.05';
  }

  function setPlayButton() {
    const atEnd = sequenceTime >= total - 0.05;
    player.classList.toggle('playing', sequencePlaying);
    player.querySelector('span').textContent = sequencePlaying ? 'Ⅱ' : atEnd ? '↺' : '▶';
    player.setAttribute('aria-label', sequencePlaying ? 'Pause boot sequence' : atEnd ? 'Replay boot sequence' : 'Play boot sequence');
  }

  function cancelUnlock() {
    clearTimeout(unlockTimer);
    loginScene.classList.remove('entering');
  }

  function updateTimeline() {
    const progress = (sequenceTime / total) * 100;
    scrub.value = String(sequenceTime);
    fill.style.setProperty('--sequence-progress', `${progress}%`);
    clock.textContent = `${formatTime(sequenceTime)} / ${formatTime(total)}`;
    const segment = segmentAt(sequenceTime);
    const label = segment.stage === 'shared'
      ? `Shared scene, ${segment.mode === 'splash' ? 'splash' : 'lock screen'}`
      : stages[segment.stage]?.tag.split(' / ')[1] || segment.stage;
    scrub.setAttribute('aria-valuetext', `${label}, ${formatTime(sequenceTime)} of ${formatTime(total)}`);
  }

  function refreshSharedUi() {
    $$('[data-shared-mode]').forEach(button => {
      const active = button.dataset.sharedMode === sharedMode;
      button.setAttribute('aria-pressed', String(active));
      button.classList.toggle('selected', active);
    });
    $('#shared-lock').hidden = sharedMode !== 'lock';
    $('#shared-splash').hidden = sharedMode !== 'splash';
    if (stage === 'shared') {
      $('#scene-corner').textContent = `SHARED SCENE / ${sharedMode.toUpperCase()}`;
    }
  }

  function renderStage(name, { silent = false } = {}) {
    stage = name;
    last = performance.now();
    const sceneName = name === 'shared' ? 'sddm' : name;
    $$('[data-scene]').forEach(node => { node.hidden = node.dataset.scene !== sceneName; });
    loginScene.classList.toggle('shared-mode', name === 'shared');
    loginScene.classList.remove('entering');
    $('#login-radio').hidden = name !== 'sddm';
    $('#login-form').hidden = name !== 'sddm';
    sharedSceneChrome.hidden = name !== 'shared';
    refreshSharedUi();

    $$('[data-stage]').forEach(button => {
      const active = button.dataset.stage === name;
      button.setAttribute('aria-pressed', String(active));
      button.classList.toggle('selected', active);
    });

    const details = stages[name] || stages.sddm;
    $('#scene-tag').textContent = details.tag;
    $('#stage-eyebrow').textContent = details.eyebrow;
    $('#stage-title').textContent = details.title;
    $('#stage-description').textContent = details.text;
    $('#stage-links').replaceChildren(...details.sources.map(path => {
      const button = document.createElement('button');
      button.dataset.source = path;
      button.textContent = `${path.split('/').pop()} ↗`;
      return button;
    }));
    $('#replay-intro').hidden = name !== 'sddm';
    $('#intro-overlay').hidden = true;
    clearTimeout(introTimer);
    if (name === 'sddm') $('#scene-corner').textContent = '26 FRAMES / PAN / CROSSFADE';

    if (!silent && !paused && !motionPreference.matches) {
      $('#display').animate([
        { clipPath: 'inset(0 0 100% 0)', transform: 'scale(1.035)' },
        { clipPath: 'inset(0 0 0 0)', transform: 'scale(1)' }
      ], { duration: 700, easing: 'cubic-bezier(.16,1,.3,1)' });
    }
  }

  function selectStage(name, { silent = false } = {}) {
    cancelUnlock();
    if (name === 'shared') sharedMode = 'lock';
    renderStage(name, { silent });
    sequenceTime = stageStart(name);
    updateTimeline();
    setPlayButton();
  }

  function setSharedMode(mode) {
    cancelUnlock();
    sharedMode = mode === 'splash' ? 'splash' : 'lock';
    refreshSharedUi();
    if (stage === 'shared') {
      sequenceTime = sequence.find(segment => segment.stage === 'shared' && segment.mode === sharedMode)?.start ?? stageStart('shared');
      updateTimeline();
    }
  }

  function setTime(value, { silent = false } = {}) {
    sequenceTime = Math.min(total, Math.max(0, value));
    const segment = segmentAt(sequenceTime);
    if (segment.stage === 'shared' && segment.mode) sharedMode = segment.mode;
    if (segment.stage !== stage) {
      renderStage(segment.stage, { silent });
    } else if (segment.stage === 'shared') {
      refreshSharedUi();
    }
    updateTimeline();
    setPlayButton();
  }

  function playSequence() {
    if (sequencePlaying) return;
    cancelUnlock();
    if (sequenceTime >= total - 0.05) {
      sequenceTime = 0;
      setTime(0, { silent: true });
    }
    sequencePlaying = true;
    playStartedAt = performance.now() - sequenceTime * 1000;
    setPlayButton();
    requestAnimationFrame(advanceSequence);
  }

  function pauseSequence() {
    if (!sequencePlaying) return;
    sequencePlaying = false;
    setPlayButton();
  }

  function advanceSequence(now) {
    if (!sequencePlaying) return;
    sequenceTime = (now - playStartedAt) / 1000;
    if (sequenceTime >= total) {
      sequenceTime = total;
      setTime(total);
      pauseSequence();
      return;
    }
    setTime(sequenceTime);
    requestAnimationFrame(advanceSequence);
  }

  function setMotion() {
    document.body.classList.toggle('motion-off', paused);
    $('#motion-toggle').setAttribute('aria-pressed', String(paused));
    $('#motion-toggle').textContent = paused ? '▶ Resume motion' : 'Ⅱ Pause motion';
    $('#page-motion-toggle').setAttribute('aria-pressed', String(paused));
    $('#page-motion-toggle').textContent = paused ? 'Resume motion' : 'Pause motion';
    if (paused) pauseSequence();
  }

  buildTimeline();
  renderStage('grub', { silent: true });
  updateTimeline();
  setPlayButton();
  setMotion();

  // Deep link into a chapter, e.g. showcase.html?stage=shared&mode=splash.
  const params = new URLSearchParams(location.search);
  const requestedStage = params.get('stage');
  if (requestedStage && stages[requestedStage]) {
    selectStage(requestedStage, { silent: true });
    if (requestedStage === 'shared' && params.get('mode') === 'splash') setSharedMode('splash');
    requestAnimationFrame(() => {
      const root = document.documentElement;
      const previous = root.style.scrollBehavior;
      root.style.scrollBehavior = 'auto';
      $('#sequence-viewer').scrollIntoView({ block: 'start' });
      root.style.scrollBehavior = previous;
    });
  }

  const tracks = ['emerge --sync', 'have you tried rebooting?', 'GNU is Not Unix', "it's always DNS"];
  const loop = now => {
    if (!paused && !document.hidden && !transitioning && (stage === 'sddm' || stage === 'shared') && now - last >= data.duration) {
      last = now;
      // Wait for the incoming frame so a slow disk never fades to an empty image.
      if (back.complete && back.naturalWidth) {
        transitioning = true;
        front.classList.remove('active'); back.classList.add('active');
        [front, back] = [back, front]; index = (index + 1) % data.frames.length;
        const next = data.frames[(index + 1) % data.frames.length];
        const retired = back;
        // Keep both images intact for the full fade before preparing the next one.
        setTimeout(() => { retired.src = url(next); transitioning = false; }, data.duration + 20);
        $('#radio-track').textContent = `♪ ${tracks[Math.floor(index / 7) % tracks.length]}`;
      }
    }
    requestAnimationFrame(loop);
  };
  requestAnimationFrame(loop);

  function setPaused(next) {
    paused = next;
    last = performance.now();
    setMotion();
    updateScroll();
  }
  motionPreference.addEventListener('change', event => setPaused(event.matches));
  $('#motion-toggle').addEventListener('click', () => setPaused(!paused));
  $('#page-motion-toggle').addEventListener('click', () => setPaused(!paused));

  $$('[data-stage]').forEach(button => {
    button.addEventListener('click', () => {
      pauseSequence();
      selectStage(button.dataset.stage);
    });
    button.addEventListener('keydown', event => {
      const buttons = $$('[data-stage]');
      const current = buttons.indexOf(button);
      const nextIndex = event.key === 'Home' ? 0
        : event.key === 'End' ? buttons.length - 1
        : event.key === 'ArrowRight' ? (current + 1) % buttons.length
        : event.key === 'ArrowLeft' ? (current - 1 + buttons.length) % buttons.length
        : -1;
      if (nextIndex < 0) return;
      event.preventDefault();
      const next = buttons[nextIndex];
      next.focus();
      next.click();
    });
  });

  $$('[data-shared-mode]').forEach(button => {
    button.addEventListener('click', () => {
      pauseSequence();
      setSharedMode(button.dataset.sharedMode);
    });
  });

  player.addEventListener('click', () => {
    if (sequencePlaying) pauseSequence();
    else playSequence();
  });
  scrub.addEventListener('input', () => {
    pauseSequence();
    cancelUnlock();
    setTime(Number(scrub.value), { silent: true });
  });
  document.addEventListener('visibilitychange', () => { if (document.hidden) pauseSequence(); });

  $('#replay-intro').addEventListener('click', () => {
    const overlay = $('#intro-overlay'); clearTimeout(introTimer);
    overlay.hidden = false; overlay.style.animation = 'none'; void overlay.offsetWidth; overlay.style.animation = '';
    introTimer = setTimeout(() => { overlay.hidden = true; }, paused ? 2400 : 3200);
  });

  $('#shared-unlock').addEventListener('click', () => {
    if (stage !== 'shared' || loginScene.classList.contains('entering')) return;
    cancelUnlock();
    pauseSequence();
    loginScene.classList.add('entering');
    const duration = paused || motionPreference.matches ? 0 : 850;
    unlockTimer = setTimeout(() => {
      loginScene.classList.remove('entering');
      renderStage('desktop');
      sequenceTime = total;
      updateTimeline();
      setPlayButton();
    }, duration);
  });

  const toolTabs = $$('[data-tool]');
  function selectTool(button) {
    const editor = button.dataset.tool === 'editor';
    $('#fetch-demo').hidden = editor; $('#editor-demo').hidden = !editor;
    $('#terminal-command').textContent = editor ? 'nvim home/neovim.nix' : 'ff';
    toolTabs.forEach(node => {
      const selected = node === button;
      node.setAttribute('aria-selected', String(selected));
      node.tabIndex = selected ? 0 : -1;
    });
  }
  toolTabs.forEach((button, tabIndex) => {
    button.addEventListener('click', () => selectTool(button));
    button.addEventListener('keydown', event => {
      const offsets = { ArrowRight: 1, ArrowLeft: -1, Home: -tabIndex, End: toolTabs.length - 1 - tabIndex };
      if (!(event.key in offsets)) return;
      event.preventDefault();
      const next = toolTabs[(tabIndex + offsets[event.key] + toolTabs.length) % toolTabs.length];
      selectTool(next); next.focus();
    });
  });

  const dialog = $('#source-dialog'); let lastTrigger;
  document.addEventListener('click', event => {
    const button = event.target.closest('[data-source]'); if (!button) return;
    const code = data.sources[button.dataset.source]; if (code === undefined) return;
    lastTrigger = button;
    $('#source-title').textContent = button.dataset.source; $('#source-code').textContent = code;
    $('#copy-source').textContent = 'Copy'; dialog.showModal();
    dialog.querySelector('pre').scrollTop = 0;
  });
  $('#close-source').addEventListener('click', () => dialog.close());
  dialog.addEventListener('close', () => lastTrigger?.focus());
  dialog.addEventListener('click', event => {
    if (event.target === dialog) {
      const box = dialog.getBoundingClientRect();
      if (event.clientX < box.left || event.clientX > box.right || event.clientY < box.top || event.clientY > box.bottom) dialog.close();
    }
  });
  $('#copy-source').addEventListener('click', async () => {
    try { await navigator.clipboard.writeText($('#source-code').textContent); $('#copy-source').textContent = 'Copied'; }
    catch { const selection = getSelection(), range = document.createRange(); range.selectNodeContents($('#source-code')); selection.removeAllRanges(); selection.addRange(range); $('#copy-source').textContent = 'Selected · Ctrl/Cmd+C'; }
  });

  // Only the photograph follows scrolling; no scroll hijacking or pointer tracking.
  const photograph = $('.hero-capture');
  let scrollQueued = false;
  function updateScroll() {
    scrollQueued = false;
    const progress = Math.min(1, Math.max(0, scrollY / Math.max(1, $('.intro').offsetHeight)));
    photograph.style.setProperty('--scroll', paused || motionPreference.matches ? 0 : progress);
  }
  addEventListener('scroll', () => {
    if (!scrollQueued) { scrollQueued = true; requestAnimationFrame(updateScroll); }
  }, { passive: true });
  addEventListener('resize', updateScroll);
  updateScroll();
  if ('IntersectionObserver' in window) {
    const observer = new IntersectionObserver(entries => {
      entries.forEach(entry => {
        if (!entry.isIntersecting) return;
        entry.target.classList.add('section-in-view');
        observer.unobserve(entry.target);
      });
    }, { threshold: .1 });
    $$('.workspace, .sequence').forEach(section => observer.observe(section));
  }
})();
