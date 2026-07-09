import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { validateLocalPluginDirectory } from './lib/plugin-package-validator.mjs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const pluginDir = path.join(__dirname, '..', 'plugin');

const result = await validateLocalPluginDirectory(pluginDir);
console.log(`Validated ${result.manifest.id}@${result.manifest.version}`);
console.log(`SHA-256: ${result.sha256}`);
console.log('Plugin package is valid.');
