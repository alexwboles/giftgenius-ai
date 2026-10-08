#!/usr/bin/env bash
# GiftGenius smoke tests — 17 checks. Exit non-zero on first failure.
set -u
cd "$(dirname "$0")/.."
pass=0; fail=0
check() { # $1 = description, rest = command
  local desc="$1"; shift
  if "$@" >/dev/null 2>&1; then echo "PASS: $desc"; pass=$((pass+1));
  else echo "FAIL: $desc"; fail=$((fail+1)); fi
}

check "index.html exists" test -f index.html
check "css/style.css exists" test -f css/style.css
check "js/giftbank.js exists" test -f js/giftbank.js
check "js/logic.js exists" test -f js/logic.js
check "js/app.js exists" test -f js/app.js
check "giftbank.js syntax valid" node --check js/giftbank.js
check "logic.js syntax valid" node --check js/logic.js
check "app.js syntax valid" node --check js/app.js
check "bank has 100+ ideas" node -e "const b=require('./js/giftbank.js').GIFT_BANK; if(b.length<100) throw new Error('only '+b.length)"
check "all entries have n/d/i/a/lo/hi and lo<=hi" node -e "
  const b=require('./js/giftbank.js').GIFT_BANK;
  for (const g of b) {
    if(!g.n||!g.d||!Array.isArray(g.i)||!g.i.length||!Array.isArray(g.a)||!g.a.length) throw new Error('bad fields: '+g.n);
    if(!(g.lo>0&&g.hi>=g.lo)) throw new Error('bad price: '+g.n);
  }"
check "suggestGifts returns 5 for sample person" node -e "
  const L=require('./js/logic.js');
  const p={id:'p1',name:'Maya',ageBand:'teen',interests:['gaming'],notes:''};
  const s=L.suggestGifts(p,{budget:50},[],[],5);
  if(s.length!==5) throw new Error('got '+s.length);"
check "daysUntil math (2026-12-25 from 2026-12-20 = 5)" node -e "
  const L=require('./js/logic.js');
  if(L.daysUntil('2026-12-25','2026-12-20')!==5) throw new Error('bad math');"
check "updatePerson edits name/age/interests/notes, unknown id false" node -e "
  const L=require('./js/logic.js');
  const people=[{id:'p1',name:'Maya',ageBand:'teen',interests:['gaming'],notes:''}];
  if(!L.updatePerson(people,'p1',{name:'Maya R.',ageBand:'adult',interests:['reading','bogus'],notes:'likes tea'})) throw new Error('update failed');
  const p=people[0];
  if(p.name!=='Maya R.'||p.ageBand!=='adult'||p.notes!=='likes tea') throw new Error('fields wrong: '+JSON.stringify(p));
  if(p.interests.join()!=='reading') throw new Error('bad interest leaked: '+p.interests);
  if(L.updatePerson(people,'nope',{name:'x'})) throw new Error('unknown id should be false');"
check "updateOccasion edits date/budget, rejects bad date" node -e "
  const L=require('./js/logic.js');
  const occs=[{id:'o1',name:'Birthday',date:'2026-11-01',budget:50}];
  if(!L.updateOccasion(occs,'o1',{date:'2026-11-05',budget:75})) throw new Error('update failed');
  if(occs[0].date!=='2026-11-05'||occs[0].budget!==75) throw new Error('fields wrong');
  L.updateOccasion(occs,'o1',{date:'not-a-date'});
  if(occs[0].date!=='2026-11-05') throw new Error('bad date accepted');
  if(L.updateOccasion(occs,'nope',{budget:1})) throw new Error('unknown id should be false');"
check "budgetOverview totals budgeted vs spent" node -e "
  const L=require('./js/logic.js');
  const people=[{id:'p1',name:'Maya'}];
  const occs=[{id:'o1',personId:'p1',name:'Birthday',date:'2026-12-25',budget:100},
              {id:'o2',personId:'p1',name:'Holiday',date:'2026-12-26',budget:0}];
  const bought=[{occasionId:'o1',price:25},{occasionId:'o1',price:10}];
  const ov=L.budgetOverview(occs,people,bought,'2026-10-07');
  if(ov.occasions!==2||ov.withBudget!==1) throw new Error('counts: '+JSON.stringify(ov));
  if(ov.budgeted!==100||ov.spent!==35||ov.remaining!==65) throw new Error('money: '+JSON.stringify(ov));"
check "toggleShortlist stars then unstars" node -e "
  const L=require('./js/logic.js');
  const sl=L.toggleShortlist({},'o1','Chess set');
  if(sl.o1.join()!=='Chess set') throw new Error('star failed');
  L.toggleShortlist(sl,'o1','Chess set');
  if(sl.o1.length!==0) throw new Error('unstar failed');"
check "boughtToCSV header + quoted row" node -e "
  const L=require('./js/logic.js');
  const people=[{id:'p1',name:'Maya'}];
  const csv=L.boughtToCSV([{personId:'p1',name:'Chess, \"deluxe\"',price:40,year:2026}],people).split('\n');
  if(csv[0]!=='gift,person,year,price') throw new Error('header: '+csv[0]);
  if(csv[1]!=='\"Chess, \"\"deluxe\"\"\",Maya,2026,40') throw new Error('row: '+csv[1]);"

echo "--- smoke: $pass passed, $fail failed ---"
exit $((fail>0))
