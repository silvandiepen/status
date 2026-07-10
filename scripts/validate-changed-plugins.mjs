import { execFileSync } from 'node:child_process';
import { appendFile, readdir, readFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { validateLocalPluginDirectory } from './lib/plugin-package-validator.mjs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(__dirname, '..');

const PLUGIN_PATH_PATTERN = /^(plugins\/(?:bundled|examples)\/[^/]+|status-plugin-example\/plugin)\//;

function gitDiffNames(base, head) {
  const output = execFileSync('git', ['diff', '--name-only', base, head], {
    cwd: repoRoot,
    encoding: 'utf8',
  });
  return output.trim().split('\n').filter(Boolean);
}

function resolveGitRange() {
  const base = process.env.GITHUB_BASE_SHA;
  const head = process.env.GITHUB_SHA;
  if (base && head) {
    return { base, head };
  }

  try {
    execFileSync('git', ['rev-parse', '--verify', 'main'], { cwd: repoRoot, stdio: 'ignore' });
    const mergeBase = execFileSync('git', ['merge-base', 'main', 'HEAD'], {
      cwd: repoRoot,
      encoding: 'utf8',
    }).trim();
    return { base: mergeBase, head: 'HEAD' };
  } catch {
    return { base: 'HEAD~1', head: 'HEAD' };
  }
}

function pluginDirectories(changedFiles) {
  const directories = new Set();

  for (const file of changedFiles) {
    if (PLUGIN_PATH_PATTERN.test(file) === false) {
      continue;
    }

    if (file.startsWith('status-plugin-example/plugin/')) {
      directories.add(path.join(repoRoot, 'status-plugin-example/plugin'));
      continue;
    }

    const parts = file.split('/');
    directories.add(path.join(repoRoot, parts[0], parts[1], parts[2]));
  }

  return [...directories].sort();
}

async function readJSON(filePath) {
  return JSON.parse(await readFile(filePath, 'utf8'));
}

async function readOptionalJSON(filePath) {
  try {
    return await readJSON(filePath);
  } catch (error) {
    if (error?.code === 'ENOENT') {
      return undefined;
    }
    throw error;
  }
}

function readJSONFromGit(ref, relativePath) {
  try {
    const output = execFileSync('git', ['show', `${ref}:${relativePath}`], {
      cwd: repoRoot,
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'ignore'],
    });
    return JSON.parse(output);
  } catch {
    return undefined;
  }
}

function sorted(value) {
  return [...new Set(value ?? [])].sort((left, right) => left.localeCompare(right));
}

function diffValues(previous, current) {
  const before = new Set(sorted(previous));
  const after = new Set(sorted(current));
  return {
    added: [...after].filter((value) => before.has(value) === false),
    removed: [...before].filter((value) => after.has(value) === false),
  };
}

function formatList(values) {
  return values.length === 0 ? 'none' : values.join(', ');
}

function relativePluginPath(directory) {
  return path.relative(repoRoot, directory);
}

function actionIDs(actionsFile) {
  return sorted((actionsFile?.actions ?? []).map((action) => action.id).filter(Boolean));
}

function writeActionIDs(actionsFile) {
  return sorted((actionsFile?.actions ?? [])
    .filter((action) => action.requiresWritePermission === true)
    .map((action) => action.id)
    .filter(Boolean));
}

function eventTypes(eventsFile) {
  return sorted((eventsFile?.events ?? []).map((event) => event.type).filter(Boolean));
}

function triggerIDs(triggersFile) {
  return sorted((triggersFile?.triggers ?? []).map((trigger) => trigger.id).filter(Boolean));
}

function viewIDs(viewsFile) {
  return sorted((viewsFile?.views ?? []).map((view) => view.id).filter(Boolean));
}

function resourceTypes(mappingsFile) {
  return sorted((mappingsFile?.resources ?? []).map((resource) => resource.type).filter(Boolean));
}

function fixtureFiles(changedFiles, pluginPath) {
  return changedFiles
    .filter((file) => file.startsWith(`${pluginPath}/fixtures/`))
    .sort((left, right) => left.localeCompare(right));
}

async function allFixtureFiles(pluginPath) {
  const fixturesRoot = path.join(repoRoot, pluginPath, 'fixtures');
  const files = [];

  async function visit(directory) {
    let entries;
    try {
      entries = await readdir(directory, { withFileTypes: true });
    } catch (error) {
      if (error?.code === 'ENOENT') {
        return;
      }
      throw error;
    }

    for (const entry of entries) {
      const fullPath = path.join(directory, entry.name);
      if (entry.isDirectory()) {
        await visit(fullPath);
      } else if (entry.isFile() && entry.name.endsWith('.json')) {
        files.push(path.relative(path.join(repoRoot, pluginPath), fullPath));
      }
    }
  }

  await visit(fixturesRoot);
  return files.sort((left, right) => left.localeCompare(right));
}

async function validateFixtureJSON(pluginPath, fixturePaths, sourceName) {
  for (const fixturePath of fixturePaths) {
    try {
      JSON.parse(await readFile(path.join(repoRoot, pluginPath, fixturePath), 'utf8'));
    } catch (error) {
      throw new Error(`${sourceName}: fixture ${fixturePath} must be valid JSON (${error.message})`);
    }
  }
}

function changedPluginRelativeFiles(changedFiles, pluginPath) {
  return changedFiles
    .filter((file) => file.startsWith(`${pluginPath}/`))
    .map((file) => path.relative(pluginPath, file))
    .sort((left, right) => left.localeCompare(right));
}

