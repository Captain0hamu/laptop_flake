(() => {
  'use strict';
  const data = window.NIX_GRAPH_DATA;
  const svg = document.getElementById('network-graph');
  const stage = document.querySelector('.network-stage');
  const search = document.getElementById('graph-search');
  const results = document.getElementById('graph-search-results');
  const details = document.getElementById('graph-details');
  const motionButton = document.getElementById('graph-motion');
  const ns = 'http://www.w3.org/2000/svg';
  const reduced = matchMedia('(prefers-reduced-motion: reduce)');
  let paused = reduced.matches, selected = null, frame = 0, remaining = 0, drag = null;
  const make = (tag, attrs = {}) => {
    const item = document.createElementNS(ns, tag);
    Object.entries(attrs).forEach(([key, value]) => item.setAttribute(key, value));
    return item;
  };
  const html = (tag, text, className) => {
    const item = document.createElement(tag);
    if (text !== undefined) item.textContent = text;
    if (className) item.className = className;
    return item;
  };
  if (!data || !Array.isArray(data.localReferences)) {
    document.getElementById('graph-count').textContent = 'DATA UNAVAILABLE';
    return;
  }
  const paths = [...new Set(data.localReferences.flatMap(ref => [ref.file, ...ref.targets]))].sort();
  const category = path => path.startsWith('modules/') ? 'system'
    : path.startsWith('home/') ? 'home'
    : path.startsWith('files/') || path.startsWith('scripts/') ? 'asset' : 'root';
  const colors = { root: '#a9c9ef', system: '#a890ed', home: '#8bd6b5', asset: '#d9b58e' };
  const anchors = { root: [300, 320], system: [700, 235], home: [610, 530], asset: [350, 560] };
  const nodes = paths.map((path, i) => {
    const kind = category(path), angle = i * 2.399963, radius = 32 + (i % 8) * 22;
    return { path, kind, x: anchors[kind][0] + Math.cos(angle) * radius,
      y: anchors[kind][1] + Math.sin(angle) * radius, vx: 0, vy: 0, degree: 0 };
  });
  const byPath = new Map(nodes.map(node => [node.path, node]));
  const edges = [];
  data.localReferences.forEach(ref => ref.targets.forEach(target => {
    const from = byPath.get(ref.file), to = byPath.get(target);
    if (!from || !to || from === to) return;
    edges.push({ from, to }); from.degree++; to.degree++;
  }));
  document.getElementById('graph-count').textContent = `${nodes.length} FILES / ${edges.length} LINKS`;
  const edgesLayer = make('g'), nodesLayer = make('g');
  svg.append(edgesLayer, nodesLayer);
  edges.forEach(edge => { edge.el = make('line', { class: 'network-edge' }); edgesLayer.append(edge.el); });
  nodes.forEach(node => {
    node.el = make('g', { class: 'network-node', role: 'button', tabindex: '0', 'aria-label': `${node.path}, ${node.degree} connections` });
    const hitArea = make('circle', { class: 'node-hit', r: 20, fill: 'transparent', 'pointer-events': 'all', 'aria-hidden': 'true' });
    node.circle = make('circle', { r: Math.min(13, 5 + Math.sqrt(node.degree) * 1.5), fill: colors[node.kind] });
    node.label = make('text', { x: 14, y: 4 });
    node.label.textContent = node.path.split('/').pop();
    node.el.append(hitArea, node.circle, node.label); nodesLayer.append(node.el);
    node.el.addEventListener('click', () => { if (!node.moved) select(node); });
    node.el.addEventListener('keydown', event => {
      if (event.key === 'Enter' || event.key === ' ') { event.preventDefault(); select(node); }
    });
    node.el.addEventListener('pointerdown', event => {
      if (event.button !== 0) return;
      node.moved = false; drag = { node, x: event.clientX, y: event.clientY };
      node.el.setPointerCapture(event.pointerId);
    });
    node.el.addEventListener('pointermove', event => {
      if (!drag || drag.node !== node) return;
      if (Math.hypot(event.clientX - drag.x, event.clientY - drag.y) > 3) node.moved = true;
      if (!node.moved) return;
      const point = svg.createSVGPoint(); point.x = event.clientX; point.y = event.clientY;
      const matrix = svg.getScreenCTM(); if (!matrix) return;
      const position = point.matrixTransform(matrix.inverse());
      node.x = Math.max(24, Math.min(976, position.x)); node.y = Math.max(40, Math.min(680, position.y));
      node.vx = node.vy = 0; render();
    });
    node.el.addEventListener('pointerup', () => { drag = null; if (!paused) start(70); });
    node.el.addEventListener('pointercancel', () => { drag = null; });
  });
  function render() {
    edges.forEach(edge => {
      edge.el.setAttribute('x1', edge.from.x); edge.el.setAttribute('y1', edge.from.y);
      edge.el.setAttribute('x2', edge.to.x); edge.el.setAttribute('y2', edge.to.y);
    });
    nodes.forEach(node => node.el.setAttribute('transform', `translate(${node.x} ${node.y})`));
  }
  function step() {
    nodes.forEach(node => {
      const [ax, ay] = anchors[node.kind];
      node.vx += (ax - node.x) * .0015; node.vy += (ay - node.y) * .0015;
    });
    for (let i = 0; i < nodes.length; i++) for (let j = i + 1; j < nodes.length; j++) {
      const a = nodes[i], b = nodes[j], dx = a.x - b.x || .01, dy = a.y - b.y || .01;
      const d2 = Math.max(100, dx * dx + dy * dy), force = Math.min(1.5, 260 / d2);
      a.vx += dx * force / Math.sqrt(d2); a.vy += dy * force / Math.sqrt(d2);
      b.vx -= dx * force / Math.sqrt(d2); b.vy -= dy * force / Math.sqrt(d2);
    }
    edges.forEach(({ from, to }) => {
      const dx = to.x - from.x, dy = to.y - from.y, distance = Math.max(1, Math.hypot(dx, dy));
      const force = (distance - 120) * .0018;
      from.vx += dx / distance * force; from.vy += dy / distance * force;
      to.vx -= dx / distance * force; to.vy -= dy / distance * force;
    });
    nodes.forEach(node => {
      if (drag && drag.node === node) return;
      node.vx *= .85; node.vy *= .85;
      node.x = Math.max(35, Math.min(950, node.x + node.vx));
      node.y = Math.max(65, Math.min(665, node.y + node.vy));
    });
  }
  function animate() {
    frame = 0;
    if (paused || remaining-- <= 0) return;
    step(); render(); frame = requestAnimationFrame(animate);
  }
  function start(ticks) { remaining = ticks; if (!frame && !paused) frame = requestAnimationFrame(animate); }
  function updateMotion() {
    motionButton.setAttribute('aria-pressed', String(paused));
    motionButton.textContent = paused ? 'Resume motion' : 'Pause motion';
  }
  motionButton.addEventListener('click', () => { paused = !paused; updateMotion(); if (!paused) start(100); });
  reduced.addEventListener('change', event => { paused = event.matches; updateMotion(); if (!paused) start(100); });

  function select(node) {
    selected = node;
    const incoming = edges.filter(edge => edge.to === node).map(edge => edge.from);
    const outgoing = edges.filter(edge => edge.from === node).map(edge => edge.to);
    const related = new Set([node, ...incoming, ...outgoing]);
    stage.classList.add('has-selection');
    edges.forEach(edge => edge.el.classList.toggle('related', edge.from === node || edge.to === node));
    nodes.forEach(item => {
      item.el.classList.toggle('related', related.has(item));
      item.el.classList.toggle('selected', item === node);
      item.label.style.display = related.has(item) ? '' : 'none';
    });
    details.replaceChildren(html('span', 'NODE / SELECTED', 'eyebrow'), html('h3', node.path.split('/').pop()), html('p', node.path));
    function section(title, list) {
      details.append(html('h4', `${title} / ${list.length}`));
      const group = html('div', undefined, 'connections');
      if (!list.length) group.append(html('p', 'None found in the source scan.'));
      list.forEach(neighbor => { const button = html('button', `${neighbor.path} ↗`); button.type = 'button'; button.addEventListener('click', () => select(neighbor)); group.append(button); });
      details.append(group);
    }
    section('REFERENCES', outgoing); section('REFERENCED BY', incoming);
    if (node.path !== 'local.nix') {
      const link = html('a', 'OPEN SOURCE ↗');
      link.href = location.protocol === 'file:' ? `../${node.path}` : `https://github.com/Captain0hamu/laptop_flake/${/\.[^/]+$/.test(node.path) ? 'blob' : 'tree'}/main/${node.path.split('/').map(encodeURIComponent).join('/')}`;
      link.target = '_blank'; link.rel = 'noopener'; details.append(link);
    }
  }
  function reset() {
    selected = null; stage.classList.remove('has-selection'); search.value = ''; results.replaceChildren();
    nodes.forEach(node => {
      if (node.initial) { node.x = node.initial.x; node.y = node.initial.y; node.vx = node.vy = 0; }
      node.el.classList.remove('related', 'selected'); node.label.style.display = node.degree >= 4 ? '' : 'none';
    });
    edges.forEach(edge => edge.el.classList.remove('related'));
    details.replaceChildren(html('span', 'NODE / SELECTED', 'eyebrow'), html('h3', 'Start anywhere.'), html('p', 'Select a node or search for a file to inspect its connections.'));
    render();
    if (!paused) start(120);
  }
  search.addEventListener('input', () => {
    const query = search.value.trim().toLowerCase(); results.replaceChildren();
    if (!query) return;
    const matches = nodes.filter(node => node.path.toLowerCase().includes(query));
    matches.slice(0, 12).forEach(node => {
      const button = html('button', node.path); button.type = 'button';
      button.addEventListener('click', () => { select(node); results.replaceChildren(); }); results.append(button);
    });
    if (!matches.length) results.append(html('p', 'No matching files.'));
  });
  document.getElementById('graph-reset').addEventListener('click', reset);
  // The deployed site contains only selected assets, so repository links go to GitHub.
  if (location.protocol !== 'file:') document.querySelectorAll('.architecture svg a').forEach(link => {
    const href = link.getAttribute('href');
    if (href && href.startsWith('../')) link.setAttribute('href', `https://github.com/Captain0hamu/laptop_flake/blob/main/${href.slice(3)}`);
  });
  for (let i = 0; i < 100; i++) step();
  nodes.forEach(node => { node.initial = { x: node.x, y: node.y }; });
  render(); reset(); updateMotion();
})();
