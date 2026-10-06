
/* ===== CERVEJA NA REDE V16 — GRUPO ONLINE FIXO ===== */
const FIXED_STATE_KEYS=['cnr_hist','cnr_tournaments','cnr_current_teams','cnr_match_meta','cnr_match_stats'];
const DEFAULT_CLOUD_CONFIG={url:'https://sewbzgmpkindoftynkqp.supabase.co',key:'sb_publishable_PvY7Ctn-qr2Pu6kWLd5hww_EQH7USYU'};
let cloudClient=null, cloudGroupId='', cloudGroupCode='CRN-1556', cloudPlayersChannel=null, cloudStateChannel=null;
let cloudBusy=false, cloudApplying=false, cloudAuthPromise=null, cloudStateTimers={}, cloudPlayerCache=new Map();

function cloudCfg(){return DEFAULT_CLOUD_CONFIG}
function cloudReady(){const c=cloudCfg();return !!(c?.url&&c?.key&&window.supabase?.createClient)}
function normalizeCode(v){return String(v||'').trim().toUpperCase().replace(/[^A-Z0-9-]/g,'').slice(0,20)}
function cloudErrorMessage(e,fallback){const m=String(e?.message||e?.error_description||e?.details||'').trim();if(/failed to fetch|networkerror|load failed|err_name_not_resolved|dns/i.test(m))return 'Sem acesso ao Supabase. Verifique a internet.';if(/not_authenticated|anonymous|jwt|auth/i.test(m))return 'Não foi possível autenticar este aparelho. Confirme o login anônimo no Supabase.';return m||fallback}

async function initCloudClient(){
  const c=cloudCfg();
  if(!c?.url||!c?.key)throw new Error('Configuração do Supabase ausente.');
  if(!window.supabase?.createClient)throw new Error('Biblioteca Supabase não carregou.');
  if(!cloudClient)cloudClient=window.supabase.createClient(c.url,c.key,{auth:{persistSession:true,autoRefreshToken:true,detectSessionInUrl:false}});
  return cloudClient;
}
async function ensureCloudAuth(){
  if(!cloudClient)await initCloudClient();
  if(cloudAuthPromise)return cloudAuthPromise;
  cloudAuthPromise=(async()=>{
    const cur=await cloudClient.auth.getSession();
    if(cur.error)throw cur.error;
    if(cur.data?.session)return cur.data.session;
    const r=await cloudClient.auth.signInAnonymously();
    if(r.error)throw r.error;
    if(!r.data?.session)throw new Error('Supabase não retornou uma sessão anônima.');
    return r.data.session;
  })().catch(e=>{cloudAuthPromise=null;throw e});
  return cloudAuthPromise;
}
async function fixedGroup(){
  await ensureCloudAuth();
  const {data,error}=await cloudClient.rpc('get_fixed_group');
  if(error)throw error;
  const g=Array.isArray(data)?data[0]:data;
  if(!g?.id)throw new Error('O grupo online fixo não foi localizado.');
  cloudGroupId=String(g.id);cloudGroupCode=normalizeCode(g.code)||'CRN-1556';
  return g;
}

function renderAllFromCloud(){
  players=safeJSON(localStorage.getItem(PKEY)||'[]',[]);
  currentTeams=safeJSON(localStorage.getItem('cnr_current_teams')||'null',[])||[];
  matchMeta=safeJSON(localStorage.getItem('cnr_match_meta')||'null',null)||null;
  tournaments=safeJSON(localStorage.getItem(TKEY)||'[]',[]);
  matchStats=safeJSON(localStorage.getItem('cnr_match_stats')||'{}',{});
  if(typeof renderPlayers==='function')renderPlayers();
  if(typeof renderPresence==='function')renderPresence();
  if(typeof renderTeams==='function')renderTeams();
  if(typeof renderHistory==='function')renderHistory();
  if(typeof renderTournament==='function')renderTournament();
  if(typeof renderMatchStats==='function')renderMatchStats();
}

