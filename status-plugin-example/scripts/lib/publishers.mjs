import { readFile } from 'node:fs/promises';
import path from 'node:path';

function fail(message) {
  throw new Error(message);
}

export async function loadPublishers(repoRoot) {
  const catalogPath = path.join(repoRoot, 'plugins/publishers.json');
  const catalog = JSON.parse(await readFile(catalogPath, 'utf8'));
  if (!Array.isArray(catalog.publishers)) {
    fail('plugins/publishers.json must contain a publishers array');
  }
  return catalog.publishers;
}

export function validateAuthor(author, publishers, sourceName) {
  if (!author || typeof author !== 'object' || Array.isArray(author)) {
    fail(`${sourceName}: manifest.author must be an object`);
  }
  if (typeof author.name !== 'string' || author.name.trim() === '') {
    fail(`${sourceName}: manifest.author.name is required`);
  }
  if (author.publisherId !== undefined) {
    if (typeof author.publisherId !== 'string' || /^[a-z][a-z0-9-]*$/.test(author.publisherId) === false) {
      fail(`${sourceName}: manifest.author.publisherId must be a lowercase slug`);
    }
    if (publishers.some((publisher) => publisher.id === author.publisherId) === false) {
      fail(`${sourceName}: manifest.author.publisherId references unknown publisher ${author.publisherId}`);
    }
  }
  if (author.url !== undefined) {
    if (typeof author.url !== 'string' || author.url.trim() === '') {
      fail(`${sourceName}: manifest.author.url must be a non-empty string`);
    }
  }
}

export function resolveAuthor(author, publishers) {
  validateAuthor(author, publishers, 'manifest');

  const publisher = author.publisherId
    ? publishers.find((entry) => entry.id === author.publisherId)
    : undefined;

  return {
    name: author.name,
    publisherId: author.publisherId,
    websitePath: author.url ?? (author.publisherId ? `/publishers/${author.publisherId}/` : undefined),
    externalUrl: publisher?.websiteUrl,
    repositoryUrl: publisher?.repositoryUrl,
    publisherSummary: publisher?.summary,
  };
}