# status-plugin-example

Minimal [Status](https://github.com/statusfoundry/status) plugin you can fork, rename, and install locally.

This directory is generated from `plugins/examples/mock-operations` in the main Status repository. Do not edit it by hand — run `npm run plugin-example:sync` from the monorepo root instead.

## Quick start

```bash
npm install   # no dependencies; scripts use Node built-ins
npm run validate
```

A successful run prints the plugin id, version, and package checksum.

## Layout

```txt
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
```

## Install in Status

1. Validate: `npm run validate`
2. In Status: **Plugins → Install local plugin…**
3. Select the `plugin/` folder (the one containing `manifest.json`)

The app imports the folder into Application Support and runs the same structural checks.

## Forking

1. Fork this repository (or copy the folder).
2. Change `id`, `name`, and `version` in `plugin/manifest.json`.
3. Update mappings, views, and rules for your integration.
4. Run `npm run validate` until it passes.
5. Install via **Install local plugin…** in Status.

## Documentation

- [Plugin author guide](https://statusfoundry.github.io/status/docs/plugin-author-guide/) — full walkthrough
- [Developers](https://statusfoundry.github.io/status/developers/) — commands and links
- [Plugin system spec](https://statusfoundry.github.io/status/docs/plugin-system/) — architecture

## Sync from monorepo

Maintainers regenerate this tree from Status with:

```bash
npm run plugin-example:sync
```
