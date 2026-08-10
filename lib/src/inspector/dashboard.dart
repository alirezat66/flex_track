/// Embedded single-page dashboard for [FlexTrackInspector] (no CDN).
const String flexTrackInspectorDashboardHtml = r'''
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1"/>
<title>FlexTrack Inspector</title>
<style>
/* Isar Inspector–inspired: Material 3 dark, seed #9FC9FF (see isar_inspector main.dart). */
:root {
  --seed: #9fc9ff;
  --bg: #0c0e12;
  --surface: #12151c;
  --surface-card: #161a22;
  --surface-high: #1e2430;
  --on-surface: #e8eaef;
  --on-surface-variant: #9aa3b5;
  --outline: #3d4554;
  --primary: #9fc9ff;
  --on-primary: #062542;
  --primary-container: #284056;
  --on-primary-container: #d2e4ff;
  --success: #7dd3a8;
  --warn-line: #ffb4a9;
}
* { box-sizing: border-box; }
html, body {
  margin: 0;
  height: 100%;
  font-family: system-ui, -apple-system, "Segoe UI", Roboto, sans-serif;
  background: var(--bg);
  color: var(--on-surface);
  font-size: 13px;
  -webkit-font-smoothing: antialiased;
}
.app-chrome {
  display: flex;
  align-items: stretch;
  gap: 24px;
  height: 100vh;
  padding: 24px;
  overflow: hidden;
}
.inspector-card {
  background: var(--surface-card);
  border-radius: 12px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.35), 0 4px 12px rgba(0,0,0,0.25);
  display: flex;
  flex-direction: column;
  min-width: 0;
  border: 1px solid rgba(159, 201, 255, 0.08);
}
.sidebar { width: 300px; flex-shrink: 0; }
.main-panel { flex: 1; min-width: 200px; }
.detail-panel { width: 320px; flex-shrink: 0; }
.sidebar-header {
  display: flex;
  align-items: center;
  gap: 14px;
  padding: 18px 20px 12px;
  min-height: 72px;
  border-bottom: 1px solid var(--outline);
}
.brand-mark {
  width: 40px;
  height: 40px;
  border-radius: 10px;
  background: linear-gradient(135deg, var(--primary) 0%, #6b9bd4 100%);
  color: var(--on-primary);
  font-weight: 800;
  font-size: 13px;
  display: flex;
  align-items: center;
  justify-content: center;
  letter-spacing: -0.02em;
  flex-shrink: 0;
}
.brand-titles { line-height: 1.2; }
.brand-name { font-weight: 700; font-size: 16px; color: var(--on-surface); }
.brand-sub { font-weight: 700; font-size: 16px; color: var(--on-surface); opacity: 0.92; }
.conn-row {
  padding: 10px 20px 14px;
  font-size: 12px;
  color: var(--on-surface-variant);
  border-bottom: 1px solid var(--outline);
  display: flex;
  align-items: center;
  gap: 8px;
}
.panel-title {
  padding: 16px 20px 12px;
  font-weight: 700;
  font-size: 16px;
  border-bottom: 1px solid var(--outline);
  color: var(--on-surface);
}
.toolbar {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
  align-items: center;
  padding: 12px 16px;
  background: var(--surface-high);
  border-bottom: 1px solid var(--outline);
}
button {
  background: var(--primary);
  color: var(--on-primary);
  border: none;
  padding: 8px 16px;
  border-radius: 20px;
  cursor: pointer;
  font-size: 13px;
  font-weight: 600;
  transition: opacity 0.15s, box-shadow 0.15s;
}
button:hover { opacity: 0.92; box-shadow: 0 2px 8px rgba(159, 201, 255, 0.25); }
button.secondary {
  background: transparent;
  color: var(--primary);
  border: 1px solid var(--outline);
  box-shadow: none;
}
button.secondary:hover { background: rgba(159, 201, 255, 0.08); }
button.active {
  background: var(--primary-container);
  color: var(--on-primary-container);
  box-shadow: none;
}
input[type="text"], select {
  background: var(--surface);
  color: var(--on-surface);
  border: 1px solid var(--outline);
  border-radius: 8px;
  padding: 8px 12px;
  font-size: 13px;
}
select { cursor: pointer; }
.status-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  display: inline-block;
  flex-shrink: 0;
}
.status-dot.on {
  background: var(--success);
  box-shadow: 0 0 10px rgba(125, 211, 168, 0.55);
}
.status-dot.off { background: #c47a6a; }
.scroll { flex: 1; overflow: auto; padding: 12px 16px 16px; }
.sidebar .scroll { padding-top: 8px; }
.list-item {
  padding: 12px 14px;
  margin-bottom: 10px;
  border-radius: 10px;
  background: var(--surface-high);
  border: 1px solid transparent;
  cursor: pointer;
  font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
  font-size: 12px;
  transition: border-color 0.12s, background 0.12s;
}
.list-item:hover {
  border-color: rgba(159, 201, 255, 0.35);
}
.list-item.selected {
  background: var(--primary-container);
  border-color: var(--primary);
  color: var(--on-primary-container);
}
.list-item.selected .time { color: var(--on-primary-container); opacity: 0.85; }
.list-item.selected .name { color: var(--on-primary-container); }
.list-item-row1 { line-height: 1.35; }
.tk-pills {
  display: flex;
  flex-wrap: wrap;
  gap: 4px;
  margin-top: 8px;
  align-items: center;
}
.tk-pill {
  font-size: 10px;
  font-weight: 700;
  padding: 3px 8px;
  border-radius: 999px;
  background: var(--primary-container);
  color: var(--on-primary-container);
  font-family: ui-monospace, Menlo, Consolas, monospace;
}
.tk-pill.ok {
  background: rgba(125, 211, 168, 0.18);
  color: var(--success);
  border: 1px solid rgba(125, 211, 168, 0.35);
}
.tk-pill.none {
  background: var(--surface-high);
  color: var(--on-surface-variant);
  font-weight: 600;
}
.tk-pill.more {
  background: var(--surface);
  color: var(--on-surface-variant);
  border: 1px dashed var(--outline);
}
.detail-subh {
  font-size: 10px;
  text-transform: uppercase;
  letter-spacing: 0.07em;
  color: var(--on-surface-variant);
  margin: 12px 0 6px;
  font-weight: 700;
}
.time { color: var(--on-surface-variant); font-size: 11px; margin-right: 10px; }
.name { font-weight: 700; color: var(--on-surface); }
.badge {
  display: inline-block;
  padding: 2px 8px;
  border-radius: 6px;
  font-size: 10px;
  font-weight: 700;
  margin-left: 8px;
  vertical-align: middle;
  text-transform: lowercase;
  letter-spacing: 0.02em;
}
.badge.business { background: #1e4d2e; color: #b8ebc8; }
.badge.user { background: #1a3a5c; color: #b8d4ff; }
.badge.technical { background: #3a3f4a; color: #d8dce6; }
.badge.sensitive { background: #5c2626; color: #ffc8c8; }
.badge.marketing { background: #3d2a52; color: #e8d4ff; }
.badge.system { background: #523218; color: #ffd6b0; }
.badge.security { background: #4a2020; color: #ffb8b8; }
.badge.other { background: #2d323c; color: #c8cdd8; }
.flags { margin-left: 8px; font-size: 11px; letter-spacing: 1px; }
.section {
  padding: 12px 0;
  border-bottom: 1px solid var(--outline);
}
.section:last-child { border-bottom: none; }
.section h2 {
  font-size: 11px;
  text-transform: uppercase;
  letter-spacing: 0.06em;
  color: var(--on-surface-variant);
  margin: 0 0 10px;
  font-weight: 700;
}
.tracker-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 13px;
  margin: 0 0 10px;
  padding: 10px 12px;
  border-radius: 8px;
  background: var(--surface-high);
  border-left: 3px solid transparent;
  transition: background 0.12s, border-color 0.12s;
}
.tracker-row.tracker-hit {
  border-left-color: var(--primary);
  background: rgba(159, 201, 255, 0.1);
}
.dot-en { width: 7px; height: 7px; border-radius: 50%; background: var(--success); }
.dot-dis { width: 7px; height: 7px; border-radius: 50%; background: #5c6370; }
.warn {
  color: #ffb4a8;
  font-size: 12px;
  margin: 6px 0;
  padding: 8px 10px;
  border-radius: 8px;
  border-left: 3px solid #ff8a7a;
  background: rgba(255, 138, 122, 0.08);
}
.detail-pre {
  margin: 0;
  padding: 12px;
  font-family: ui-monospace, Menlo, Consolas, monospace;
  font-size: 11px;
  white-space: pre-wrap;
  word-break: break-all;
  color: var(--on-primary-container);
  background: var(--surface);
  border-radius: 8px;
  border: 1px solid var(--outline);
}
.empty { color: var(--on-surface-variant); padding: 20px; text-align: center; font-size: 13px; }
.toolbar label { color: var(--on-surface-variant); font-size: 12px; font-weight: 500; }
</style>
</head>
<body>
<div class="app-chrome">
  <aside class="inspector-card sidebar">
    <header class="sidebar-header">
      <div class="brand-mark" aria-hidden="true">FT</div>
      <div class="brand-titles">
        <div class="brand-name">FlexTrack</div>
        <div class="brand-sub">Inspector</div>
      </div>
    </header>
    <div class="conn-row" id="connLine">
      <span class="status-dot off" id="connDot"></span>
      <span id="connText">disconnected</span>
    </div>
    <div class="scroll">
      <div class="section"><h2>Trackers</h2><div id="trackers"></div></div>
      <div class="section"><h2>Consent</h2><div id="consent"></div></div>
      <div class="section"><h2>Validation</h2><div id="validation"></div></div>
    </div>
  </aside>
  <main class="inspector-card main-panel">
    <div class="panel-title">Live events</div>
    <div class="toolbar">
      <button type="button" id="btnPause">Pause</button>
      <button type="button" class="secondary" id="btnClear">Clear</button>
      <input type="text" id="filterName" placeholder="Filter by name…" style="flex:1;min-width:120px;"/>
      <label>Category</label>
      <select id="filterCat"><option value="">All</option>
        <option value="business">business</option><option value="user">user</option>
        <option value="technical">technical</option><option value="sensitive">sensitive</option>
        <option value="marketing">marketing</option><option value="system">system</option>
        <option value="security">security</option></select>
      <label>Tracker</label>
      <select id="filterTracker"><option value="">All</option></select>
    </div>
    <div class="scroll" id="feed"></div>
  </main>
  <aside class="inspector-card detail-panel">
    <div class="panel-title">Event detail</div>
    <div class="scroll" id="detail"><div class="empty">Select an event</div></div>
  </aside>
</div>
<script>
(function(){
  var events = [];
  var selectedId = null;
  var paused = false;
  var userScrolledUp = false;
  var feedEl = document.getElementById('feed');
  var detailEl = document.getElementById('detail');
  var connDot = document.getElementById('connDot');
  var connText = document.getElementById('connText');
  var ws = null;
  var reconnectTimer = null;

  function catClass(c) {
    var m = {business:'business',user:'user',technical:'technical',sensitive:'sensitive',marketing:'marketing',system:'system',security:'security'};
    return m[c] || 'other';
  }

  function setConn(on) {
    connDot.className = 'status-dot ' + (on ? 'on' : 'off');
    connText.textContent = on ? 'connected' : 'reconnecting…';
  }

  function renderStatus(data) {
    var tb = document.getElementById('trackers');
    var cs = document.getElementById('consent');
    var vl = document.getElementById('validation');
    tb.innerHTML = '';
    cs.innerHTML = '';
    vl.innerHTML = '';
    if (!data || data.isSetUp === false) {
      tb.innerHTML = '<div class="empty">FlexTrack not set up</div>';
      return;
    }
    var trSel = document.getElementById('filterTracker');
    var prevTr = trSel ? trSel.value : '';
    if (trSel) {
      trSel.innerHTML = '<option value="">All</option>';
    }
    (data.trackers || []).forEach(function(t){
      var row = document.createElement('div');
      row.className = 'tracker-row';
      row.dataset.trackerId = t.id;
      var en = t.enabled ? '<span class="dot-en" title="enabled"></span>' : '<span class="dot-dis" title="disabled"></span>';
      row.innerHTML = en + ' <span style="flex:1;margin-left:8px;">' + escapeHtml(t.name) + '</span><span style="color:var(--on-surface-variant);font-size:11px;">' + escapeHtml(t.id) + '</span>';
      tb.appendChild(row);
      if (trSel && t.id) {
        var o = document.createElement('option');
        o.value = t.id;
        o.textContent = t.id;
        trSel.appendChild(o);
      }
    });
    if (trSel && prevTr) {
      var has = false;
      for (var i = 0; i < trSel.options.length; i++) {
        if (trSel.options[i].value === prevTr) { has = true; break; }
      }
      trSel.value = has ? prevTr : '';
    }
    applyTrackerRowHighlight();
    var con = data.consent || {};
    cs.innerHTML = '<div>general: <b>' + !!con.general + '</b></div><div>pii: <b>' + !!con.pii + '</b></div>';
    var issues = data.validation || [];
    if (!issues.length) vl.innerHTML = '<div style="color:var(--success);font-size:12px;">No issues</div>';
    else issues.forEach(function(w){ var d=document.createElement('div'); d.className='warn'; d.textContent=w; vl.appendChild(d); });
  }

  function escapeHtml(s) {
    if (s == null) return '';
    return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
  }

  function flagsHtml(f) {
    if (!f) return '';
    var s = '';
    if (f.essential) s += '<span class="flags" title="essential">⭐</span>';
    if (f.highVolume) s += '<span class="flags" title="high volume">📊</span>';
    if (f.containsPII) s += '<span class="flags" title="PII">🔒</span>';
    return s;
  }

  function normIds(x) {
    return Array.isArray(x) ? x : [];
  }

  function pillsHtml(ids, extraClass) {
    ids = normIds(ids);
    if (!ids.length) {
      return '<span class="tk-pill none">none</span>';
    }
    return ids.map(function(id) {
      return '<span class="tk-pill ' + (extraClass || '') + '">' + escapeHtml(id) + '</span>';
    }).join('');
  }

  function applyTrackerRowHighlight() {
    var targets = [];
    if (selectedId) {
      var sev = events.find(function(e) { return e.id === selectedId; });
      if (sev) targets = normIds(sev.targetTrackers);
    }
    document.querySelectorAll('.tracker-row').forEach(function(row) {
      var tid = row.dataset.trackerId;
      var hit = tid && targets.indexOf(tid) >= 0;
      row.classList.toggle('tracker-hit', !!hit);
    });
  }

  function pillsHtmlCompact(ids, max) {
    max = max || 4;
    ids = normIds(ids);
    if (!ids.length) {
      return '<span class="tk-pill none">—</span>';
    }
    var shown = ids.slice(0, max);
    var rest = ids.length - shown.length;
    var h = shown.map(function(id) {
      return '<span class="tk-pill">' + escapeHtml(id) + '</span>';
    }).join('');
    if (rest > 0) {
      h += '<span class="tk-pill more">+' + rest + '</span>';
    }
    return h;
  }

  function passesFilters(ev) {
    var q = (document.getElementById('filterName').value || '').trim().toLowerCase();
    if (q && String(ev.name).toLowerCase().indexOf(q) < 0) return false;
    var c = document.getElementById('filterCat').value;
    if (c) {
      var ec = ev.category || '';
      if (ec !== c) return false;
    }
    var tid = document.getElementById('filterTracker').value;
    if (tid) {
      var targets = normIds(ev.targetTrackers);
      var ok = normIds(ev.successfulTrackerIds);
      if (targets.indexOf(tid) < 0 && ok.indexOf(tid) < 0) return false;
    }
    return true;
  }

  function renderFeed() {
    var nearBottom = feedEl.scrollHeight - feedEl.scrollTop - feedEl.clientHeight < 40;
    feedEl.innerHTML = '';
    var list = events.filter(passesFilters);
    if (!list.length) { feedEl.innerHTML = '<div class="empty">No events</div>'; return; }
    list.forEach(function(ev){
      var div = document.createElement('div');
      div.className = 'list-item' + (ev.id === selectedId ? ' selected' : '');
      div.dataset.id = ev.id;
      var cat = ev.category || '—';
      var bc = catClass(ev.category);
      div.innerHTML = '<div class="list-item-row1"><span class="time">' + escapeHtml(ev.timestamp) + '</span><span class="name">' + escapeHtml(ev.name) + '</span>' +
        '<span class="badge ' + bc + '">' + escapeHtml(cat) + '</span>' + flagsHtml(ev.flags) + '</div>' +
        '<div class="tk-pills">' + pillsHtmlCompact(ev.targetTrackers, 4) + '</div>';
      div.onclick = function(){ selectEvent(ev.id); };
      feedEl.appendChild(div);
    });
    if (!userScrolledUp || nearBottom) {
      feedEl.scrollTop = 0;
    }
    applyTrackerRowHighlight();
  }

  function selectEvent(id) {
    selectedId = id;
    var ev = events.find(function(e){ return e.id === id; });
    if (!ev) {
      detailEl.innerHTML = '<div class="empty">Select an event</div>';
      applyTrackerRowHighlight();
      renderFeed();
      return;
    }
    var flags = ev.flags || {};
    detailEl.innerHTML =
      '<div class="section"><h2>Summary</h2><div style="font-family:monospace;font-size:12px;">' +
      '<div><b>name</b> ' + escapeHtml(ev.name) + '</div>' +
      '<div><b>category</b> ' + escapeHtml(ev.category || '—') + '</div>' +
      '<div><b>essential</b> ' + flags.essential + '</div>' +
      '<div><b>highVolume</b> ' + flags.highVolume + '</div>' +
      '<div><b>containsPII</b> ' + flags.containsPII + '</div></div></div>' +
      '<div class="section"><h2>Trackers</h2>' +
      '<div class="detail-subh">Routed to (rule targets)</div>' +
      '<div class="tk-pills">' + pillsHtml(ev.targetTrackers, '') + '</div>' +
      '<div class="detail-subh">Delivered (track succeeded)</div>' +
      '<div class="tk-pills">' + pillsHtml(ev.successfulTrackerIds, 'ok') + '</div></div>' +
      '<div class="section"><h2>Properties</h2><pre class="detail-pre">' + escapeHtml(JSON.stringify(ev.properties || {}, null, 2)) + '</pre></div>';
    applyTrackerRowHighlight();
    renderFeed();
  }

  feedEl.addEventListener('scroll', function(){
    userScrolledUp = feedEl.scrollTop > 24;
  });

  document.getElementById('btnPause').onclick = function(){
    paused = !paused;
    var b = document.getElementById('btnPause');
    b.textContent = paused ? 'Resume' : 'Pause';
    b.classList.toggle('active', paused);
  };

  document.getElementById('btnClear').onclick = function(){
    fetch('/api/events', { method: 'DELETE' }).then(function(){
      events = [];
      selectedId = null;
      detailEl.innerHTML = '<div class="empty">Select an event</div>';
      applyTrackerRowHighlight();
      renderFeed();
    });
  };

  document.getElementById('filterName').oninput = renderFeed;
  document.getElementById('filterCat').onchange = renderFeed;
  document.getElementById('filterTracker').onchange = renderFeed;

  function pushEvent(data) {
    events.unshift(data);
    while (events.length > 200) events.pop();
    if (!paused) renderFeed();
    else {
      var sel = document.querySelector('.list-item.selected');
      if (sel) { /* keep selection styling */ }
    }
  }

  function handleMessage(raw) {
    try {
      var msg = JSON.parse(raw);
      if (msg.type === 'status') renderStatus(msg.data);
      else if (msg.type === 'event' && msg.data) pushEvent(msg.data);
    } catch (e) {}
  }

  function connectWs() {
    if (reconnectTimer) { clearTimeout(reconnectTimer); reconnectTimer = null; }
    var proto = location.protocol === 'https:' ? 'wss:' : 'ws:';
    var url = proto + '//' + location.host + '/ws';
    setConn(false);
    ws = new WebSocket(url);
    ws.onopen = function(){ setConn(true); };
    ws.onclose = function(){ setConn(false); reconnectTimer = setTimeout(connectWs, 2000); };
    ws.onerror = function(){ try { ws.close(); } catch(e){} };
    ws.onmessage = function(ev){ handleMessage(ev.data); };
  }

  fetch('/api/status').then(function(r){ return r.json(); }).then(renderStatus);
  fetch('/api/events').then(function(r){ return r.json(); }).then(function(arr){
    events = (arr || []).slice().reverse();
    renderFeed();
  });
  connectWs();
})();
</script>
</body>
</html>
''';
