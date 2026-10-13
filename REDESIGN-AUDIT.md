# Redesign Audit — giftgenius-ai (2026-10-13)

**Competitors studied:** Gift Whisperer / Giftella (AI-curated gift cards: price bands, "why it works" copy, recipient-interest matching, shortlists), Occasional.ly (occasion countdowns, budget tracking), traditional gift-guide editorial (ranked lists, fit reasoning).

## Visual gaps
1. **Theme is neutral/generic.** Gift products are warm and boutique — gift-wrap, ribbon, curated-card aesthetics. Ours looks like a utility form. → "gift boutique" identity: kraft-cream paper, deep garnet ribbon accent, gold rules, Fraunces serif display.
2. **Suggestion cards are text rows.** Giftella shows curated gift cards with fit reasoning and price bands. Ours buries score + why in plain text. → ranked gift cards: rank medallion, fit-score ring, interest-match tags, "why it fits" ribbon note, price pill.
3. **Person cards list interests as flat text.** → interest tag pills.
4. **Occasion cards have countdowns but no visual urgency.** → countdown numerals with "hot" styling preserved + refined.

## Functional / flow gaps
1. **Fit score invisible.** → fit-score ring on each suggestion (score normalized 0–60).
2. **Interest tags.** → pills on person cards (data already stored).

## Decisions
- Keep: people CRUD + interest chips, occasions + past/rollover, suggestion engine (score/why), shortlist starring, custom ideas, bought log + split purchase + CSV.
- Identity: "the gift boutique" — kraft paper, garnet ribbon, gold, serif, sharp corners.
