'use strict';
const {safeBrowseUrl}=require('./sai-url.cjs');
async function searchWeb(query,fetcher=fetch,options={}){
 if(typeof query!=='string'||query.trim().length<2||query.length>250||/[\x00-\x1f\x7f]/.test(query))throw Error('Enter a search of 2–250 characters.');
 const page=Number(options.page??1),time=options.time||'';if(!Number.isInteger(page)||page<1||page>20||!['','day','month','year'].includes(time))throw Error('Invalid search filters.');
 const target=new URL('http://127.0.0.1:8888/search');target.searchParams.set('q',query.trim());target.searchParams.set('format','json');target.searchParams.set('safesearch','1');target.searchParams.set('pageno',String(page));if(time)target.searchParams.set('time_range',time);
 const response=await fetcher(target.href,{redirect:'error',signal:AbortSignal.timeout(15000),headers:{Accept:'application/json'}});if(!response.ok)throw Error('SAI Search returned HTTP '+response.status+'. Check the local search service.');const raw=await response.text();if(raw.length>1500000)throw Error('Search response exceeded the limit.');const data=JSON.parse(raw);if(!Array.isArray(data.results))throw Error('Search service returned invalid results.');
 const clean=(value,max)=>String(value||'').replace(/<[^>]*>/g,' ').replace(/&amp;/g,'&').replace(/&nbsp;/g,' ').replace(/\s+/g,' ').trim().slice(0,max),seen=new Set(),results=[];
 for(const item of data.results){let url;try{url=safeBrowseUrl(item.url);}catch{continue;}if(seen.has(url))continue;seen.add(url);results.push({url,title:clean(item.title,200)||new URL(url).hostname,excerpt:clean(item.content,1000),engine:clean(item.engine,60)});if(results.length>=30)break;}
 return {results,page,time,provider:'Local SearXNG metasearch',searchedAt:new Date().toISOString(),unavailable:(data.unresponsive_engines||[]).slice(0,10).map(x=>({engine:clean(x[0],60),reason:clean(x[1],100)}))};
}
module.exports={searchWeb};

