(() => {
  'use strict';
  const data = window.NIX_SHOWCASE;
  if (!data) return;
  const $ = selector => document.querySelector(selector);
  const $$ = selector => [...document.querySelectorAll(selector)];
  const stages = {
    grub: { tag: '01 / SYSTEM SELECTION', title: 'Choose your entry point.', text: 'Grand Theft Gentoo artwork, BankGothic type, and a cool-blue selection. A small GRUB patch keeps the selected menu visible until the kernel takes over. Menu entries here are examples.', sources: ['modules/nixos/bootloader.nix', 'files/grub/keep-menu-on-boot.patch'] },
    plymouth: { tag: '02 / BOOT SPLASH', title: 'Even the wait has a soundtrack.', text: 'A custom Plymouth theme with a radio panel, spinning vinyl, hints, and a progress bar. This recreation layers a browser-rendered HUD over the actual generated background.', sources: ['modules/nixos/plymouth.nix', 'files/plymouth/gtg/gtg.script'] },
    sddm: { tag: '03 / LOGIN', title: 'Still frames. Moving atmosphere.', text: `${data.frames.length} crossfading frames. Slow pans and zooms, scanlines, and a radio HUD, built in QML. BankGothic ties the login screen to the rest of the boot sequence.`, sources: ['files/sddm/Gently-Blur-SDDM-6/AnimatedBackground.qml', 'files/sddm/Gently-Blur-SDDM-6/IntroOverlay.qml', 'files/sddm/Gently-Blur-SDDM-6/SplashHud.qml'] }
  };
  let stage = 'sddm';
  const motionPreference = matchMedia('(prefers-reduced-motion: reduce)');
  let paused = motionPreference.matches;
  let index = 0, front = $('#frame-a'), back = $('#frame-b');
  let last = performance.now(), introTimer, transitioning = false;
  const url = name => `../files/sddm/Gently-Blur-SDDM-6/anim/${name}`;
  front.src = url(data.frames[0]);
  back.src = url(data.frames[1 % data.frames.length]);
  const tracks = ['emerge --sync', 'have you tried rebooting?', 'GNU is Not Unix', "it's always DNS"];
  const loop = now => {
    if (!paused && !document.hidden && !transitioning && stage === 'sddm' && now - last >= data.duration) {
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
  function setMotion() {
    document.body.classList.toggle('motion-off', paused);
    $('#motion-toggle').setAttribute('aria-pressed', String(paused));
    $('#motion-toggle').textContent = paused ? '▶ Resume motion' : 'Ⅱ Pause motion';
    $('#page-motion-toggle').setAttribute('aria-pressed', String(paused));
    $('#page-motion-toggle').textContent = paused ? 'Resume motion' : 'Pause motion';
  }
  setMotion();
  motionPreference.addEventListener('change', event => { paused = event.matches; last = performance.now(); setMotion(); });
  $('#motion-toggle').addEventListener('click', () => { paused = !paused; last = performance.now(); setMotion(); });
  $('#page-motion-toggle').addEventListener('click', () => { paused = !paused; last = performance.now(); setMotion(); });
  function selectStage(name) {
    stage = name; last = performance.now();
    $$('[data-scene]').forEach(node => { node.hidden = node.dataset.scene !== name; });
    $$('[data-stage]').forEach(button => { const active = button.dataset.stage === name; button.setAttribute('aria-pressed', String(active)); button.classList.toggle('selected', active); });
    const details = stages[name];
    $('#scene-tag').textContent = details.tag;
    $('#stage-eyebrow').textContent = name === 'sddm' ? '03 / SDDM' : details.tag;
    $('#stage-title').textContent = details.title;
    $('#stage-description').textContent = details.text;
    $('#stage-links').replaceChildren(...details.sources.map(path => { const button = document.createElement('button'); button.dataset.source = path; button.textContent = `${path.split('/').pop()} ↗`; return button; }));
    $('#replay-intro').hidden = name !== 'sddm';
    $('#intro-overlay').hidden = true;
    if (!paused && !motionPreference.matches) {
      $('#display').animate([
        { clipPath: 'inset(0 0 100% 0)', transform: 'scale(1.035)' },
        { clipPath: 'inset(0 0 0 0)', transform: 'scale(1)' }
      ], { duration: 700, easing: 'cubic-bezier(.16,1,.3,1)' });
    }
  }
  $$('[data-stage]').forEach(button => button.addEventListener('click', () => selectStage(button.dataset.stage)));
  selectStage('sddm');
  $('#replay-intro').addEventListener('click', () => {
    const overlay = $('#intro-overlay'); clearTimeout(introTimer);
    overlay.hidden = false; overlay.style.animation = 'none'; void overlay.offsetWidth; overlay.style.animation = '';
    introTimer = setTimeout(() => { overlay.hidden = true; }, paused ? 2400 : 3200);
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
  toolTabs.forEach((button, index) => {
    button.addEventListener('click', () => selectTool(button));
    button.addEventListener('keydown', event => {
      const offsets = { ArrowRight: 1, ArrowLeft: -1, Home: -index, End: toolTabs.length - 1 - index };
      if (!(event.key in offsets)) return;
      event.preventDefault();
      const next = toolTabs[(index + offsets[event.key] + toolTabs.length) % toolTabs.length];
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
  dialog.addEventListener('click', event => { if (event.target === dialog) { const box = dialog.getBoundingClientRect(); if (event.clientX < box.left || event.clientX > box.right || event.clientY < box.top || event.clientY > box.bottom) dialog.close(); } });
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
  $('#page-motion-toggle').addEventListener('click', updateScroll);
  $('#motion-toggle').addEventListener('click', updateScroll);
  motionPreference.addEventListener('change', updateScroll);
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
