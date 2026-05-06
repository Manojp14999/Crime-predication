// Global utilities for CrimeWatch Mysuru

function showToast(msg, type = 'info') {
  let t = document.getElementById('toast');
  if (!t) {
    t = document.createElement('div');
    t.id = 'toast';
    t.className = 'toast';
    document.body.appendChild(t);
  }
  t.textContent = msg;
  t.className = `toast show ${type}`;
  setTimeout(() => { t.className = 'toast'; }, 3500);
}

async function checkStatus() {
  try {
    const res  = await fetch('/api/status');
    const data = await res.json();
    const badge = document.getElementById('status-badge');
    if (badge) {
      badge.innerHTML = data.models_ready
        ? '<span class="dot green"></span> Models Ready'
        : '<span class="dot red"></span> Not Trained';
    }
    return data;
  } catch { return null; }
}

document.addEventListener('DOMContentLoaded', checkStatus);
