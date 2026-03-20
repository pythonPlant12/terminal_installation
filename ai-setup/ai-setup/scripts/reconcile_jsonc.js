const fs = require('fs');

let jsoncParser = null;
try {
  jsoncParser = require('jsonc-parser');
} catch (_) {
  jsoncParser = null;
}

function isPlainObject(value) {
  return value !== null && typeof value === 'object' && !Array.isArray(value);
}

function cloneValue(value) {
  if (!isPlainObject(value) && !Array.isArray(value)) {
    return value;
  }
  return JSON.parse(JSON.stringify(value));
}

function mergeUserIntoRepoData(repoDataObj, userDataObj) {
  const result = cloneValue(repoDataObj);

  if (!isPlainObject(userDataObj)) {
    return result;
  }

  const target = isPlainObject(result) ? result : {};

  for (const key of Object.keys(userDataObj)) {
    const userVal = userDataObj[key];
    const repoVal = target[key];

    if (isPlainObject(userVal) && isPlainObject(repoVal)) {
      target[key] = mergeUserIntoRepoData(repoVal, userVal);
      continue;
    }

    target[key] = cloneValue(userVal);
  }

  return target;
}

function stripJsoncComments(input) {
  let output = '';
  let inString = false;
  let isEscaped = false;
  let inLineComment = false;
  let inBlockComment = false;

  for (let i = 0; i < input.length; i += 1) {
    const ch = input[i];
    const next = i + 1 < input.length ? input[i + 1] : '';

    if (inLineComment) {
      if (ch === '\n') {
        inLineComment = false;
        output += ch;
      }
      continue;
    }

    if (inBlockComment) {
      if (ch === '*' && next === '/') {
        inBlockComment = false;
        i += 1;
      } else if (ch === '\n') {
        output += ch;
      }
      continue;
    }

    if (inString) {
      output += ch;
      if (isEscaped) {
        isEscaped = false;
      } else if (ch === '\\') {
        isEscaped = true;
      } else if (ch === '"') {
        inString = false;
      }
      continue;
    }

    if (ch === '/' && next === '/') {
      inLineComment = true;
      i += 1;
      continue;
    }

    if (ch === '/' && next === '*') {
      inBlockComment = true;
      i += 1;
      continue;
    }

    if (ch === '"') {
      inString = true;
    }

    output += ch;
  }

  return output;
}

function removeTrailingCommas(input) {
  let output = '';
  let inString = false;
  let isEscaped = false;

  for (let i = 0; i < input.length; i += 1) {
    const ch = input[i];

    if (inString) {
      output += ch;
      if (isEscaped) {
        isEscaped = false;
      } else if (ch === '\\') {
        isEscaped = true;
      } else if (ch === '"') {
        inString = false;
      }
      continue;
    }

    if (ch === '"') {
      inString = true;
      output += ch;
      continue;
    }

    if (ch !== ',') {
      output += ch;
      continue;
    }

    let j = i + 1;
    while (j < input.length && /\s/.test(input[j])) {
      j += 1;
    }

    if (j < input.length && (input[j] === '}' || input[j] === ']')) {
      continue;
    }

    output += ch;
  }

  return output;
}

function parseJsoncFallback(content) {
  const withoutComments = stripJsoncComments(content);
  const normalized = removeTrailingCommas(withoutComments);
  return JSON.parse(normalized);
}

function parseJsonc(content) {
  if (jsoncParser) {
    return jsoncParser.parse(content);
  }

  return parseJsoncFallback(content);
}

function readUserData(userJsonPath, userJsoncPath) {
  if (userJsoncPath && fs.existsSync(userJsoncPath)) {
    return parseJsonc(fs.readFileSync(userJsoncPath, 'utf8')) || {};
  }

  if (userJsonPath && fs.existsSync(userJsonPath)) {
    return JSON.parse(fs.readFileSync(userJsonPath, 'utf8')) || {};
  }

  return {};
}

function convertJsoncFileToJson(inPath, outPath) {
  const parsed = parseJsonc(fs.readFileSync(inPath, 'utf8'));
  fs.writeFileSync(outPath, `${JSON.stringify(parsed, null, 2)}\n`, 'utf8');
}

function mergeUserIntoRepoText(repoContent, userDataObj, repoDataObj, currentPath = []) {
  let result = repoContent;
  if (!isPlainObject(userDataObj)) {
    return result;
  }

  for (const key of Object.keys(userDataObj)) {
    const userVal = userDataObj[key];
    const newPath = [...currentPath, key];
    const repoVal = isPlainObject(repoDataObj) ? repoDataObj[key] : undefined;

    if (isPlainObject(userVal) && isPlainObject(repoVal)) {
      result = mergeUserIntoRepoText(result, userVal, repoVal, newPath);
      continue;
    }

    const edits = jsoncParser.modify(result, newPath, userVal, {
      formattingOptions: { insertSpaces: true, tabSize: 2, eol: '\n' }
    });
    result = jsoncParser.applyEdits(result, edits);
  }

  return result;
}

function runWithJsoncParser(repoContent, repoData, userData, outJsonPath, outJsoncPath) {
  const mergedContent = mergeUserIntoRepoText(repoContent, userData, repoData);
  const mergedData = parseJsonc(mergedContent);
  fs.writeFileSync(outJsoncPath, mergedContent, 'utf8');
  fs.writeFileSync(outJsonPath, `${JSON.stringify(mergedData, null, 2)}\n`, 'utf8');
}

function runWithoutJsoncParser(repoData, userData, outJsonPath, outJsoncPath) {
  const mergedData = mergeUserIntoRepoData(repoData, userData);
  const normalized = `${JSON.stringify(mergedData, null, 2)}\n`;
  fs.writeFileSync(outJsoncPath, normalized, 'utf8');
  fs.writeFileSync(outJsonPath, normalized, 'utf8');
}

function main() {
  const args = process.argv.slice(2);

  if (args[0] === '--to-json') {
    const inPath = args[1];
    const outPath = args[2];
    if (!inPath || !outPath) {
      throw new Error('Usage: reconcile_jsonc.js --to-json <input-jsonc> <output-json>');
    }
    convertJsoncFileToJson(inPath, outPath);
    return;
  }

  const repoPath = args[0];
  const userJsonPath = args[1];
  const userJsoncPath = args[2];
  const outJsonPath = args[3];
  const outJsoncPath = args[4];

  if (!repoPath || !outJsonPath || !outJsoncPath) {
    throw new Error(
      'Usage: reconcile_jsonc.js <repo-jsonc> <user-json> <user-jsonc> <out-json> <out-jsonc>'
    );
  }

  const repoContent = fs.readFileSync(repoPath, 'utf8');
  const repoData = parseJsonc(repoContent);
  const userData = readUserData(userJsonPath, userJsoncPath);

  if (jsoncParser) {
    runWithJsoncParser(repoContent, repoData, userData, outJsonPath, outJsoncPath);
    return;
  }

  runWithoutJsoncParser(repoData, userData, outJsonPath, outJsoncPath);
}

main();
