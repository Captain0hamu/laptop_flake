(() => {
  'use strict';
  const main = document.querySelector('main');
  const footer = document.querySelector('.showcase-footer');
  const header = document.querySelector('.navigation');
  const sections = [
    [document.querySelector('.intro')],
    [document.querySelector('.workspace')],
    [document.querySelector('.tor-feature')],
    [document.querySelector('.sequence')],
    [document.querySelector('.underneath'), footer]
  ];
  const names = ['Intro', 'Daily driver', 'Go onion', 'Power on', 'More'];
  const hashIds = ['intro', 'workspace', 'tor', 'sequence', 'more'];
  const preference = matchMedia('(prefers-reduced-motion: reduce)');
  let current = Math.max(0, hashIds.indexOf(location.hash.slice(1)));
  let locked = false, edgeDirection = 0, edgeDistance = 0, touchStart = null;

  const workspaceImage = document.createElement('div');
  workspaceImage.className = 'deck-workspace-image tor-window';
  workspaceImage.innerHTML = `
    <div class="tor-window-bar"><span aria-hidden="true"><i></i><i></i><i></i></span><span>DAILY DRIVER / KITTY</span><span>01 — 02</span></div>
    <div class="tor-screen">
      <div class="tor-screen-meta"><span>THE WORKSPACE</span><span>PLASMA / NIXOS</span></div>
      <figure><img src="assets/workspace-daily-redacted.png" alt="Kitty workspace with fastfetch and Nix configuration; IP addresses are hidden"><figcaption>ACTUAL DESKTOP <span> / SENSITIVE DETAILS REDACTED</span></figcaption></figure>
      <div class="tor-screen-bottom"><span>CONFIGURED FOR THE EVERYDAY</span><span aria-hidden="true">✳</span></div>
    </div>`;
  const workspaceSimulation = document.querySelector('.workspace-simulation');
  workspaceSimulation.inert = true;
  workspaceSimulation.setAttribute('aria-hidden', 'true');
  workspaceSimulation.before(workspaceImage);

  const panels = sections.map((nodes, index) => {
    const panel = document.createElement('div');
    const inner = document.createElement('div');
    panel.className = 'deck-panel';
    inner.className = 'deck-inner';
    nodes.forEach(node => inner.appendChild(node));
    if (index === 0) panel.appendChild(header);
    panel.appendChild(inner);
    main.appendChild(panel);
    if (index === current) panel.classList.add('is-current');
    return panel;
  });

  const navigation = document.createElement('nav');
  navigation.className = 'deck-index';
  navigation.setAttribute('aria-label', 'Showcase sections');
  const buttons = names.map((name, index) => {
    const button = document.createElement('button');
    button.type = 'button';
    button.setAttribute('aria-label', name);
    button.addEventListener('click', () => goTo(index));
    navigation.appendChild(button);
    return button;
  });
  document.body.appendChild(navigation);

  function updateState() {
    panels.forEach((panel, index) => {
      panel.inert = index !== current;
      panel.setAttribute('aria-hidden', String(index !== current));
      if (index === current) buttons[index].setAttribute('aria-current', 'location');
      else buttons[index].removeAttribute('aria-current');
    });
  }
  function goTo(index) {
    if (locked || index < 0 || index >= panels.length || index === current) return;
    locked = true;
    const previous = panels[current], next = panels[index];
    const moveFocus = previous.contains(document.activeElement);
    const forward = index > current;
    next.scrollTop = 0;
    next.style.zIndex = '2';
    previous.style.zIndex = '1';
    next.className = `deck-panel is-preparing ${forward ? 'from-below' : 'from-above'}`;
    void next.offsetHeight;
    previous.className = 'deck-panel is-leaving';
    next.className = 'deck-panel is-current';
    current = index;
    updateState();
    if (moveFocus) buttons[index].focus({ preventScroll:true });
    history.replaceState(null, '', `${location.href.split('#')[0]}#${hashIds[index]}`);
    let finished = false, fallback;
    function finish(event) {
      if (event && (event.target !== next || event.propertyName !== 'clip-path')) return;
      if (finished) return;
      finished = true;
      clearTimeout(fallback);
      next.removeEventListener('transitionend', finish);
      previous.className = 'deck-panel';
      previous.style.zIndex = '';
      next.style.zIndex = '';
      locked = false;
      resetEdge();
    }
    next.addEventListener('transitionend', finish);
    fallback = setTimeout(finish, preference.matches ? 0 : 850);
  }
  function canScroll(direction) {
    const panel = panels[current];
    return direction > 0 ? panel.scrollTop + panel.clientHeight < panel.scrollHeight - 2 : panel.scrollTop > 2;
  }
  function resetEdge() {
    edgeDirection = 0;
    edgeDistance = 0;
  }
  function tryEdge(direction, distance) {
    if (locked || !direction || current + direction < 0 || current + direction >= panels.length) return;
    if (edgeDirection !== direction) {
      edgeDirection = direction;
      edgeDistance = 0;
    }
    edgeDistance += distance;
    if (edgeDistance >= panels[current].clientHeight * 0.25) {
      resetEdge();
      goTo(current + direction);
    }
  }
  document.documentElement.classList.add('deck-ready');
  updateState();
  document.addEventListener('click', event => {
    const link = event.target.closest('a[href^="#"]');
    if (!link || event.button !== 0 || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return;
    const index = hashIds.indexOf(link.getAttribute('href').slice(1));
    if (index !== -1) { event.preventDefault(); goTo(index); }
  });
  addEventListener('wheel', event => {
    if (event.ctrlKey || Math.abs(event.deltaX) > Math.abs(event.deltaY) || document.querySelector('dialog[open]')) return;
    const direction = Math.sign(event.deltaY);
    if (!direction) return;
    if (!locked && canScroll(direction)) { resetEdge(); return; }
    event.preventDefault();
    if (locked) return;
    const distance = Math.abs(event.deltaY) * (event.deltaMode === 1 ? 16 : event.deltaMode === 2 ? innerHeight : 1);
    tryEdge(direction, distance);
  }, { passive:false });
  addEventListener('touchstart', event => {
    if (event.touches.length === 1) {
      touchStart = { y:event.touches[0].clientY, atTop:!canScroll(-1), atBottom:!canScroll(1) };
    }
  }, { passive:true });
  addEventListener('touchend', event => {
    if (touchStart === null || !event.changedTouches.length || document.querySelector('dialog[open]')) return;
    const delta = touchStart.y - event.changedTouches[0].clientY;
    const beganAtEdge = delta > 0 ? touchStart.atBottom : touchStart.atTop;
    touchStart = null;
    if (Math.abs(delta) > 60 && beganAtEdge && !canScroll(Math.sign(delta))) tryEdge(Math.sign(delta), Math.abs(delta));
    else resetEdge();
  }, { passive:true });
  addEventListener('keydown', event => {
    if (/^(INPUT|TEXTAREA|SELECT|BUTTON)$/.test(event.target.tagName) || event.altKey || event.ctrlKey || event.metaKey || document.querySelector('dialog[open]')) return;
    let direction = 0;
    if (['ArrowDown', 'PageDown', ' '].includes(event.key)) direction = 1;
    if (['ArrowUp', 'PageUp'].includes(event.key)) direction = -1;
    if (direction && !canScroll(direction)) {
      event.preventDefault();
      const distance = event.key.startsWith('Arrow') ? 40 : panels[current].clientHeight * 0.85;
      tryEdge(direction, distance);
    } else if (direction) {
      resetEdge();
    }
  });
})();
