(() => {
  'use strict';
  // Decorative lighting never controls content or the original showcase controls.
  if (!('IntersectionObserver' in window)) return;
  const observer = new IntersectionObserver(entries => {
    entries.forEach(entry => entry.target.classList.toggle('after-hours-visible', entry.isIntersecting));
  }, { threshold: 0.05 });
  document.querySelectorAll('.intro, .workspace, .tor-feature, .sequence, .underneath')
    .forEach(section => observer.observe(section));
})();
