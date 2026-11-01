addEventListener('wheel', event => {
  if (event.ctrlKey || Math.abs(event.deltaX) > Math.abs(event.deltaY)) return;
  const scroller = document.scrollingElement;
  const canScroll = event.deltaY > 0
    ? scroller.scrollTop + scroller.clientHeight < scroller.scrollHeight - 2
    : scroller.scrollTop > 2;
  if (!canScroll && parent !== window) {
    event.preventDefault();
    parent.postMessage({ type:'workspace-wheel', deltaY:event.deltaY, deltaMode:event.deltaMode }, '*');
  }
}, { passive:false });
