import {MAP,createGame,legalOrder,commit,advance} from './engine.js';
let state=createGame(),selected=0,orders=[];
const $=id=>document.getElementById(id);
function description(o){return `${o.type==='move'?`Dispatch ${o.count} → ${MAP[o.to].name}`:o.type==='build'?'Build 2 ships':'Extract 3 alloy'} · ${MAP[o.at].name}`;}
function render(){
  $('cycle').textContent=`Cycle ${state.round} / 8`;
  $('phase').textContent=state.phase==='finished'?(state.winner==='draw'?'Draw':state.winner===0?'Victory · network secured':'Defeat · network lost'):state.phase;
  $('player').textContent=`${state.score[0]} influence / ${state.credits[0]} alloy`;
  $('enemy').textContent=`${state.score[1]} influence / ${state.credits[1]} alloy`;
  $('map').querySelectorAll('button').forEach(b=>b.remove());
  MAP.forEach((w,i)=>{const b=document.createElement('button');b.className=`world owner${state.worlds[i].owner} ${selected===i?'selected':''}`;b.style.left=w.x+'%';b.style.top=w.y+'%';b.innerHTML=`${w.relay?'<span class="relay">◇</span>':''}${state.worlds[i].ships}<span class="name">${w.name}</span>`;b.setAttribute('aria-label',`${w.name}, ${state.worlds[i].owner===null?'neutral':state.worlds[i].owner===0?'friendly':'enemy'}, ${state.worlds[i].ships} ships${w.relay?', relay':''}`);b.onclick=()=>{selected=i;render();};$('map').append(b);});
  const w=state.worlds[selected];$('selection').textContent=MAP[selected].name;$('details').textContent=`${w.owner===0?'Ember Union':w.owner===1?'Vesper Accord':'Unclaimed'} · ${w.ships} ships${MAP[selected].relay?' · Relay: +1 influence each cycle':''}`;
  const old=$('destination').value;$('destination').replaceChildren(...MAP[selected].links.map(i=>new Option(MAP[i].name,i)));if(MAP[selected].links.includes(Number(old)))$('destination').value=old;
  $('count').max=w.ships;$('movement').hidden=$('type').value!=='move';
  $('queue').disabled=w.owner!==0||state.phase!=='planning'||orders.length>=3;
  $('controls').hidden=state.phase!=='planning';
  const shown=state.phase==='planning'?orders:state.queues[0];
  $('queue-count').textContent=`${shown.length} / 3`;$('orders').replaceChildren();
  [...shown].reverse().forEach((o,i)=>{const li=document.createElement('li'),text=document.createElement('span');text.textContent=`${i+1}. ${description(o)}`;li.append(text);if(state.phase==='planning'){const b=document.createElement('button');b.textContent='×';b.setAttribute('aria-label','Remove '+description(o));b.onclick=()=>{orders.splice(orders.length-1-i,1);render();};li.append(b);}$('orders').append(li);});
  $('commit').hidden=state.phase!=='planning';$('commit').disabled=orders.length!==3;$('step').hidden=state.phase!=='resolution';
  $('log').replaceChildren(...state.log.slice(-12).reverse().map(t=>{const p=document.createElement('p');p.textContent=t;return p;}));
}
$('links').innerHTML=MAP.flatMap((w,i)=>w.links.filter(j=>j>i).map(j=>`<line x1="${w.x}" y1="${w.y}" x2="${MAP[j].x}" y2="${MAP[j].y}"/>`)).join('');
$('type').onchange=render;
$('queue').onclick=()=>{const o={type:$('type').value,at:selected,to:Number($('destination').value),count:Number($('count').value)};if(!legalOrder(state,0,o)){$('notice').textContent='This command needs more ships or alloy.';return;}orders.push(o);$('notice').textContent='Command queued. The top command resolves first.';render();};
$('commit').onclick=()=>{try{state=commit(state,orders);orders=[];$('notice').textContent='Orders locked. Resolve commands to see the rival’s response.';render();}catch(e){$('notice').textContent=e.message;}};
$('step').onclick=()=>{state=advance(state);if(state.phase==='planning')$('notice').textContent='New cycle. Queue your next three commands.';render();};
$('restart').onclick=()=>{state=createGame();orders=[];selected=0;$('notice').textContent='';render();};
render();