async function loadFixedData(){
  await ensureCloudAuth();
  const [{data:prs,error:pe},{data:sts,error:se}]=await Promise.all([
    cloudClient.from('fixed_players').select('id,data,updated_at'),
    cloudClient.from('fixed_state').select('key,state,updated_at')
  ]);
  if(pe)throw pe;if(se)throw se;
  cloudPlayerCache=new Map((prs||[]).map(r=>[String(r.id),r.data]));
  const arr=[...cloudPlayerCache.values()].filter(Boolean);
  if(arr.length){cloudApplying=true;localStorage.setItem(PKEY,JSON.stringify(arr));cloudApplying=false}
  else await migrateLegacyData();
  for(const r of(sts||[])){
    if(FIXED_STATE_KEYS.includes(r.key)){cloudApplying=true;localStorage.setItem(r.key,JSON.stringify(r.state));cloudApplying=false}
  }
  renderAllFromCloud();
}

async function migrateLegacyData(){
  // Migra o estado antigo CRN-1556 apenas na primeira instalação da estrutura V16.
  let legacy=null;
  try{
    const {data}=await cloudClient.from('group_state').select('state').eq('group_id',cloudGroupId).maybeSingle();
    legacy=data?.state||null;
  }catch(e){console.warn('Migração legacy:',e)}
  let localPlayers=[];
  try{localPlayers=safeJSON(localStorage.getItem(PKEY)||'[]',[])}catch(e){}
  let oldPlayers=[];
  try{const legacyPlayers=legacy?.[PKEY];oldPlayers=Array.isArray(legacyPlayers)?legacyPlayers:(typeof legacyPlayers==='string'?(JSON.parse(legacyPlayers)||[]):[])}catch(e){oldPlayers=[]}
  const merged=new Map();
  for(const p of(oldPlayers||[]))merged.set(String(p.id),p);
  for(const p of(localPlayers||[]))if(!merged.has(String(p.id)))merged.set(String(p.id),p);
  const rows=[...merged.entries()].map(([id,data])=>({id,data,updated_at:new Date().toISOString(),updated_by:null}));
  if(rows.length){const {error}=await cloudClient.from('fixed_players').upsert(rows,{onConflict:'id'});if(error)throw error;cloudPlayerCache=new Map(rows.map(r=>[String(r.id),r.data]));cloudApplying=true;localStorage.setItem(PKEY,JSON.stringify(rows.map(r=>r.data)));cloudApplying=false}
  for(const k of FIXED_STATE_KEYS){let val=null;try{const legacyVal=legacy?.[k];if(legacyVal!==null&&typeof legacyVal!=='undefined'){val=typeof legacyVal==='string'?JSON.parse(legacyVal):legacyVal}else{const localVal=localStorage.getItem(k);val=localVal?JSON.parse(localVal):null}}catch(e){val=null}if(val!==null&&typeof val!=='undefined'){await cloudClient.from('fixed_state').upsert({key:k,state:val,updated_at:new Date().toISOString(),updated_by:null},{onConflict:'key'});cloudApplying=true;localStorage.setItem(k,JSON.stringify(val));cloudApplying=false}}
}

async function syncPlayers(){
  if(cloudApplying||!cloudClient||!cloudGroupId)return;
  let current=[];try{current=safeJSON(localStorage.getItem(PKEY)||'[]',[])}catch(e){return}
  const next=new Map(current.map(p=>[String(p.id),p]));
  const old=new Set(cloudPlayerCache.keys());
  const changed=[];
  for(const [id,p] of next){if(JSON.stringify(cloudPlayerCache.get(id))!==JSON.stringify(p))changed.push({id,data:p,updated_at:new Date().toISOString(),updated_by:null})}
  const removed=[...old].filter(id=>!next.has(id));
  if(!changed.length&&!removed.length)return;
  cloudBusy=true;
  try{
    await ensureCloudAuth();
    if(changed.length){const {error}=await cloudClient.from('fixed_players').upsert(changed,{onConflict:'id'});if(error)throw error;for(const r of changed)cloudPlayerCache.set(String(r.id),r.data)}
    if(removed.length){const {error}=await cloudClient.from('fixed_players').delete().in('id',removed);if(error)throw error;for(const id of removed)cloudPlayerCache.delete(id)}
  }catch(e){console.warn('syncPlayers:',e);updateCloudUI('⚠️ '+cloudErrorMessage(e,'Falha ao sincronizar jogadores'))}
  finally{cloudBusy=false}
}
function schedulePlayersSync(){clearTimeout(cloudStateTimers.players);cloudStateTimers.players=setTimeout(syncPlayers,250)}
function scheduleFixedState(key){
  if(!FIXED_STATE_KEYS.includes(key)||cloudApplying||!cloudClient||!cloudGroupId)return;
  clearTimeout(cloudStateTimers[key]);
  cloudStateTimers[key]=setTimeout(async()=>{
    try{await ensureCloudAuth();let v=localStorage.getItem(key);let state=null;try{state=v?JSON.parse(v):null}catch(e){state=v}const {error}=await cloudClient.from('fixed_state').upsert({key,state,updated_at:new Date().toISOString(),updated_by:null},{onConflict:'key'});if(error)throw error}
    catch(e){console.warn('syncState:',e);updateCloudUI('⚠️ '+cloudErrorMessage(e,'Falha ao sincronizar'))}
  },250);
}

