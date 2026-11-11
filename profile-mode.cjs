 'use strict';
const path=require('node:path');
function profileMode(argv,base,temporary){const index=argv.indexOf('--profile'),name=index<0?'personal':argv[index+1];if(!['personal','work','private'].includes(name))throw Error('Unknown browser profile.');return {name,private:name==='private',directory:name==='personal'?base:name==='work'?path.join(base,'Profiles','work'):temporary,partition:name==='private'?'sai-private':'persist:sai-browser'};}
module.exports={profileMode};
