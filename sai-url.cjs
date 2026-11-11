'use strict';
// SAI Browser address bar and navigation policy. This is URL validation, not
// an entire network sandbox. Chromium isolated sessions and permission denial
// are mandatory additional layers.
const net=require('node:net');
function isPublicIp(host) {
  const type=net.isIP(host);
  if(type===4) {
    const n=host.split('.').map(Number);
    if(n[0]===0||n[0]===10||n[0]===127||n[0]>=224)return false;
    if(n[0]===100&&n[1]>=64&&n[1]<=127)return false;
    if(n[0]===169&&n[1]===254)return false;
    if(n[0]===172&&n[1]>=16&&n[1]<=31)return false;
    if(n[0]===192&&(n[1]===168||n[1]===0))return false;
    if(n[0]===198&&(n[1]===18||n[1]===19||n[1]===51))return false;
    if(n[0]===203&&n[1]===0&&n[2]===113)return false;
    return true;
  }
  // Restrict bare IPv6 targets: browsing by domain avoids most ambiguous
  // literal IPv6 scope and embedded IPv4 forms.
  return type===0;
}
function safeBrowseUrl(raw) {
  if(typeof raw!=='string'||raw.length>2000)throw new Error('Invalid address');
  const url=new URL(raw);
  if(!['https:','http:'].includes(url.protocol)||url.username||url.password||
    (url.port&&!['80','443'].includes(url.port)))throw new Error('Only ordinary public HTTP(S) websites are supported');
  const hostname=url.hostname.replace(/^\[|\]$/g,'').toLowerCase();
  if(!hostname||hostname==='localhost'||hostname.endsWith('.localhost')||
     hostname.endsWith('.internal')||hostname.endsWith('.local')||
     hostname.endsWith('.test')||!isPublicIp(hostname))throw new Error('Private and local networks are not reachable from SAI Browser');
  return url.toString();
}
function resolveAddress(input) {
  const text=String(input||'').trim().slice(0,1500);
  if(!text)throw new Error('Enter an address or search');
  if(/^https?:\/\//i.test(text))return safeBrowseUrl(text);
  if(/^[a-z0-9.-]+\.[a-z]{2,}(?:\/[^\s]*)?$/i.test(text))return safeBrowseUrl('https://'+text);
  return 'sai://search?q='+encodeURIComponent(text);
}

module.exports={safeBrowseUrl,resolveAddress};
