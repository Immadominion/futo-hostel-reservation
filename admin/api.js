/* ============================================================
   Roost Admin — live backend integration.
   Layers on top of app.js: logs in, fetches from the API, maps
   the DTOs into the same shapes app.js already renders, then
   re-renders. Falls back to the seed data on any failure.

   Toggle demo mode (offline, uses app.js seed data):
     ?demo=1  in the URL, or  localStorage.roost_admin_demo = '1'
   ============================================================ */
(function () {
  'use strict';

  const CONFIG = {
    apiBaseUrl: 'https://futo-hostel-reservation-backend.onrender.com/api/v1',
    demo:
      new URLSearchParams(location.search).get('demo') === '1' ||
      localStorage.getItem('roost_admin_demo') === '1',
  };

  const TOKEN_KEY = 'roost_admin_jwt';
  const getToken = () => localStorage.getItem(TOKEN_KEY);
  const setToken = (t) => localStorage.setItem(TOKEN_KEY, t);
  const clearToken = () => localStorage.removeItem(TOKEN_KEY);

  let live = false; // true once we're showing live data

  // ---- HTTP ----
  async function request(path, { method = 'GET', body } = {}) {
    const res = await fetch(CONFIG.apiBaseUrl + path, {
      method,
      headers: {
        'Content-Type': 'application/json',
        Accept: 'application/json',
        ...(getToken() ? { Authorization: 'Bearer ' + getToken() } : {}),
      },
      body: body ? JSON.stringify(body) : undefined,
    });
    let data = null;
    const text = await res.text();
    if (text) {
      try { data = JSON.parse(text); } catch (_) {}
    }
    if (!res.ok) {
      const msg = data && data.error ? data.error.message : 'Request failed (' + res.status + ')';
      const err = new Error(msg);
      err.status = res.status;
      throw err;
    }
    return data;
  }

  // ---- mapping (server DTO -> app.js render shapes) ----
  const GENDER_LABEL = { male: 'Male', female: 'Female', mixed: 'Mixed', postgrad: 'Postgraduate' };
  const fmtDate = (iso) => {
    if (!iso) return '';
    const d = new Date(iso);
    return isNaN(d) ? String(iso) : d.toLocaleDateString('en-NG', { day: 'numeric', month: 'short', year: 'numeric' });
  };
  const replaceArr = (arr, items) => { arr.length = 0; items.forEach((x) => arr.push(x)); };

  async function loadAll() {
    // hostels + their rooms
    const hostelDtos = await request('/admin/hostels');
    const hostels = await Promise.all(
      hostelDtos.map(async (h) => {
        let rooms = [];
        try {
          const roomDtos = await request('/admin/rooms?hostelId=' + encodeURIComponent(h.id));
          rooms = roomDtos.map((r) => ({ type: r.name, avail: r.bedsAvailable, total: r.bedsTotal, id: r.id, capacity: r.capacity }));
        } catch (_) {
          rooms = [{ type: 'beds', avail: h.bedsAvailable || 0, total: h.bedsTotal || 0 }];
        }
        return {
          id: h.id,
          name: h.name,
          gender: GENDER_LABEL[h.gender] || h.gender || '—',
          funder: h.funder || '—',
          price: h.price || 0,
          rooms,
        };
      })
    );
    const nameById = {};
    hostels.forEach((h) => { nameById[h.id] = h.name; });

    // reservations
    const resDtos = await request('/admin/reservations');
    const reservations = resDtos.map((r) => ({
      id: r.id,
      ref: r.reference || '—',
      student: r.studentName || r.studentRegNo || '—',
      reg: r.studentRegNo || '',
      hostel: nameById[r.hostelId] || r.hostelId || '—',
      room: (r.roomName || 'Room') + (r.bed ? ' · Bed ' + r.bed : ''),
      rrr: r.rrr || '',
      amount: r.fee || 0,
      status: (r.status || 'pending').toUpperCase(),
      date: fmtDate(r.createdAt),
      roomId: r.roomId || '',
      bed: r.bed || null,
    }));

    // allocation queue = reservations still awaiting a confirmed bed
    const queue = resDtos
      .filter((r) => r.status === 'pending' || r.status === 'reserved')
      .map((r) => ({
        id: r.id,
        reg: r.studentRegNo || '',
        name: r.studentName || r.studentRegNo || '—',
        level: r.studentLevel || '—',
        requested: nameById[r.hostelId] || r.hostelId || '—',
        roomId: r.roomId || '',
        bed: r.bed || null,
      }));

    // push into app.js globals (mutated in place) and repaint
    replaceArr(HOSTELS, hostels);
    replaceArr(RESERVATIONS, reservations);
    replaceArr(QUEUE, queue);
    replaceArr(ALLOCATED, []);
    live = true;
    renderAll();
    banner(false);
  }

  function renderAll() {
    renderOverview();
    renderHostels();
    renderReservations();
    renderAllocation();
  }

  // ---- allocation (live): confirm the held bed via the API ----
  async function allocateLive(index) {
    const item = QUEUE[index];
    if (!item) return;
    try {
      await request('/admin/reservations/' + encodeURIComponent(item.id) + '/allocate', {
        method: 'POST',
        body: { roomId: item.roomId, bed: item.bed },
      });
      await loadAll();
    } catch (e) {
      banner(true, 'Could not allocate: ' + e.message);
    }
  }

  // ---- login modal ----
  function showLogin(show) {
    const scrim = document.getElementById('adminLoginScrim');
    if (scrim) scrim.hidden = !show;
  }

  function wireLogin() {
    const form = document.getElementById('adminLoginForm');
    if (!form) return;
    form.addEventListener('submit', async (e) => {
      e.preventDefault();
      const errEl = document.getElementById('loginError');
      const btn = form.querySelector('button[type="submit"]');
      if (errEl) errEl.hidden = true;
      if (btn) { btn.disabled = true; btn.textContent = 'Signing in…'; }
      try {
        const out = await request('/auth/admin/login', {
          method: 'POST',
          body: { email: form.email.value.trim(), password: form.password.value },
        });
        setToken(out.token);
        showLogin(false);
        await loadAll();
      } catch (err) {
        if (errEl) { errEl.textContent = err.message || 'Sign in failed.'; errEl.hidden = false; }
      } finally {
        if (btn) { btn.disabled = false; btn.textContent = 'Sign in'; }
      }
    });
  }

  // ---- small banner for degraded / error states ----
  function banner(show, msg) {
    let el = document.getElementById('adminBanner');
    if (!el) {
      el = document.createElement('div');
      el.id = 'adminBanner';
      el.style.cssText =
        'position:fixed;left:50%;bottom:18px;transform:translateX(-50%);background:#1e293b;color:#fff;' +
        'padding:10px 16px;border-radius:10px;font:500 13px system-ui;z-index:9999;max-width:90%;box-shadow:0 6px 24px rgba(0,0,0,.25)';
      document.body.appendChild(el);
    }
    el.textContent = msg || '';
    el.style.display = show ? 'block' : 'none';
  }

  // ---- boot ----
  async function boot() {
    wireLogin();
    if (CONFIG.demo) return; // app.js already rendered the seed data
    if (!getToken()) { showLogin(true); return; }
    try {
      await loadAll();
    } catch (e) {
      if (e.status === 401) { clearToken(); showLogin(true); return; }
      banner(true, 'Live data unavailable — showing sample data. (' + e.message + ')');
    }
  }

  window.RoostAdmin = {
    boot,
    isLive: () => live,
    allocateLive,
    signOut: () => { clearToken(); location.reload(); },
  };
})();