function subscribeFixed(){
  if(cloudPlayersChannel)cloudClient.removeChannel(cloudPlayersChannel);
  if(cloudStateChannel)cloudClient.removeChannel(cloudStateChannel);
  cloudPlayersChannel=cloudClient.channel('cnr-v16-fixed-players').on('postgres_changes',{event:'*',schema:'public',table:'fixed_players'},payload=>{
    if(cloudApplying)return;
    if(payload.eventType==='DELETE'){cloudPlayerCache.delete(String(payload.old.id));cloudApplying=true;localStorage.setItem(PKEY,JSON.stringify([...cloudPlayerCache.values()]));cloudApplying=false}
    else if(payload.new){cloudPlayerCache.set(String(payload.new.id),payload.new.data);cloudApplying=true;localStorage.setItem(PKEY,JSON.stringify([...cloudPlayerCache.values()]));cloudApplying=false}
    renderAllFromCloud();
  }).subscribe();
  cloudStateChannel=cloudClient.channel('cnr-v16-fixed-state').on('postgres_changes',{event:'*',schema:'public',table:'fixed_state'},payload=>{
    if(cloudApplying||!payload.new?.key)return;
    const key=String(payload.new.key);if(!FIXED_STATE_KEYS.includes(key))return;
    cloudApplying=true;localStorage.setItem(key,JSON.stringify(payload.new.state));cloudApplying=false;renderAllFromCloud();
  }).subscribe();
}
function updateCloudUI(err){const st=document.getElementById('cloudStatus'),info=document.getElementById('cloudInfo');if(!st)return;if(err){st.textContent=err;info.textContent='Os dados locais continuam preservados.';return}if(cloudGroupId){st.textContent='🟢 ONLINE • Grupo fixo';info.textContent='Todos os celulares usam o mesmo grupo automaticamente.'}else{st.textContent='🔄 Conectando...';info.textContent='Conectando ao grupo online fixo.'}}

async function initCloud(){
  if(!cloudReady()){updateCloudUI('⚠️ Biblioteca Supabase não carregou');return}
  try{await initCloudClient();await ensureCloudAuth();await fixedGroup();await loadFixedData();subscribeFixed();updateCloudUI();}
  catch(e){console.error('Supabase V16:',e);updateCloudUI('⚠️ '+cloudErrorMessage(e,'Não foi possível conectar'))}
}

// Intercepta apenas os dados que devem ser compartilhados. Jogadores são sincronizados por registro.
const _v16SetItem=localStorage.setItem.bind(localStorage),_v16RemoveItem=localStorage.removeItem.bind(localStorage);
localStorage.setItem=function(k,v){_v16SetItem(k,v);if(!cloudApplying){if(k===PKEY)schedulePlayersSync();else if(FIXED_STATE_KEYS.includes(k))scheduleFixedState(k)}};
localStorage.removeItem=function(k){_v16RemoveItem(k);if(!cloudApplying){if(k===PKEY)schedulePlayersSync();else if(FIXED_STATE_KEYS.includes(k))scheduleFixedState(k)}};

window.addEventListener('online',()=>{updateCloudUI();initCloud()});
window.addEventListener('load',()=>setTimeout(initCloud,400));

