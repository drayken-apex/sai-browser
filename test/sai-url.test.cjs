'use strict';
const test=require('node:test');
const assert=require('node:assert/strict');
const {safeBrowseUrl,resolveAddress}=require('../sai-url.cjs');
test('SAI Browser permits ordinary public HTTPS pages',()=>{
  assert.equal(safeBrowseUrl('https://example.com'), 'https://example.com/');
  assert.equal(safeBrowseUrl('https://github.com/openai'), 'https://github.com/openai');
});
test('SAI Browser blocks dangerous URLs and private hosts',()=>{
  for(const url of ['file:///C:/Windows','javascript:alert(1)','http://localhost:8000',
    'https://127.0.0.1','https://10.0.0.1','https://192.168.1.1',
    'http://169.254.169.254/latest/meta-data','https://internal.local',
    'http://user:secret@example.com','https://example.org:9999']) {
      assert.throws(()=>safeBrowseUrl(url),url);
  }
});
test('SAI queries stay in the private search UI rather than forwarding to another engine',()=>{
 assert.equal(resolveAddress('github.com'),'https://github.com/');
 for(const engine of ['google','bing','duckduckgo',undefined]){
  const url=new URL(resolveAddress('local AI models',engine));
  assert.equal(url.protocol,'sai:');assert.equal(url.hostname,'search');assert.equal(url.searchParams.get('q'),'local AI models');
 }
});
