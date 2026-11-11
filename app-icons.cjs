'use strict';
const {app}=require('electron');
const path=require('node:path');
function iconFile(name,extension='ico'){
 return path.join(app.isPackaged?path.join(process.resourcesPath,'icons'):path.join(__dirname,'assets'),name+'.'+extension);
}
module.exports={iconFile};