function reportDiffLine(label, previous, current) {
  const { added, removed } = diffValues(previous, current);
  return `- ${label}: ${formatList(sorted(current))} (added: ${formatList(added)}; removed: ${formatList(removed)})`;
}

async function buildReviewReport({ directory, base, changedFiles, result }) {
  const pluginPath = relativePluginPath(directory);
  const sourceName = path.relative(repoRoot, directory);
  const previousManifest = readJSONFromGit(base, `${pluginPath}/manifest.json`);
  const registry = await readOptionalJSON(path.join(directory, 'registry.json'));
  const actionsFile = await readOptionalJSON(path.join(directory, 'actions.json'));
  const eventsFile = await readOptionalJSON(path.join(directory, 'events.json'));
  const mappingsFile = await readOptionalJSON(path.join(directory, 'mappings.json'));
  const triggersFile = await readOptionalJSON(path.join(directory, 'triggers.json'));
  const viewsFile = await readOptionalJSON(path.join(directory, 'views.json'));
  const changedFixtures = fixtureFiles(changedFiles, pluginPath);
  const fixturePaths = await allFixtureFiles(pluginPath);
  await validateFixtureJSON(pluginPath, fixturePaths, sourceName);
  const relativeChangedFiles = changedPluginRelativeFiles(changedFiles, pluginPath);
  const writeActions = writeActionIDs(actionsFile);
  const permissionDiff = diffValues(previousManifest?.permissions, result.manifest.permissions);
  const domainDiff = diffValues(previousManifest?.domains, result.manifest.domains);
  const hasMappings = (mappingsFile?.resources?.length ?? 0) + (mappingsFile?.events?.length ?? 0) + (mappingsFile?.metrics?.length ?? 0) > 0;
  const mappingsChanged = relativeChangedFiles.includes('mappings.json');
  const pluginIsNew = !previousManifest;

  const reviewFlags = [];
  if (pluginIsNew) {
    reviewFlags.push('new plugin package');
  }
  if (permissionDiff.added.length > 0) {
    reviewFlags.push(`new permissions: ${permissionDiff.added.join(', ')}`);
  }
  if (domainDiff.added.length > 0) {
    reviewFlags.push(`new domains: ${domainDiff.added.join(', ')}`);
  }
  if (writeActions.length > 0) {
    reviewFlags.push(`declares write actions: ${writeActions.join(', ')}`);
  }
  if (hasMappings && (pluginIsNew || mappingsChanged) && changedFixtures.length === 0) {
    throw new Error(`${sourceName}: mapping changes must include changed JSON fixture evidence under fixtures/`);
  }
  if (hasMappings && fixturePaths.length === 0) {
    reviewFlags.push('mapped plugin has no fixture files yet');
  }
  if (mappingsChanged) {
    reviewFlags.push(`mapping file changed with fixtures: ${changedFixtures.map((file) => path.relative(pluginPath, file)).join(', ')}`);
  }

  return [
    `### ${result.manifest.name} (${result.manifest.id})`,
    '',
    `- Path: \`${pluginPath}\``,
    `- Version: \`${result.manifest.version}\``,
    `- Trust level: \`${registry?.trustLevel ?? 'local-dev'}\``,
    `- SHA-256: \`${result.sha256}\``,
    reportDiffLine('Permissions', previousManifest?.permissions, result.manifest.permissions),
    reportDiffLine('Domains', previousManifest?.domains, result.manifest.domains),
    `- Events: ${formatList(eventTypes(eventsFile))}`,
    `- Resources: ${formatList(resourceTypes(mappingsFile))}`,
    `- Triggers: ${formatList(triggerIDs(triggersFile))}`,
    `- Views: ${formatList(viewIDs(viewsFile))}`,
    `- Actions: ${formatList(actionIDs(actionsFile))}`,
    `- Write actions: ${formatList(writeActions)}`,
    `- Fixtures: ${formatList(fixturePaths)}`,
    `- Changed fixtures: ${formatList(changedFixtures.map((file) => path.relative(pluginPath, file)))}`,
    `- Review flags: ${formatList(reviewFlags)}`,
  ].join('\n');
}

async function writeStepSummary(markdown) {
  if (!process.env.GITHUB_STEP_SUMMARY) {
    return;
  }
  await appendFile(process.env.GITHUB_STEP_SUMMARY, `${markdown}\n`);
}

async function main() {
  const { base, head } = resolveGitRange();
  const changedFiles = gitDiffNames(base, head);
  const directories = pluginDirectories(changedFiles);

  if (directories.length === 0) {
    console.log('No plugin directories changed in this revision range.');
    return;
  }

  console.log(`Validating ${directories.length} changed plugin director${directories.length === 1 ? 'y' : 'ies'}:`);

  const reports = ['## Plugin PR validation report', ''];
  for (const directory of directories) {
    const sourceName = path.relative(repoRoot, directory);
    const result = await validateLocalPluginDirectory(directory, sourceName);
    console.log(`Validated ${result.manifest.id}@${result.manifest.version} (${sourceName})`);
    console.log(`SHA-256: ${result.sha256}`);
    reports.push(await buildReviewReport({ directory, base, changedFiles, result }), '');
  }

  const markdown = reports.join('\n');
  console.log('\n' + markdown);
  await writeStepSummary(markdown);
}

main().catch((error) => {
  console.error(error.message ?? error);
  process.exit(1);
});
