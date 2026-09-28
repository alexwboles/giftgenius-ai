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

echo "--- e2e: $pass passed, $fail failed ---"
exit $((fail>0))
