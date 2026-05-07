import fs from 'fs';

const files = [
    'src/core/utils.lua',
    'src/core/value_extractor.lua',
    'src/fixtures/sample_savedata.lua',
    'src/core/savedata.lua',
    'src/debug/sniffer.lua',
    'src/features/quest_manager.lua',
    'src/features/farming.lua',
    'src/ui/window.lua'
];

let bundle = 'repeat task.wait() until game:IsLoaded()\n';
bundle += 'shared._PS99 = shared._PS99 or { Core = {}, Features = {}, UI = {}, Debug = {}, Fixtures = {} }\n\n';

const namespaceByPath = (file) => {
    if (file.includes('/features/')) return 'Features';
    if (file.includes('/debug/')) return 'Debug';
    if (file.includes('/fixtures/')) return 'Fixtures';
    if (file.includes('/ui/')) return 'UI';
    return 'Core';
};

const exportedNameByPath = (file, moduleVar) => {
    if (file.endsWith('sample_savedata.lua')) return 'SampleSaveData';
    return moduleVar;
};

for (const file of files) {
    let content = fs.readFileSync(file, 'utf8');
    const moduleName = file.split('/').pop().replace('.lua', '');
    const namespace = namespaceByPath(file);

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
        bundle += `\n    shared._PS99.${namespace}.${exportedNameByPath(file, moduleVar)} = ${moduleVar}\n`;
    }
    bundle += `end\n\n`;
}

bundle += '\nif shared._PS99.UI and shared._PS99.UI.Init then\n    shared._PS99.UI.Init()\nend\n';
bundle += '\nprint("[PS99 Bundle] Loaded safe parser build successfully.")\n';

fs.writeFileSync('test_bundle.lua', bundle);
console.log('Bundle created.');
