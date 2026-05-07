import fs from 'fs';

const files = [
    'src/core/utils.lua',
    'src/core/network.lua',
    'src/core/savedata.lua',
    'src/debug/sniffer.lua',
    'src/features/quest_manager.lua',
    'src/features/farming.lua',
    'src/ui/window.lua'
];

let bundle = 'shared._PS99 = shared._PS99 or { Core = {}, Features = {}, UI = {}, Debug = {} }\n\n';

for (const file of files) {
    let content = fs.readFileSync(file, 'utf8');
    const moduleName = file.split('/').pop().replace('.lua', '');
    let namespace = 'Core';
    if (file.includes('features')) namespace = 'Features';
    if (file.includes('debug')) namespace = 'Debug';
    if (file.includes('ui')) namespace = 'UI';
    
    const lines = content.split('\n');
    let moduleVar = moduleName;
    for (let i = lines.length - 1; i >= 0; i--) {
        if (lines[i].startsWith('return ')) {
            moduleVar = lines[i].split('return ')[1].trim();
            lines[i] = '';
            break;
        }
    }
    content = lines.join('\n');
    
    bundle += `do\n`;
    bundle += content;
    
    if (namespace === 'UI') {
         bundle += `\n    shared._PS99.UI = ${moduleVar}\n`;
    } else {
         bundle += `\n    shared._PS99.${namespace}.${moduleVar} = ${moduleVar}\n`;
    }
    bundle += `end\n\n`;
}

bundle += `\n-- Autostart UI\nif shared._PS99.UI and shared._PS99.UI.Init then\n    shared._PS99.UI.Init()\nend\n`;
bundle += `\nprint("[PS99 Bundle] Loaded successfully!")\n`;

fs.writeFileSync('test_bundle.lua', bundle);
console.log('Bundle created!');
