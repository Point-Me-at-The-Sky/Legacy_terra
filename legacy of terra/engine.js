export const MAP = [
  {name:'Ember Anchorage',x:15,y:50,links:[1,2],home:0},
  {name:'Glass Reach',x:33,y:23,links:[0,2,3],relay:true},
  {name:'Cinder Belt',x:33,y:77,links:[0,1,4]},
  {name:'The Still Eye',x:53,y:40,links:[1,4,5],relay:true},
  {name:'Hollow Meridian',x:55,y:78,links:[2,3,6],relay:true},
  {name:'Pale Crossing',x:74,y:22,links:[3,6,7]},
  {name:'Crown of Night',x:76,y:65,links:[4,5,7],relay:true},
  {name:'Vesper Citadel',x:91,y:43,links:[5,6],home:1}
];
export function createGame(){return {round:1,phase:'planning',turn:0,credits:[5,5],score:[0,0],queues:[[],[]],worlds:MAP.map(w=>({owner:w.home??null,ships:w.home===undefined?0:5})),log:['The network awakens. Queue three commands, then commit.'],winner:null};}
export function legalOrder(s,p,o){
  if(!o || !Number.isInteger(o.at) || !s.worlds[o.at]) return false;
  const w=s.worlds[o.at];
  if(w.owner!==p)return false;
  if(o.type==='harvest')return true;
  if(o.type==='build')return s.credits[p]>=2;
  return o.type==='move' && MAP[o.at].links.includes(o.to) && Number.isInteger(o.count) && o.count>0 && w.ships>=o.count;
}
export function aiPlan(s){
  // Plan against a private projection so later commands can use newly captured worlds.
  const copy=structuredClone(s), chronological=[];
  for(let i=0;i<3;i++){
    let candidates=[];
    copy.worlds.forEach((w,at)=>{if(w.owner!==1||!w.ships)return;MAP[at].links.forEach(to=>{
      const target=copy.worlds[to];
      if(target.owner!==1 && w.ships>target.ships)candidates.push({type:'move',at,to,count:w.ships,value:(MAP[to].relay?5:1)+(target.owner===0?2:0)});
    });});
    candidates.sort((a,b)=>b.value-a.value);
    let o=candidates[0];
    if(!o){const at=copy.worlds.findIndex(w=>w.owner===1);if(at<0)break;o={type:copy.credits[1]>=2?'build':'harvest',at};}
    chronological.push(o);execute(copy,1,o);
  }
  return chronological.reverse();
}
function execute(s,p,o){
  const faction=p===0?'Ember Union':'Vesper Accord';
  if(!legalOrder(s,p,o)){s.log.push(`${faction}: command failed; its requirements changed.`);return;}
  const w=s.worlds[o.at],name=MAP[o.at].name;
  if(o.type==='harvest'){s.credits[p]+=3;s.log.push(`${faction} extracts 3 alloy at ${name}.`);}
  if(o.type==='build'){s.credits[p]-=2;w.ships+=2;s.log.push(`${faction} builds 2 ships at ${name}.`);}
  if(o.type==='move'){
    w.ships-=o.count;const target=s.worlds[o.to];
    if(target.owner===p)target.ships+=o.count;
    else if(o.count>target.ships){target.ships=o.count-target.ships;target.owner=p;}
    else {target.ships-=o.count;if(target.ships===0)target.owner=null;}
    s.log.push(`${faction} sends ${o.count} ships to ${MAP[o.to].name}.`);
  }
}
export function commit(state,orders){
  if(state.phase!=='planning'||orders.length!==3)throw Error('Queue exactly three commands.');
  if(!orders.every(o=>legalOrder(state,0,o)))throw Error('A queued command is invalid.');
  const s=structuredClone(state);s.queues=[structuredClone(orders),aiPlan(s)];s.phase='resolution';s.turn=(s.round-1)%2;return s;
}
export function advance(state){
  if(state.phase!=='resolution')return state;
  const s=structuredClone(state);let p=s.turn;
  if(!s.queues[p].length)p=1-p;
  if(s.queues[p].length)execute(s,p,s.queues[p].pop());
  s.turn=1-p;
  if(!s.queues.some(q=>q.length)){
    s.worlds.forEach((w,i)=>{if(w.owner!==null&&MAP[i].relay)s.score[w.owner]++;});
    s.credits=s.credits.map(n=>n+2);
    s.log.push(`Cycle ${s.round} ends. Relay control: ${s.score[0]} / ${s.score[1]}. Each faction gains 2 alloy.`);
    const alive=[0,1].map(p=>s.worlds.some(w=>w.owner===p));
    if(!alive[0]||!alive[1]||Math.max(...s.score)>=12||s.round===8){
      s.phase='finished';s.winner=!alive[0]?1:!alive[1]?0:s.score[0]===s.score[1]?'draw':s.score[0]>s.score[1]?0:1;
      s.log.push(s.winner==='draw'?'The network remains divided. Draw.':`${s.winner===0?'Ember Union':'Vesper Accord'} controls the network.`);
    }else{s.round++;s.phase='planning';}
  }
  return s;
}
