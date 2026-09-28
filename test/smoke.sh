#!/usr/bin/env bash
# GiftGenius smoke tests — 12 checks. Exit non-zero on first failure.
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

echo "--- smoke: $pass passed, $fail failed ---"
exit $((fail>0))
