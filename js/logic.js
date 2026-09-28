/* GiftGenius core logic — pure functions, no DOM. Shared by app + tests. */
"use strict";

const INTERESTS = ["gaming","tech","cooking","garden","fitness","reading","music","art",
  "outdoors","travel","pets","photo","movies","crafts","boardgames","selfcare","kids",
  "fashion","coffee","plants","wine","sports","science"];
const INTEREST_LABELS = { gaming:"gaming", tech:"tech", cooking:"cooking", garden:"gardening",
  fitness:"fitness", reading:"reading", music:"music", art:"art", outdoors:"the outdoors",
  travel:"travel", pets:"pets", photo:"photography", movies:"movies", crafts:"crafts & DIY",
  boardgames:"board games", selfcare:"self-care", kids:"kid stuff", fashion:"fashion",
  coffee:"coffee & tea", plants:"plants", wine:"wine", sports:"sports", science:"science" };
const AGE_BANDS = ["kid","teen","adult","senior"];
const AGE_LABELS = { kid:"kid (0–12)", teen:"teen (13–19)", adult:"adult (20–59)", senior:"senior (60+)" };

function _bank() {
  if (typeof GIFT_BANK !== "undefined") return GIFT_BANK;
  try { return require("./giftbank.js").GIFT_BANK; } catch (e) { return []; }
}

/* Days from todayISO to dateISO (both YYYY-MM-DD), UTC-midnight math. */
function daysUntil(dateISO, todayISO) {
  const ms = Date.parse(dateISO + "T00:00:00Z") - Date.parse(todayISO + "T00:00:00Z");
  return Math.round(ms / 86400000);
}

/* Plain-language nudge for an occasion N days away. null = no nudge. */
function occasionNudge(days) {
  if (days < 0) return "That date already passed — move it to next year or delete it.";
  if (days === 0) return "It's TODAY — grab one of these ideas now!";
  if (days <= 7) return `Only ${days} day${days===1?"":"s"} left — pick a gift this week.`;
  if (days <= 21) return `${days} days away — a good time to order so it arrives on time.`;
  return null;
}

/* Notes keyword boost: +2 per matching word, capped at +6. */
function _notesBoost(gift, notes) {
  if (!notes) return 0;
  const words = notes.toLowerCase().split(/[^a-z]+/).filter(w => w.length > 3);
  if (!words.length) return 0;
  const hay = (gift.n + " " + gift.d).toLowerCase();
  let hits = 0;
  for (const w of words) if (hay.includes(w)) hits++;
  return Math.min(hits * 2, 6);
}

function scoreGift(gift, person, occasion) {
  const hits = gift.i.filter(k => person.interests.includes(k));
  let score = hits.length * 12;
  if (gift.a.includes(person.ageBand)) score += 8; else score -= 6;
  const budget = occasion && occasion.budget;
  if (budget && budget > 0) {
    if (gift.hi <= budget) score += 10;
    else if (gift.lo <= budget) score += 4;
    else score -= 25;
  }
  score += _notesBoost(gift, person.notes);
  return { score, hits };
}

/* wasBought: array of {personId, name}; hidden: array of gift names for this person */
function suggestGifts(person, occasion, wasBought, hidden, topN) {
  const bank = _bank();
  topN = topN || 5;
  const boughtNames = new Set((wasBought || []).filter(b => b.personId === person.id).map(b => b.name));
  const hiddenNames = new Set(hidden || []);
  const scored = [];
  for (const g of bank) {
    if (boughtNames.has(g.n) || hiddenNames.has(g.n)) continue;
    const { score, hits } = scoreGift(g, person, occasion);
    scored.push({ gift: g, score, hits });
  }
  scored.sort((a, b) => b.score - a.score || a.gift.lo - b.gift.lo);
  return scored.slice(0, topN);
}

function whyLine(scored, person, occasion) {
  const g = scored.gift;
  const parts = [];
  if (scored.hits.length) {
    const labels = scored.hits.slice(0, 2).map(k => INTEREST_LABELS[k] || k);
    parts.push(`Matches their love of ${labels.join(" and ")}`);
  } else {
    parts.push(`A safe crowd-pleaser for a ${AGE_LABELS[person.ageBand] || person.ageBand}`);
  }
  if (occasion && occasion.budget > 0) {
    if (g.hi <= occasion.budget) parts.push(`fits the $${occasion.budget} budget`);
    else if (g.lo <= occasion.budget) parts.push(`starts at $${g.lo}, inside the $${occasion.budget} budget`);
  }
  return parts.join(" and ") + ".";
}

function priceRange(g) { return g.lo === g.hi ? `$${g.lo}` : `$${g.lo}–$${g.hi}`; }

function spentForOccasion(bought, occasionId) {
  return (bought || []).filter(b => b.occasionId === occasionId)
    .reduce((s, b) => s + (Number(b.price) || 0), 0);
}

function upcomingOccasions(occasions, people, todayISO) {
  return (occasions || [])
    .map(o => {
      const days = daysUntil(o.date, todayISO);
      const person = (people || []).find(p => p.id === o.personId);
      return { occasion: o, person, days, nudge: occasionNudge(days) };
    })
    .filter(x => x.days >= 0)
    .sort((a, b) => a.days - b.days);
}

if (typeof module !== "undefined" && module.exports) {
  module.exports = { INTERESTS, INTEREST_LABELS, AGE_BANDS, AGE_LABELS,
    daysUntil, occasionNudge, scoreGift, suggestGifts, whyLine, priceRange,
    spentForOccasion, upcomingOccasions };
}
