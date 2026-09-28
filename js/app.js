/* GiftGenius browser app — all data stays in localStorage. */
(function () {
  "use strict";
  const LS_KEY = "giftgenius.v1";
  const todayISO = () => new Date().toISOString().slice(0, 10);
  const uid = () => Math.random().toString(36).slice(2, 10);

  function load() {
    try {
      const raw = localStorage.getItem(LS_KEY);
      if (raw) { const d = JSON.parse(raw); return Object.assign({ people: [], occasions: [], bought: [], hidden: {} }, d); }
    } catch (e) {}
    return { people: [], occasions: [], bought: [], hidden: {} };
  }
  function save() { localStorage.setItem(LS_KEY, JSON.stringify(state)); }
  let state = load();

  const $ = id => document.getElementById(id);
  const esc = s => String(s == null ? "" : s).replace(/[&<>"']/g, c => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));

  function personName(id) { const p = state.people.find(p => p.id === id); return p ? p.name : "Someone"; }

  /* ---------- tabs ---------- */
  function showTab(name) {
    document.querySelectorAll(".tab").forEach(t => t.classList.toggle("active", t.dataset.tab === name));
    document.querySelectorAll(".panel").forEach(p => p.classList.toggle("active", p.id === "panel-" + name));
    if (name === "people") renderPeople();
    if (name === "occasions") renderOccasions();
    if (name === "find") renderFind();
    if (name === "bought") renderBought();
  }
  document.querySelectorAll(".tab").forEach(t => t.addEventListener("click", () => showTab(t.dataset.tab)));

  /* ---------- reminder banner ---------- */
  function renderBanner() {
    const up = upcomingOccasions(state.occasions, state.people, todayISO()).filter(x => x.nudge);
    const b = $("banner");
    if (!up.length) { b.style.display = "none"; return; }
    b.style.display = "flex";
    b.innerHTML = '<span class="b-dot" aria-hidden="true"></span><div>' + up.slice(0, 3).map(x =>
      `<strong>${esc(x.person ? x.person.name : "Someone")}</strong> — ${esc(x.occasion.name)}: ${esc(x.nudge)}`
    ).join("<br>") + "</div>";
  }

  /* ---------- people ---------- */
  function renderPeople() {
    const list = $("peopleList");
    list.innerHTML = state.people.length ? state.people.map(p =>
      `<div class="card"><div class="card-head"><strong>${esc(p.name)}</strong>
       <span class="pill">${esc(AGE_LABELS[p.ageBand] || p.ageBand)}</span>
       <button class="link" data-del-person="${p.id}">remove</button></div>
       <div class="muted">${p.interests.map(k => esc(INTEREST_LABELS[k] || k)).join(" · ") || "no interests yet"}</div>
       ${p.notes ? `<div class="note-line">${esc(p.notes)}</div>` : ""}</div>`
    ).join("") : `<div class="empty">No people yet — add your first person above.</div>`;
    list.querySelectorAll("[data-del-person]").forEach(btn => btn.addEventListener("click", () => {
      const id = btn.dataset.delPerson;
      state.people = state.people.filter(p => p.id !== id);
      state.occasions = state.occasions.filter(o => o.personId !== id);
      save(); renderPeople(); renderBanner();
    }));
  }
  $("personForm").addEventListener("submit", e => {
    e.preventDefault();
    const name = $("pName").value.trim(); if (!name) return;
    const interests = [...document.querySelectorAll(".int-chip.selected")].map(c => c.dataset.k);
    state.people.push({ id: uid(), name, ageBand: $("pAge").value, interests, notes: $("pNotes").value.trim() });
    save(); e.target.reset();
    document.querySelectorAll(".int-chip.selected").forEach(c => c.classList.remove("selected"));
    renderPeople(); renderBanner();
  });
  document.querySelectorAll(".int-chip").forEach(c => c.addEventListener("click", () => c.classList.toggle("selected")));

  /* ---------- occasions ---------- */
  function renderOccasions() {
    const up = upcomingOccasions(state.occasions, state.people, todayISO());
    $("occList").innerHTML = up.length ? up.map(x => {
      const spent = spentForOccasion(state.bought, x.occasion.id);
      const bud = x.occasion.budget || 0;
      const pct = bud > 0 ? Math.min(100, Math.round(spent / bud * 100)) : 0;
      return `<div class="card"><div class="card-head"><strong>${esc(x.person ? x.person.name : "?")}</strong>
        <span class="pill">${esc(x.occasion.name)}</span>
        <span class="pill ${x.days <= 7 ? "hot" : ""}">${x.days === 0 ? "today!" : "in " + x.days + "d"}</span>
        <button class="link" data-del-occ="${x.occasion.id}">remove</button></div>
        <div class="muted">${esc(x.occasion.date)}${bud ? ` · budget $${bud} · spent $${spent}` : ""}</div>
        ${bud ? `<div class="bar"><div style="width:${pct}%"></div></div>` : ""}
        ${x.nudge ? `<div class="nudge">${esc(x.nudge)}</div>` : ""}</div>`;
    }).join("") : `<div class="empty">No upcoming occasions — add one above.</div>`;
    $("occList").querySelectorAll("[data-del-occ]").forEach(btn => btn.addEventListener("click", () => {
      state.occasions = state.occasions.filter(o => o.id !== btn.dataset.delOcc);
      save(); renderOccasions(); renderBanner();
    }));
    const sel = $("oPerson");
    sel.innerHTML = state.people.map(p => `<option value="${p.id}">${esc(p.name)}</option>`).join("");
  }
  $("occForm").addEventListener("submit", e => {
    e.preventDefault();
    const personId = $("oPerson").value; if (!personId) { alert("Add a person first."); return; }
    state.occasions.push({ id: uid(), personId, name: $("oName").value.trim() || "Birthday",
      date: $("oDate").value, budget: Number($("oBudget").value) || 0 });
    save(); e.target.reset(); renderOccasions(); renderBanner();
  });

  /* ---------- find gifts ---------- */
  let lastSuggestions = [];
  function renderFind() {
    $("fPerson").innerHTML = state.people.map(p => `<option value="${p.id}">${esc(p.name)}</option>`).join("");
    syncOccOptions();
  }
  function syncOccOptions() {
    const pid = $("fPerson").value;
    const occs = state.occasions.filter(o => o.personId === pid);
    $("fOcc").innerHTML = occs.length
      ? occs.map(o => `<option value="${o.id}">${esc(o.name)} — ${esc(o.date)}</option>`).join("")
      : `<option value="">No occasion (general ideas)</option>`;
  }
  $("fPerson").addEventListener("change", syncOccOptions);
  $("findBtn").addEventListener("click", () => {
    const person = state.people.find(p => p.id === $("fPerson").value);
    if (!person) { alert("Add a person first."); return; }
    const occasion = state.occasions.find(o => o.id === $("fOcc").value) || { budget: 0, name: "Gift" };
    lastSuggestions = suggestGifts(person, occasion, state.bought, state.hidden[person.id] || [], 5)
      .map(s => ({ personId: person.id, occasionId: occasion.id || null, score: s.score, why: whyLine(s, person, occasion), gift: s.gift }));
    renderSuggestions(person, occasion);
  });
  function renderSuggestions(person, occasion) {
    const box = $("suggList");
    if (!lastSuggestions.length) { box.innerHTML = `<div class="empty">No ideas left — everything's bought or hidden for ${esc(person.name)}!</div>`; return; }
    box.innerHTML = lastSuggestions.map((s, i) =>
      `<div class="card gift"><div class="card-head"><strong>${i + 1}. ${esc(s.gift.n)}</strong>
       <span class="pill">${priceRange(s.gift)}</span></div>
       <div class="muted">${esc(s.gift.d)}</div>
       <div class="why"><span class="why-mark">Why it fits</span>${esc(s.why)}</div>
       <div class="row"><button class="btn small" data-buy="${i}">Mark bought</button>
       <button class="btn small ghost" data-hide="${i}">Hide</button>
       <button class="btn small ghost" data-ai="${i}">AI note</button></div>
       <div class="ai-note" id="ainote-${i}" style="display:none"></div></div>`
    ).join("");
    box.querySelectorAll("[data-buy]").forEach(b => b.addEventListener("click", () => {
      const s = lastSuggestions[+b.dataset.buy];
      const price = prompt(`How much did "${s.gift.n}" cost? (optional)`, "") || "";
      state.bought.push({ personId: s.personId, occasionId: s.occasionId, name: s.gift.n, price: Number(price) || 0, year: new Date().getFullYear() });
      save(); $("findBtn").click(); renderBanner();
    }));
    box.querySelectorAll("[data-hide]").forEach(b => b.addEventListener("click", () => {
      const s = lastSuggestions[+b.dataset.hide];
      (state.hidden[s.personId] = state.hidden[s.personId] || []).push(s.gift.n);
      save(); $("findBtn").click();
    }));
    box.querySelectorAll("[data-ai]").forEach(b => b.addEventListener("click", () => enhanceWithAI(+b.dataset.ai)));
  }
  async function enhanceWithAI(i) {
    const s = lastSuggestions[i];
    const note = $("ainote-" + i);
    note.style.display = "block"; note.textContent = "Thinking…";
    const key = ($("aiKey").value || "").trim();
    if (!key) { note.textContent = "Add your OpenAI API key above to get a personalized AI note — everything else works without it."; return; }
    try {
      const resp = await fetch("https://api.openai.com/v1/chat/completions", {
        method: "POST",
        headers: { "Content-Type": "application/json", "Authorization": "Bearer " + key },
        body: JSON.stringify({ model: "gpt-4o-mini",
          messages: [{ role: "user", content: `In one warm sentence, why is "${s.gift.n}" (${s.gift.d}) a thoughtful gift? Why: ${s.why}` }],
          max_tokens: 80 })
      });
      if (!resp.ok) throw new Error("API error");
      const data = await resp.json();
      note.textContent = data.choices[0].message.content.trim();
    } catch (e) { note.textContent = "Couldn't reach the AI brain — the idea above is still solid on its own."; }
  }

  /* ---------- bought ---------- */
  function renderBought() {
    const items = [...state.bought].reverse();
    $("boughtList").innerHTML = items.length ? items.map((b, ri) => {
      const i = items.length - 1 - ri;
      return `<div class="card"><div class="card-head"><strong>${esc(b.name)}</strong>
        <span class="pill">${esc(personName(b.personId))}</span>
        ${b.price ? `<span class="pill">$${esc(b.price)}</span>` : ""}
        <span class="muted">${esc(b.year)}</span>
        <button class="link" data-unbuy="${i}">undo</button></div></div>`;
    }).join("") : `<div class="empty">Nothing marked as bought yet.</div>`;
    $("boughtList").querySelectorAll("[data-unbuy]").forEach(btn => btn.addEventListener("click", () => {
      state.bought.splice(+btn.dataset.unbuy, 1); save(); renderBought();
    }));
  }

  renderBanner();
  showTab("people");
})();
