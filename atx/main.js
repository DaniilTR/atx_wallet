document.addEventListener('DOMContentLoaded', () => {
  // Копирование адреса
  const copyBtn = document.getElementById('copy-btn');
  const addr = document.getElementById('addr-value');
  if (copyBtn && addr) {
    copyBtn.addEventListener('click', async () => {
      const value = addr.textContent?.trim() || '';
      try {
        if (navigator.clipboard && value) {
          await navigator.clipboard.writeText(value);
        } else {
          const ta = document.createElement('textarea');
          ta.value = value; document.body.appendChild(ta); ta.select();
          document.execCommand('copy'); document.body.removeChild(ta);
        }
        copyBtn.classList.add('ok');
        setTimeout(() => copyBtn.classList.remove('ok'), 900);
      } catch (e) {
        alert('Не удалось скопировать адрес');
      }
    });
  }

  // Выбор активной кнопки в доке
  const dockButtons = document.querySelectorAll('.dock-btn');
  dockButtons.forEach(btn => btn.addEventListener('click', () => {
    dockButtons.forEach(b => b.classList.remove('active'));
    btn.classList.add('active');
  }));

  // Debug grid overlay toggle (press 'g')
  let grid = document.querySelector('.grid-overlay');
  if(!grid){
    grid = document.createElement('div');
    grid.className = 'grid-overlay';
    document.body.appendChild(grid);
  }
  window.addEventListener('keydown', (e) => {
    if(e.key.toLowerCase() === 'g'){
      grid.classList.toggle('active');
    }
  });
});
