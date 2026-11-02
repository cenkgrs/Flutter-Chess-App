import * as api from './api.js';
import { lineChart, legend } from './charts.js';

const app = document.getElementById('app');

const RANGES = {
  today: { label: 'Bugün', days: 1 },
  week: { label: 'Son 7 gün', days: 7 },
  month: { label: 'Son 30 gün', days: 30 },
  custom: { label: 'Özel aralık', days: null },
};

const state = {
  range: 'week',
  from: null,
  to: null,
  eventFilter: '',
};

function window_() {
  if (state.range === 'custom' && state.from && state.to) {
    const to = new Date(state.to);
    to.setHours(24, 0, 0, 0); // inclusive of the chosen end day
    return [new Date(state.from), to];
  }
  const to = new Date();
  to.setHours(24, 0, 0, 0);
  const from = new Date(to);
  from.setDate(from.getDate() - RANGES[state.range].days);
  return [from, to];
}

const esc = (value) =>
  String(value ?? '').replace(/[&<>"']/g, (c) => ({
    '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;',
  })[c]);

const fmtDate = (value) =>
  value ? new Date(value).toLocaleString('tr-TR', { dateStyle: 'short', timeStyle: 'short' }) : '—';

function tile(label, value) {
  return `<div class="card tile"><div class="label">${esc(label)}</div><div class="value">${
    value ?? '—'
  }</div></div>`;
}

// ---------------------------------------------------------------- sign in

function renderLogin(message) {
  app.innerHTML = `
    <form class="login card" id="login">
      <h1>ROK Analitik</h1>
      <p class="note">Yalnızca analitik yöneticisi hesaplarla girilebilir.</p>
      <input type="email" name="email" placeholder="E-posta" autocomplete="username" required />
      <input type="password" name="password" placeholder="Parola" autocomplete="current-password" required />
      <button class="primary" type="submit">Giriş yap</button>
      ${message ? `<p class="error">${esc(message)}</p>` : ''}
    </form>`;
  document.getElementById('login').addEventListener('submit', async (event) => {
    event.preventDefault();
    const form = new FormData(event.target);
    try {
      await api.signIn(form.get('email'), form.get('password'));
      start();
    } catch (error) {
      renderLogin(error.message);
    }
  });
}

// ---------------------------------------------------------------- shell

function renderShell() {
  app.innerHTML = `
    <header class="bar">
      <h1>ROK Analitik</h1>
      <span class="spacer"></span>
      <button id="theme" title="Koyu/açık">◐</button>
      <button id="signout">Çıkış</button>
    </header>
    <div class="filters" id="filters"></div>
    <div id="body"></div>`;

  const filters = document.getElementById('filters');
  filters.innerHTML =
    Object.entries(RANGES)
      .map(
        ([key, r]) =>
          `<button data-range="${key}" aria-pressed="${state.range === key}">${r.label}</button>`
      )
      .join('') +
    `<span id="customRange" ${state.range === 'custom' ? '' : 'hidden'}>
       <input type="date" id="from" value="${state.from ?? ''}" />
       <input type="date" id="to" value="${state.to ?? ''}" />
     </span>`;

  filters.addEventListener('click', (event) => {
    const key = event.target.dataset?.range;
    if (!key) return;
    state.range = key;
    renderShell();
    load();
  });
  for (const id of ['from', 'to']) {
    document.getElementById(id)?.addEventListener('change', (event) => {
      state[id] = event.target.value;
      if (state.from && state.to) load();
    });
  }
  document.getElementById('signout').addEventListener('click', async () => {
    await api.signOut();
    renderLogin();
  });
  document.getElementById('theme').addEventListener('click', () => {
    const dark = document.documentElement.getAttribute('data-theme') === 'dark';
    document.documentElement.setAttribute('data-theme', dark ? 'light' : 'dark');
    load();
  });
}

// ---------------------------------------------------------------- data

async function load() {
  const body = document.getElementById('body');
  body.innerHTML = '<p class="empty">Yükleniyor…</p>';
  const [from, to] = window_();

  try {
    const [summary, series, people, events] = await Promise.all([
      api.overview(from, to),
      api.daily(from, to),
      api.users(from, to, 100),
      api.eventLog(from, to, state.eventFilter || null, 200),
    ]);
    renderBody(body, summary, series, people, events);
  } catch (error) {
    if (error instanceof api.NotAdminError) {
      body.innerHTML = `<p class="error">${esc(error.message)} Bu hesaba
        <code>analytics_admins</code> tablosundan yetki verilmeli.</p>`;
      return;
    }
    body.innerHTML = `<p class="error">Veri alınamadı: ${esc(error.message)}</p>`;
  }
}

