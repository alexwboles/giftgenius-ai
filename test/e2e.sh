#!/usr/bin/env bash
# GiftGenius e2e tests — 6 flows exercising real logic in Node. Exit non-zero on failure.
set -u
cd "$(dirname "$0")/.."
pass=0; fail=0
flow() { # $1 = description, $2 = node script
  if node -e "$2" >/dev/null 2>&1; then echo "PASS: $1"; pass=$((pass+1));
  else echo "FAIL: $1"; fail=$((fail+1)); fi
}

flow "gamer teen gets gaming ideas, not gardening" "
  const L=require('./js/logic.js');
  const p={id:'p1',name:'Alex',ageBand:'teen',interests:['gaming'],notes:''};
  const s=L.suggestGifts(p,{budget:200},[],[],5);
  const names=s.map(x=>x.gift.n).join('|');
  if(!s[0].gift.i.includes('gaming')) throw new Error('top pick not gaming: '+s[0].gift.n);
  if(/Garden tool set|Bird feeder|Kneeling pad/.test(names)) throw new Error('gardening leaked in: '+names);
"

flow "budget filter respected (\$20 budget -> all lo<=20)" "
  const L=require('./js/logic.js');
  const p={id:'p1',name:'Sam',ageBand:'adult',interests:['reading','cooking','tech'],notes:''};
  const s=L.suggestGifts(p,{budget:20},[],[],5);
  for(const x of s){ if(x.gift.lo>20) throw new Error('over budget: '+x.gift.n+' lo='+x.gift.lo); }
"

flow "bought gift is excluded from future suggestions" "
  const L=require('./js/logic.js');
  const p={id:'p1',name:'Maya',ageBand:'adult',interests:['plants'],notes:''};
  const first=L.suggestGifts(p,{budget:100},[],[],5)[0].gift.n;
  const again=L.suggestGifts(p,{budget:100},[{personId:'p1',name:first}],[],5).map(x=>x.gift.n);
  if(again.includes(first)) throw new Error('bought gift still suggested: '+first);
"

flow "hidden gift is excluded" "
  const L=require('./js/logic.js');
  const p={id:'p1',name:'Maya',ageBand:'adult',interests:['plants'],notes:''};
  const first=L.suggestGifts(p,{budget:100},[],[],5)[0].gift.n;
  const again=L.suggestGifts(p,{budget:100},[],[first],5).map(x=>x.gift.n);
  if(again.includes(first)) throw new Error('hidden gift still suggested: '+first);
"

flow "countdown + nudge math (12 days -> nudge mentions 12 days)" "
  const L=require('./js/logic.js');
  const d=L.daysUntil('2026-10-10','2026-09-28');
  if(d!==12) throw new Error('days='+d);
  const n=L.occasionNudge(12);
  if(!/12 days/.test(n)) throw new Error('nudge: '+n);
  if(L.occasionNudge(60)!==null) throw new Error('far occasion should have no nudge');
  if(!/Only 3 days/.test(L.occasionNudge(3))) throw new Error('urgent nudge wrong');
"

flow "senior gardener gets garden ideas + budget tracker sums spent" "
  const L=require('./js/logic.js');
  const p={id:'p9',name:'Ruth',ageBand:'senior',interests:['garden'],notes:''};
  const s=L.suggestGifts(p,{budget:100},[],[],5);
  if(!s[0].gift.i.includes('garden')) throw new Error('top pick not garden: '+s[0].gift.n);
  const spent=L.spentForOccasion(
    [{occasionId:'o1',price:25},{occasionId:'o1',price:30},{occasionId:'o2',price:99}],'o1');
  if(spent!==55) throw new Error('spent='+spent);
  const w=L.whyLine(s[0],p,{budget:100});
  if(!w || w.length<10) throw new Error('whyLine empty');
"

flow "edit person interests -> suggestions shift, then star the top pick" "
  const L=require('./js/logic.js');
  const people=[{id:'p1',name:'Sam',ageBand:'adult',interests:['sports'],notes:''}];
  const s0=L.suggestGifts(people[0],{budget:80},[],[],5);
  if(s0[0].gift.i.includes('reading')) throw new Error('unexpectedly reading first: '+s0[0].gift.n);
  L.updatePerson(people,'p1',{interests:['reading']});
  const s1=L.suggestGifts(people[0],{budget:80},[],[],5);
  if(!s1[0].gift.i.includes('reading')) throw new Error('reading update not reflected: '+s1.map(x=>x.gift.n).join(','));
  const sl=L.toggleShortlist({},'o1',s1[0].gift.n);
  if(!sl.o1.includes(s1[0].gift.n)) throw new Error('star failed');
"

flow "edit occasion budget + date -> budget overview updates" "
  const L=require('./js/logic.js');
  const people=[{id:'p1',name:'Maya'}];
  const occs=[{id:'o1',personId:'p1',name:'Birthday',date:'2026-12-25',budget:100}];
  const bought=[{occasionId:'o1',price:25}];
  let ov=L.budgetOverview(occs,people,bought,'2026-10-07');
  if(ov.remaining!==75) throw new Error('remaining='+ov.remaining);
  L.updateOccasion(occs,'o1',{budget:60});
  ov=L.budgetOverview(occs,people,bought,'2026-10-07');
  if(ov.budgeted!==60||ov.remaining!==35) throw new Error('after edit: '+JSON.stringify(ov));
  L.updateOccasion(occs,'o1',{date:'2025-01-01'});
  ov=L.budgetOverview(occs,people,bought,'2026-10-07');
  if(ov.occasions!==0) throw new Error('moved-past occasion still counted');
"

flow "bought CSV round-trips a gift with commas and quotes" "
  const L=require('./js/logic.js');
  const people=[{id:'p1',name:'Maya'}];
  const bought=[{personId:'p1',name:'Chess, \"deluxe\" edition',price:40,year:2026,occasionId:'o1'}];
  const lines=L.boughtToCSV(bought,people).split('\n');
  if(lines.length!==2) throw new Error('line count '+lines.length);
  if(!/^\"Chess, \"\"deluxe\"\" edition\",Maya,2026,40$/.test(lines[1])) throw new Error('row: '+lines[1]);
"

echo "--- e2e: $pass passed, $fail failed ---"
exit $((fail>0))
