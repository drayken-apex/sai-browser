'use strict';
const {app,Menu,dialog}=require('electron');const path=require('node:path');
if(process.platform==='win32')app.setAppUserModelId('org.ysai.saibrowser');
const fs=require('node:fs'),os=require('node:os');
const requested=process.argv[process.argv.indexOf('--profile')+1];
const privateDirectory=process.argv.includes('--profile')&&requested==='private'?fs.mkdtempSync(path.join(os.tmpdir(),'sai-private-')):null;
const mode=require('./profile-mode.cjs').profileMode(process.argv,app.getPath('userData'),privateDirectory);
if(mode.directory!==app.getPath('userData')){fs.mkdirSync(mode.directory,{recursive:true});app.setPath('userData',mode.directory);app.setPath('sessionData',mode.directory);}
if(mode.private){app.commandLine.appendSwitch('disable-http-cache');app.commandLine.appendSwitch('disable-gpu-shader-disk-cache');}

const {openSaiBrowser,openProjectSpace,configureProfileMode}=require('./sai-browser.cjs');
const {safeBrowseUrl}=require('./sai-url.cjs');
configureProfileMode({...mode,launch:async name=>{if(!['personal','work','private'].includes(name))throw Error('Unknown profile.');const args=[...(!app.isPackaged?[__dirname]:[]),'--profile',name];const child=require('node:child_process').spawn(process.execPath,args,{detached:true,stdio:'ignore',windowsHide:true});child.unref();}});
if(mode.private)app.on('will-quit',()=>{try{fs.rmSync(privateDirectory,{recursive:true,force:true});}catch{}});
const primary=app.requestSingleInstanceLock();
function space(argv){const i=argv.indexOf('--space');if(i<0)return null;const id=argv[i+1];if(typeof id!=='string'||!id||id.length>60||/[\x00-\x1f]/.test(id))throw Error('Invalid Space.');return id;}
function address(argv){const i=argv.indexOf('--url');return i>=0?safeBrowseUrl(argv[i+1]):undefined;}
if(!primary)app.quit();else{
 const startup=app.whenReady().then(async()=>{
  Menu.setApplicationMenu(Menu.buildFromTemplate([{label:'SAI',submenu:[{label:'Browser',click:()=>void openSaiBrowser()},{type:'separator'},{role:'quit'}]},{role:'editMenu'},{role:'viewMenu'}]));
  await openSaiBrowser(address(process.argv));if(space(process.argv))await openProjectSpace(space(process.argv));
 });
 startup.catch(error=>{try{require('node:fs').writeFileSync(path.join(app.getPath('userData'),'startup-error.json'),JSON.stringify({at:new Date().toISOString(),message:String(error.message||error).slice(0,600)}));}catch{}dialog.showErrorBox('SAI Browser could not open','The browser could not load its protected local profile or app files. Your stored data has not been replaced.');app.quit();});
 app.on('second-instance',async(_event,argv)=>{await startup;await openSaiBrowser(address(argv));if(space(argv))await openProjectSpace(space(argv));});
 app.on('activate',()=>{if(app.isReady())void openSaiBrowser();});
 app.on('window-all-closed',()=>app.quit());
}