function renderBody(body, summary, series, people, events) {
  const css = (name) =>
    getComputedStyle(document.documentElement).getPropertyValue(name).trim();

  body.innerHTML = `
    <section class="tiles">
      ${tile('Toplam kullanıcı', summary.total_users)}
      ${tile('Yeni kayıt', summary.new_users)}
      ${tile('Aktif (24s)', summary.active_24h)}
      ${tile('Aktif (7g)', summary.active_7d)}
      ${tile('Başlayan oyun', summary.games_started)}
      ${tile('Biten oyun', summary.games_finished)}
      ${tile('Asistan', summary.assistant_used)}
      ${tile('Analiz', summary.analysis_used)}
      ${tile('Abonelik bildiren', summary.subscriptions_reported)}
      ${tile('Misafir olayı', summary.guest_events)}
    </section>

    <section class="charts">
      <div class="card">
        <h2>Kullanıcılar</h2>
        <div class="legend" id="lg1"></div>
        <div class="chart-wrap" id="c1"></div>
      </div>
      <div class="card">
        <h2>Oyunlar</h2>
        <div class="legend" id="lg2"></div>
        <div class="chart-wrap" id="c2"></div>
      </div>
      <div class="card">
        <h2>Asistan, analiz ve abonelik</h2>
        <div class="legend" id="lg3"></div>
        <div class="chart-wrap" id="c3"></div>
      </div>
    </section>

    <section class="card" style="margin-bottom:24px">
      <h2>Kullanıcılar (${people.length})</h2>
      <table>
        <thead><tr><th>Kullanıcı</th><th>Kayıt</th><th>Son aktivite</th>
          <th class="num">Oyun</th><th class="num">Asistan</th><th class="num">Analiz</th><th>Abonelik</th></tr></thead>
        <tbody>${
          people.length
            ? people
                .map(
                  (u) => `<tr><td>${esc(u.label)}</td><td>${fmtDate(u.created_at)}</td>
                    <td>${fmtDate(u.last_seen)}</td><td class="num">${u.games}</td>
                    <td class="num">${u.assistant}</td><td class="num">${u.analysis}</td>
                    <td>${u.subscription === 'reported' ? 'bildirildi' : '—'}</td></tr>`
                )
                .join('')
            : '<tr><td colspan="7" class="empty">Kayıt yok.</td></tr>'
        }</tbody>
      </table>
      <p class="note">E-posta adresleri hiçbir sorguda getirilmez; kullanıcılar
        kullanıcı adıyla gösterilir.</p>
    </section>

    <section class="card">
      <h2>Olay günlüğü</h2>
      <select id="eventFilter" style="margin-bottom:12px">
        <option value="">Tüm olaylar</option>
        ${api.EVENT_NAMES.map(
          (n) => `<option value="${n}" ${state.eventFilter === n ? 'selected' : ''}>${n}</option>`
        ).join('')}
      </select>
      <table>
        <thead><tr><th>Tarih</th><th>Olay</th><th>Kullanıcı</th><th>Sürüm</th><th>Metadata</th></tr></thead>
        <tbody>${
          events.length
            ? events
                .map(
                  (e) => `<tr><td>${fmtDate(e.created_at)}</td><td>${esc(e.event_name)}</td>
                    <td>${esc(e.label)}</td><td>${esc(e.app_version ?? '—')} / ${esc(e.platform ?? '—')}</td>
                    <td class="meta">${esc(JSON.stringify(e.metadata))}</td></tr>`
                )
                .join('')
            : '<tr><td colspan="5" class="empty">Olay yok.</td></tr>'
        }</tbody>
      </table>
    </section>`;

  document.getElementById('eventFilter').addEventListener('change', (event) => {
    state.eventFilter = event.target.value;
    load();
  });

  const groups = [
    {
      wrap: 'c1',
      lg: 'lg1',
      series: [
        { key: 'signups', label: 'Kayıt', colour: css('--series-1') },
        { key: 'active_users', label: 'Aktif kullanıcı', colour: css('--series-3') },
      ],
    },
    {
      wrap: 'c2',
      lg: 'lg2',
      series: [
        { key: 'games_started', label: 'Başlayan', colour: css('--series-1') },
        { key: 'games_finished', label: 'Biten', colour: css('--series-2') },
      ],
    },
    {
      wrap: 'c3',
      lg: 'lg3',
      series: [
        { key: 'assistant_used', label: 'Asistan', colour: css('--series-1') },
        { key: 'analysis_used', label: 'Analiz', colour: css('--series-2') },
        { key: 'subscriptions_started', label: 'Abonelik', colour: css('--series-3') },
      ],
    },
  ];
  for (const g of groups) {
    legend(document.getElementById(g.lg), g.series);
    lineChart(document.getElementById(g.wrap), series, g.series);
  }
}

// ---------------------------------------------------------------- boot

async function start() {
  renderShell();
  await load();
}

async function boot() {
  if (!api.configured) {
    app.innerHTML = `<div class="login card"><h1>Kurulum eksik</h1>
      <p class="note"><code>.env.example</code> dosyasını <code>.env</code> olarak
      kopyalayıp Supabase URL ve <strong>anon</strong> anahtarını girin.
      Service-role anahtarını buraya koymayın.</p></div>`;
    return;
  }
  const session = await api.currentSession();
  if (session) await start();
  else renderLogin();
}

boot();

window.addEventListener('resize', () => {
  if (document.getElementById('body')?.querySelector('.charts')) load();
});
