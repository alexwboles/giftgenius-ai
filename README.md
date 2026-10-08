# 🎁 GiftGenius

**Never panic about gifts again.** GiftGenius keeps profiles of the people you buy for, tracks their occasions with countdowns, and suggests thoughtful, budget-fitting gift ideas from a curated bank of 150+ ideas — all running 100% locally in your browser.

## The problem

Everyone has the same December (or birthday-week) panic: *what do I get them?* You either overspend on something generic, buy a repeat of last year, or order too late. GiftGenius fixes the whole loop:

1. **People profiles** — name, age band, interests, free-text notes ("loves stargazing, hates socks"); edit any profile inline
2. **Occasions with countdowns** — "Maya's birthday in 12 days", with plain-language nudges when time is short, an editable budget strip (budgeted vs spent vs remaining across all upcoming occasions), and inline editing
3. **AI-style suggestions** — top 5 ideas scored by interest match + age fit + budget fit, each with a "why it fits" line; star ideas into a per-occasion shortlist
4. **Budget tracker** — spent-vs-budget bar per occasion
5. **No-repeat memory** — bought gifts are remembered so you never duplicate next year; hide duds per person; export the bought list as CSV
6. **Optional AI notes** — paste your own OpenAI API key for a one-sentence personalized note per idea (never required)

## How to run

No build step, no server, no account. Just open `index.html` in any browser — or serve it statically:

```bash
npx serve .        # or: python3 -m http.server 8080
```

Your data lives in `localStorage` under `giftgenius.v1`. Nothing ever leaves your device.

## How suggestions work

Each gift in `js/giftbank.js` is tagged with interests, age bands, and a price range. Scoring:

- **+12** per matching interest
- **+8** if the age band fits (kid / teen / adult / senior), **−6** if not
- **+10** if it fits inside the occasion budget, **−25** if it's over budget
- **+2** per keyword from your notes matching the gift (capped at +6)
- Bought or hidden gifts are excluded entirely

A gamer teen with a $50 budget gets gaming gear — never gardening gloves.

## Pricing vision (future)

- **Free** — unlimited people, occasions, suggestions
- **Plus $4/mo** — shared family lists, price-drop alerts, printable gift guides
- **Affiliate** — gift ideas link out to retailers via affiliate links (future, clearly labeled)

## Tests

```bash
bash test/smoke.sh   # 12 checks: files, syntax, bank validity, scoring sanity
bash test/e2e.sh     # 6 end-to-end flows in Node: gamer-teen relevance, budget respect,
                     # bought/hidden exclusion, countdown + nudge math, senior-gardener relevance
```

## Project layout

```
index.html        main UI (People / Occasions / Find gifts / Bought)
css/style.css     warm gift-shop theme
js/giftbank.js    150+ curated gift ideas (shared browser + Node)
js/logic.js       pure scoring/countdown/budget logic (shared browser + Node)
js/app.js         browser UI + localStorage
test/smoke.sh     smoke tests
test/e2e.sh       end-to-end logic tests
```

Built free, for free — no paid services, no tracking, no accounts.
