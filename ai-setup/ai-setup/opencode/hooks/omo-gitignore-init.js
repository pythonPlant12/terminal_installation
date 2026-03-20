#!/usr/bin/env node
// OmO Gitignore Init - UserPromptSubmit hook
// Ensures agent/task-management entries are selectively gitignored:
// Idempotent: uses a per-repo state file so the check only runs once per session.
// Handles migration from older broad patterns (.sisyphus/, .planning) to granular rules.

const fs = require('fs');
const os = require('os');
const path = require('path');

// Broad patterns from older versions — removed during migration to granular rules.
const LEGACY_LINES = new Set([
  '.sisyphus/',
  '.sisyphus',
  '# agent orchestration — ephemeral state ignored (added automatically)',
  '# agent orchestration — ephemeral state ignored, plans tracked (added automatically)',
  '.planning',
  '.planning/',
  '# agent orchestration state (added automatically)',
  '# GSD planning (added automatically)',
  '# GSD planning — architecture tracked (added automatically)',
  '.planning/REQUIREMENTS.md',
  '.planning/ROADMAP.md',
  '.planning/quick/',
  '.planning/milestones/',
  '# pipeline step execution state (machine-local, Practice 1; added automatically)',
  '.state/',
]);

// Each group has a comment header and one or more lines to append.
// `check` patterns are used to detect if the group is already present.
const GROUPS = [
  {
    comment: '# agent orchestration — durable plans tracked, ephemeral state ignored (added automatically)',
    lines: [
      '.sisyphus/*',
      '!.sisyphus/README.md',
      '!.sisyphus/plans/',
      '.sisyphus/plans/*',
      '!.sisyphus/plans/README.md'
    ],
    check: [
      '.sisyphus/*',
      '!.sisyphus/README.md',
      '!.sisyphus/plans/',
      '.sisyphus/plans/*',
      '!.sisyphus/plans/README.md'
    ]
  },
  {
    comment: '# GSD planning — lifecycle docs tracked, execution state ignored (added automatically)',
    lines: ['.planning/STATE.md', '.planning/config.json', '.planning/debug/'],
    check: ['.planning/STATE.md', '.planning/config.json', '.planning/debug/']
  },
  {
    comment: '# task database (added automatically)',
    lines: ['.dolt', '.beads/**/**', '!.beads/issues.jsonl', '!.beads/interactions.jsonl'],
    check: ['.dolt', '.beads/**/**']
  },
  {
    comment: '# pipeline step execution state (machine-local, Practice 1; added automatically)',
    lines: ['.state/'],
    check: ['.state/']
  },
];

let input = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => input += chunk);
process.stdin.on('end', () => {
  try {
    const data = JSON.parse(input);
    const cwd = data.cwd || process.cwd();
    const sessionId = data.session_id;

    if (!sessionId) {
      process.exit(0);
    }

    // Only act inside git repositories
    const gitDir = path.join(cwd, '.git');
    if (!fs.existsSync(gitDir)) {
      process.exit(0);
    }

    // State file keyed on repo path — skip if already handled this session
    const repoHash = Buffer.from(cwd).toString('base64url').slice(0, 32);
    const stateFile = path.join(os.tmpdir(), `omo-gitignore-${sessionId}-${repoHash}`);

    if (fs.existsSync(stateFile)) {
      process.exit(0);
    }

    // Read current .gitignore (or start empty)
    const gitignorePath = path.join(cwd, '.gitignore');
    let content = '';

    if (fs.existsSync(gitignorePath)) {
      content = fs.readFileSync(gitignorePath, 'utf8');
    }

    // Migrate: remove legacy broad patterns from older versions
    const rawLines = content.split('\n');
    const cleaned = rawLines.filter(l => !LEGACY_LINES.has(l.trim()));
    const migrated = cleaned.length !== rawLines.length;
    if (migrated) {
      content = cleaned.join('\n').replace(/\n{3,}/g, '\n\n');
    }

    const existingLines = content.split('\n').map(l => l.trim());

    // Collect groups that need to be added
    const missing = GROUPS.filter(group =>
      !group.check.every(pattern => existingLines.includes(pattern))
    );

    if (missing.length === 0 && !migrated) {
      // Everything already present and no migration needed — mark state and exit
      fs.writeFileSync(stateFile, JSON.stringify({ cwd, ts: Date.now() }));
      process.exit(0);
    }

    // Build and append missing blocks
    if (missing.length > 0) {
      const blocks = missing.map(group =>
        `${group.comment}\n${group.lines.join('\n')}`
      );
      const appendix = blocks.join('\n\n');
      const trimmed = content.trimEnd();
      content = trimmed ? trimmed + '\n\n' + appendix + '\n' : appendix + '\n';
    }

    // Write updated .gitignore
    if (migrated || missing.length > 0) {
      fs.writeFileSync(gitignorePath, content);
    }

    // Mark done so we don't re-check this session
    fs.writeFileSync(stateFile, JSON.stringify({ cwd, ts: Date.now() }));

    // Silent — no stdout means no message injected into the conversation
  } catch {
    // Fail silently — hooks must never break the CLI
    process.exit(0);
  }
});
