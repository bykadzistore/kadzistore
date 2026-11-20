#!/usr/bin/env python3
from pathlib import Path
import sys

path = Path(sys.argv[1] if len(sys.argv) > 1 else "admin.html")
s = path.read_text(encoding="utf-8")
changes = 0

def replace_once(old, new, label):
    global s, changes
    count = s.count(old)
    if count != 1:
        raise SystemExit(f"Не удалось применить патч: {label}; найдено совпадений: {count}")
    s = s.replace(old, new, 1)
    changes += 1

replace_once(
    '<button id="sanctionsTab">Наказания</button></div>',
    '<button id="sanctionsTab">Наказания</button><button id="amlTab">AML / Антифрод</button></div>',
    "вкладка AML"
)
replace_once(
    '</section>\n<section id="sanctionsSection" class="hide">',
    '''</section>
<section id="amlSection" class="hide">
 <div class="panel"><div class="number">Проверки AML / антифрод</div><div class="muted">Подозрительные сделки и связанные заявки на вывод. Изучи детали, затем сними отметку или подтверди ограничение. Выплаты с открытой AML-проверкой блокируются сервером.</div><div class="actions"><button class="primary" id="amlReload">Обновить проверки</button><span class="muted" id="amlUpdated"></span></div><div id="amlCases" class="muted">Загрузка проверок...</div></div>
 <div class="panel"><div class="number">Заявки на вывод средств</div><div class="muted">Кнопка «Выплачено» дополнительно проверяется сервером. При открытом AML-кейсе сервер не разрешит выплату.</div><div id="amlWithdrawals" class="muted">Загрузка заявок...</div></div>
</section>
<section id="sanctionsSection" class="hide">''',
    "секция AML"
)
replace_once(
    '["ordersSection","productsSection","inventorySection","announcementsSection","gamesSection","analyticsSection","auditSection","marketplaceSection","sanctionsSection"]',
    '["ordersSection","productsSection","inventorySection","announcementsSection","gamesSection","analyticsSection","auditSection","marketplaceSection","sanctionsSection","amlSection"]',
    "переключение секций"
)
replace_once(
    '["ordersTab","productsTab","inventoryTab","announcementsTab","gamesTab","analyticsTab","auditTab","marketplaceTab","sanctionsTab"]',
    '["ordersTab","productsTab","inventoryTab","announcementsTab","gamesTab","analyticsTab","auditTab","marketplaceTab","sanctionsTab","amlTab"]',
    "подсветка вкладок"
)
replace_once(
    'if(which==="marketplaceSection")loadMarketplaceAdmin();}',
    'if(which==="marketplaceSection")loadMarketplaceAdmin();if(which==="amlSection")loadAmlPanel();}',
    "загрузка AML при открытии"
)
replace_once(
    'document.getElementById("sanctionsTab").onclick=()=>showAdminSection("sanctionsSection");',
    'document.getElementById("sanctionsTab").onclick=()=>showAdminSection("sanctionsSection");\ndocument.getElementById("amlTab").onclick=()=>showAdminSection("amlSection");',
    "обработчик вкладки"
)
aml_js = r'''
// AML / anti-fraud review queue. Server-side rules remain authoritative.
let amlCases=[], amlWithdrawals=[];
const amlRuleNames={
 RECIPROCAL_TRADING:"Встречная торговля между аккаунтами",
 REPEATED_COUNTERPARTY:"Повторные сделки между одной парой",
 HIGH_VELOCITY_SELLING:"Высокая скорость продаж",
 NEW_ACCOUNT_HIGH_TURNOVER:"Оборот нового аккаунта",
 MANY_COUNTERPARTIES_HIGH_VOLUME:"Много контрагентов и высокий оборот",
 HIGH_DISPUTE_REFUND_RATE:"Высокая доля споров и возвратов",
 HIGH_30D_TURNOVER:"Высокий оборот за 30 дней"
};
function renderAmlPanel(){
 const casesEl=document.getElementById("amlCases"), withdrawalsEl=document.getElementById("amlWithdrawals");
 casesEl.innerHTML=amlCases.length?amlCases.map(c=>{
  const u=c.kds_users||{},name=[u.first_name,u.username?"@"+u.username:null].filter(Boolean).join(" · ")||"Пользователь";
  const rules=(c.rule_codes||[]).map(x=>amlRuleNames[x]||x).join(" · ")||"Правила не указаны";
  const details=typeof c.details==="string"?c.details:JSON.stringify(c.details||{});
  return '<article class="market-admin-card"><div class="product-head"><h3>Риск '+esc(c.risk_score)+'/100 · '+esc(c.severity||"review")+'</h3><span class="status">'+esc(c.status||"open")+'</span></div><p>'+esc(name)+' · Telegram ID: '+esc(u.telegram_user_id||"—")+'</p><p><b>Причины:</b> '+esc(rules)+'</p><p><b>Детали:</b> '+esc(details)+'</p><p class="muted">Создано: '+new Date(c.created_at).toLocaleString("ru-RU")+' · Кейс: '+esc(c.id)+'</p><div class="market-admin-actions"><button class="good" data-aml-decision="clear" data-aml-case="'+esc(c.id)+'">Снять отметку после проверки</button><button class="warn" data-aml-decision="restrict" data-aml-case="'+esc(c.id)+'">Подтвердить риск / оставить блок</button></div></article>';
 }).join(""):'<div class="notice">Открытых AML-кейсов нет.</div>';
 withdrawalsEl.innerHTML=amlWithdrawals.length?amlWithdrawals.map(w=>{
  const u=w.kds_users||{},name=[u.first_name,u.username?"@"+u.username:null].filter(Boolean).join(" · ")||"Пользователь";
  const risk=!!w.risk_review_required;
  const payoutDisabled=risk?' disabled title="Сначала требуется AML-проверка"':'';
  return '<article class="market-admin-card"><div class="product-head"><h3>'+money(w.amount_rub)+' · '+esc(w.payout_method||"Выплата")+'</h3><span class="status">'+esc(w.status||"")+'</span></div><p>'+esc(name)+' · Telegram ID: '+esc(u.telegram_user_id||"—")+'</p><p>Реквизиты: '+esc(w.payout_details||"")+'</p><p>Риск при заявке: '+esc(w.risk_score_at_request??"—")+'/100 · AML-проверка: '+(risk?'<b class="error">Требуется</b>':'не отмечена')+'</p><p class="muted">Создано: '+new Date(w.created_at).toLocaleString("ru-RU")+' · ID: '+esc(w.id)+'</p>'+(w.status==="pending"?'<div class="market-admin-actions"><button class="good" data-aml-withdrawal="paid" data-withdrawal-id="'+esc(w.id)+'"'+payoutDisabled+'>Выплачено</button><button class="warn" data-aml-withdrawal="rejected" data-withdrawal-id="'+esc(w.id)+'">Отклонить</button></div>':"")+'</article>';
 }).join(""):'<div class="notice">Заявок на вывод нет.</div>';
}
async function loadAmlPanel(){
 const casesEl=document.getElementById("amlCases"),withdrawalsEl=document.getElementById("amlWithdrawals");
 casesEl.innerHTML='<div class="notice">Загружаю AML-кейсы…</div>';withdrawalsEl.innerHTML='<div class="notice">Загружаю заявки…</div>';
 try{
  const [c,w]=await Promise.all([
   api("POST",{action:"list_aml_cases"}),
   api("POST",{action:"list_withdrawals"})
  ]);
  amlCases=c.cases||[];amlWithdrawals=w.withdrawals||[];
  renderAmlPanel();document.getElementById("amlUpdated").textContent="Обновлено: "+new Date().toLocaleTimeString("ru-RU");
 }catch(e){casesEl.innerHTML='<div class="notice error">'+esc(e.message)+'</div>';withdrawalsEl.innerHTML='<div class="notice error">'+esc(e.message)+'</div>';}
}
document.getElementById("amlReload").onclick=loadAmlPanel;
document.getElementById("amlCases").addEventListener("click",async e=>{
 const b=e.target.closest("[data-aml-decision]");if(!b)return;
 const decision=b.dataset.amlDecision,caseId=b.dataset.amlCase;
 const note=prompt(decision==="clear"?"Комментарий: почему кейс можно снять?":"Комментарий к подтверждённому риску:","")||"";
 if(decision==="restrict"&&!note.trim()){alert("Укажи причину подтверждения риска.");return;}
 if(!confirm(decision==="clear"?"Снять AML-ограничение по этому кейсу?":"Подтвердить риск и оставить выводы заблокированными?"))return;
 b.disabled=true;
 try{await api("POST",{action:"resolve_aml_case",case_id:caseId,decision,note});await loadAmlPanel();}
 catch(err){alert(err.message);b.disabled=false;}
});
document.getElementById("amlWithdrawals").addEventListener("click",async e=>{
 const b=e.target.closest("[data-aml-withdrawal]");if(!b)return;
 const decision=b.dataset.amlWithdrawal,id=b.dataset.withdrawalId;
 if(decision==="paid"&&!confirm("Подтверждаешь, что деньги уже реально переведены получателю?"))return;
 const note=prompt(decision==="paid"?"Комментарий к выплате (необязательно):":"Причина отклонения заявки:","")||"";
 if(decision==="rejected"&&!note.trim()){alert("Укажи причину отклонения.");return;}
 b.disabled=true;
 try{await api("POST",{action:"process_withdrawal",request_id:id,decision,admin_note:note});alert(decision==="paid"?"Выплата отмечена выполненной.":"Заявка отклонена.");await loadAmlPanel();}
 catch(err){alert(err.message);b.disabled=false;}
});
'''
replace_once(
    '\n\n// User sanctions: server-enforced block of all financial and marketplace mutations.',
    '\n\n'+aml_js+'\n// User sanctions: server-enforced block of all financial and marketplace mutations.',
    "логика AML"
)
assert 'id="amlSection"' in s and 'action:"list_aml_cases"' in s and 'action:"resolve_aml_case"' in s
path.write_text(s, encoding="utf-8")
print(f"Готово: {path} обновлён. Изменений: {changes}.")
