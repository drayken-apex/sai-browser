'use strict';
const {contextBridge,ipcRenderer}=require('electron');
const invoke=name=>(...args)=>ipcRenderer.invoke('sai:'+name,...args);
contextBridge.exposeInMainWorld('sai',Object.freeze({
 compareEvidence:invoke('evidence-compare'),captureEvidence:invoke('evidence-capture'),evidenceNote:invoke('evidence-note'),removeEvidence:invoke('evidence-remove'),exportEvidence:invoke('evidence-export'),saveReading:invoke('reading-save'),readingStatus:invoke('reading-status'),updateSpace:invoke('space-update'),saveSpace:invoke('space-save'),openSpace:invoke('space-open'),reader:invoke('reader'),menu:invoke('menu'),reopenTab:invoke('reopen'),pinTab:invoke('pin'),newTab:invoke('new'),switchTab:invoke('switch'),closeTab:invoke('close-tab'),navigate:invoke('navigate'),
 control:invoke('control'),state:invoke('state'),panel:invoke('panel'),
 find:invoke('find'),bookmark:invoke('bookmark'),index:invoke('index'),library:invoke('library'),
 onCommand:callback=>{if(typeof callback==='function')ipcRenderer.on('sai:command',(_e,id)=>callback(id));},
 onState:callback=>{if(typeof callback==='function')ipcRenderer.on('sai:state',(_e,state)=>callback(state));},
 onFocusAddress:callback=>{if(typeof callback==='function')ipcRenderer.on('sai:focus-address',callback);}
}));
