import { cp, mkdir, readFile, rm, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { validateLocalPluginDirectory } from './lib/plugin-package-validator.mjs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(__dirname, '..');
const sourcePluginDir = path.join(repoRoot, 'plugins/examples/mock-operations');
const exampleRepoRoot = path.join(repoRoot, 'status-plugin-example');
const targetPluginDir = path.join(exampleRepoRoot, 'plugin');

const PACKAGE_JSON = {
  name: 'status-plugin-example',
  private: true,
  type: 'module',
  description: 'Minimal Status plugin template — validate locally before installing in the app.',
  scripts: {
    validate: 'node scripts/validate.mjs',
    check: 'node scripts/validate.mjs',
  },
};

const VALIDATE_SCRIPT = `import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { validateLocalPluginDirectory } from './lib/plugin-package-validator.mjs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const pluginDir = path.join(__dirname, '..', 'plugin');

const result = await validateLocalPluginDirectory(pluginDir);
console.log(\`Validated \${result.manifest.id}@\${result.manifest.version}\`);
console.log(\`SHA-256: \${result.sha256}\`);
console.log('Plugin package is valid.');
`;

const README = `# status-plugin-example

Minimal [Status](https://github.com/statusfoundry/status) plugin you can fork, rename, and install locally.

This directory is generated from \`plugins/examples/mock-operations\` in the main Status repository. Do not edit it by hand — run \`npm run plugin-example:sync\` from the monorepo root instead.

## Quick start

\`\`\`bash
npm install   # no dependencies; scripts use Node built-ins
npm run validate
\`\`\`

A successful run prints the plugin id, version, and package checksum.

## Layout

\`\`\`txt
plugin/                 # Your plugin (rename id in manifest after forking)
  manifest.json
  setup.schema.json
  requests.json
  mappings.json
  triggers.json
  events.json
  actions.json
  views.json
  rules.presets.json
  fixtures/
schemas/plugin/v1/      # JSON schemas used for validation
scripts/
  validate.mjs
  lib/plugin-package-validator.mjs
\`\`\`

## Install in Status

1. Validate: \`npm run validate\`
2. In Status: **Plugins → Install local plugin…**
3. Select the \`plugin/\` folder (the one containing \`manifest.json\`)

The app imports the folder into Application Support and runs the same structural checks.

## Forking

1. Fork this repository (or copy the folder).
2. Change \`id\`, \`name\`, and \`version\` in \`plugin/manifest.json\`.
3. Update mappings, views, and rules for your integration.
4. Run \`npm run validate\` until it passes.
5. Install via **Install local plugin…** in Status.

## Documentation

- [Plugin author guide](https://statusfoundry.github.io/status/docs/plugin-author-guide/) — full walkthrough
- [Developers](https://statusfoundry.github.io/status/developers/) — commands and links
- [Plugin system spec](https://statusfoundry.github.io/status/docs/plugin-system/) — architecture

## Sync from monorepo

Maintainers regenerate this tree from Status with:

\`\`\`bash
npm run plugin-example:sync
\`\`\`
`;

const GITIGNORE = `node_modules/
.DS_Store
`;

async function syncDirectory(source, target) {
  await rm(target, { recursive: true, force: true });
  await mkdir(path.dirname(target), { recursive: true });
  await cp(source, target, { recursive: true });
}

async function main() {
  await syncDirectory(sourcePluginDir, targetPluginDir);
  await syncDirectory(path.join(repoRoot, 'schemas/plugin/v1'), path.join(exampleRepoRoot, 'schemas/plugin/v1'));
  await syncDirectory(
    path.join(repoRoot, 'scripts/lib'),
    path.join(exampleRepoRoot, 'scripts/lib'),
  );

  await mkdir(path.join(exampleRepoRoot, 'scripts'), { recursive: true });
  await writeFile(path.join(exampleRepoRoot, 'package.json'), `${JSON.stringify(PACKAGE_JSON, null, 2)}\n`);
  await writeFile(path.join(exampleRepoRoot, 'scripts/validate.mjs'), VALIDATE_SCRIPT);
  await writeFile(path.join(exampleRepoRoot, 'README.md'), README);
  await writeFile(path.join(exampleRepoRoot, '.gitignore'), GITIGNORE);

  const result = await validateLocalPluginDirectory(targetPluginDir);

  console.log(`Synced status-plugin-example from mock-operations.`);
  console.log(`Validated ${result.manifest.id}@${result.manifest.version} (SHA-256 ${result.sha256}).`);
}

main().catch((error) => {
  console.error(error.message ?? error);
  process.exit(1);
});
