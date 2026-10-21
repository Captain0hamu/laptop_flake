(() => {
  'use strict';
  const data = window.NIX_SHOWCASE;
  if (!data) return;
  const $ = selector => document.querySelector(selector);
  const $$ = selector => [...document.querySelectorAll(selector)];
  const stages = {
    grub: { tag: '01 / SYSTEM SELECTION', title: '選ぶところから、らしく。', text: 'Grand Theft Gentooのテーマをベースに、BankGothicと青みのある選択ハイライト。標準の背景を外し、手動選択後はメニューを保持してカーネルへ渡す構成です。プレビューのメニュー構成は表示例です。', sources: ['modules/nixos/bootloader.nix', 'files/grub/keep-menu-on-boot.patch'] },
    plymouth: { tag: '02 / BOOT SPLASH', title: '待ち時間も、演出に。', text: 'ポスターと暗い背景を合成したPlymouthテーマ。ラジオ表示、回るレコード、ヒントと進捗バーをスクリプトで描画。ここでは実際の生成背景に、HUDと進捗のWeb再現を重ねています。', sources: ['modules/nixos/plymouth.nix', 'files/plymouth/gtg/gtg.script'] },
    sddm: { tag: '03 / LOGIN', title: '静止画に、時間を足す。', text: `${data.frames.length}枚のフレームをクロスフェード。緩やかなパンとズームに、走査線とラジオHUDを重ねたQMLのログイン画面。BankGothicで起動画面とトーンを揃えています。`, sources: ['files/sddm/Gently-Blur-SDDM-6/AnimatedBackground.qml', 'files/sddm/Gently-Blur-SDDM-6/IntroOverlay.qml', 'files/sddm/Gently-Blur-SDDM-6/SplashHud.qml'] }
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
    $('#motion-toggle').textContent = paused ? '▶ アニメーションを再生' : 'Ⅱ アニメーションを停止';
  }
  setMotion();
  motionPreference.addEventListener('change', event => { paused = event.matches; last = performance.now(); setMotion(); });
  $('#motion-toggle').addEventListener('click', () => { paused = !paused; last = performance.now(); setMotion(); });
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
    $('#copy-source').textContent = 'コピー'; dialog.showModal();
    dialog.querySelector('pre').scrollTop = 0;
  });
  $('#close-source').addEventListener('click', () => dialog.close());
  dialog.addEventListener('close', () => lastTrigger?.focus());
  dialog.addEventListener('click', event => { if (event.target === dialog) { const box = dialog.getBoundingClientRect(); if (event.clientX < box.left || event.clientX > box.right || event.clientY < box.top || event.clientY > box.bottom) dialog.close(); } });
  $('#copy-source').addEventListener('click', async () => {
    try { await navigator.clipboard.writeText($('#source-code').textContent); $('#copy-source').textContent = 'コピーしました'; }
    catch { const selection = getSelection(), range = document.createRange(); range.selectNodeContents($('#source-code')); selection.removeAllRanges(); selection.addRange(range); $('#copy-source').textContent = '選択しました · Ctrl/Cmd+C'; }
  });
})();
