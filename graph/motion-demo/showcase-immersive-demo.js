(() => {
  'use strict';
  const panels = [...document.querySelectorAll('.panel')];
  const links = [...document.querySelectorAll('.chapter-nav a')];
  const preference = matchMedia('(prefers-reduced-motion: reduce)');
  let paused = preference.matches;
  let current = Math.max(0, panels.findIndex(panel => `#${panel.id}` === location.hash));
  let locked = false;
  let wheelDistance = 0;
  let wheelTimer;
  let touchStart = null;

  function updateNavigation() {
    links.forEach((link, index) => {
      if (index === current) link.setAttribute('aria-current', 'location');
      else link.removeAttribute('aria-current');
    });
    panels.forEach((panel, index) => {
      panel.inert = index !== current;
      panel.setAttribute('aria-hidden', String(index !== current));
    });
  }
  function goTo(index) {
    if (locked || index < 0 || index >= panels.length || index === current) return;
    locked = true;
    const previous = panels[current];
    const next = panels[index];
    const forward = index > current;
    const moveFocus = previous.contains(document.activeElement);
    next.style.zIndex = '2';
    previous.style.zIndex = '1';
    next.className = `panel ${next.dataset.panelClass} is-preparing ${forward ? 'from-below' : 'from-above'}`;
    void next.offsetHeight;
    previous.classList.remove('is-current');
    previous.classList.add('is-leaving', forward ? 'to-above' : 'to-below');
    next.className = `panel ${next.dataset.panelClass} is-current`;
    current = index;
    updateNavigation();
    if (moveFocus) {
      const heading = next.querySelector('h1, h2');
      heading.setAttribute('tabindex', '-1');
      heading.focus({ preventScroll:true });
    }
    history.replaceState(null, '', `${location.href.split('#')[0]}#${next.id}`);
    let finished = false;
    let fallback;
    function finish(event) {
      if (event && (event.target !== next || event.propertyName !== 'clip-path')) return;
      if (finished) return;
      finished = true;
      clearTimeout(fallback);
      next.removeEventListener('transitionend', finish);
      previous.classList.remove('is-leaving', 'to-above', 'to-below');
      previous.style.zIndex = '';
      next.style.zIndex = '';
      locked = false;
      wheelDistance = 0;
    }
    next.addEventListener('transitionend', finish);
    fallback = setTimeout(finish, paused ? 0 : 850);
  }
  function setPaused(value) {
    paused = value;
    document.documentElement.classList.toggle('motion-off', paused);
  }
  function canScrollPanel(direction) {
    const panel = panels[current];
    return direction > 0 ? panel.scrollTop + panel.clientHeight < panel.scrollHeight - 2 : panel.scrollTop > 2;
  }

  panels.forEach((panel, index) => {
    panel.dataset.panelClass = [...panel.classList].find(name => name !== 'panel');
    if (index === current) panel.classList.add('is-current');
  });
  document.documentElement.classList.add('deck-ready');
  updateNavigation();
  setPaused(paused);
  document.addEventListener('click', event => {
    const link = event.target.closest('a[href^="#"]');
    if (!link || event.button !== 0 || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return;
    const index = panels.findIndex(panel => `#${panel.id}` === link.getAttribute('href'));
    if (index !== -1) { event.preventDefault(); goTo(index); }
  });
  function handleWheel(deltaY, deltaMode) {
    const direction = Math.sign(deltaY);
    if (!locked && canScrollPanel(direction)) { wheelDistance = 0; return; }
    if (locked) return;
    if (wheelDistance && Math.sign(wheelDistance) !== direction) wheelDistance = 0;
    wheelDistance += deltaY * (deltaMode === 1 ? 16 : deltaMode === 2 ? innerHeight : 1);
    clearTimeout(wheelTimer);
    wheelTimer = setTimeout(() => { wheelDistance = 0; }, 200);
    if (Math.abs(wheelDistance) > 55) { goTo(current + Math.sign(wheelDistance)); wheelDistance = 0; }
  }
  addEventListener('wheel', event => {
    if (event.ctrlKey || Math.abs(event.deltaX) > Math.abs(event.deltaY)) return;
    if (!locked && canScrollPanel(Math.sign(event.deltaY))) { wheelDistance = 0; return; }
    event.preventDefault();
    handleWheel(event.deltaY, event.deltaMode);
  }, { passive:false });
  const bootFrame = document.querySelector('.boot-visual iframe');
  addEventListener('message', event => {
    const fromBoot = current === 3 && event.source === bootFrame.contentWindow;
    if (!fromBoot || event.data?.type !== 'workspace-wheel') return;
    if (!Number.isFinite(event.data.deltaY) || ![0, 1, 2].includes(event.data.deltaMode)) return;
    handleWheel(event.data.deltaY, event.data.deltaMode);
  });
  addEventListener('touchstart', event => { if (event.touches.length === 1) touchStart = event.touches[0].clientY; }, { passive:true });
  addEventListener('touchend', event => {
    if (touchStart === null || !event.changedTouches.length) return;
    const delta = touchStart - event.changedTouches[0].clientY;
    touchStart = null;
    if (Math.abs(delta) > 60 && !canScrollPanel(Math.sign(delta))) goTo(current + Math.sign(delta));
  }, { passive:true });
  addEventListener('keydown', event => {
    if (/^(INPUT|TEXTAREA|SELECT|BUTTON)$/.test(event.target.tagName) || event.altKey || event.ctrlKey || event.metaKey) return;
    let direction = 0;
    if (['ArrowDown', 'PageDown', ' '].includes(event.key)) direction = 1;
    if (['ArrowUp', 'PageUp'].includes(event.key)) direction = -1;
    if (direction && !canScrollPanel(direction)) { event.preventDefault(); goTo(current + direction); }
  });
  preference.addEventListener('change', event => setPaused(event.matches));
})();
