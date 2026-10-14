// Mechanical migration of Text leaf widgets; translations remain explicit.
const fs = require('fs');
const path = require('path');
function walk(dir) {
  for (const item of fs.readdirSync(dir, {withFileTypes:true})) {
    const file = path.join(dir,item.name);
    if (item.isDirectory()) { if(item.name !== 'l10n') walk(file); continue; }
    if (!file.endsWith('.dart')) continue;
    let code=fs.readFileSync(file,'utf8');
    if (!/\bText\(/.test(code)) continue;
    code=code.replace(/\bText\(/g,'LText(');
    const importPath=path.relative(path.dirname(file),'lib/l10n/app_language.dart').replaceAll('\\','/');
    if(!code.includes(`import '${importPath}';`)) code=`import '${importPath}';\n${code}`;
    fs.writeFileSync(file,code);
  }
}
walk('lib');
