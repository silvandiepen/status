import fs from "node:fs";
import os from "node:os";
import path from "node:path";

const accountId = "8cef251b5fdcf6c6f63db98b7aa49f9a";
const projectName = "status";
const zoneName = "hakobs.com";
const hostName = "status.hakobs.com";
const target = "status-9d4.pages.dev";

const configPath = path.join(os.homedir(), "Library/Preferences/.wrangler/config/default.toml");
const config = fs.readFileSync(configPath, "utf8");
const token = config.match(/^\s*oauth_token\s*=\s*"([^"]+)"/m)?.[1];

if (!token) {
  throw new Error(`No oauth_token found in ${configPath}`);
}

async function cloudflare(method, pathname, body) {
  const response = await fetch(`https://api.cloudflare.com/client/v4${pathname}`, {
    method,
    headers: {
      authorization: `Bearer ${token}`,
      "content-type": "application/json",
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  const json = await response.json();
  if (!json.success) {
    const message = json.errors?.map((error) => `${error.code}: ${error.message}`).join("; ") || response.statusText;
    const error = new Error(message);
    error.response = json;
    throw error;
  }
  return json.result;
}

const zones = await cloudflare("GET", `/zones?name=${encodeURIComponent(zoneName)}`);
const zone = zones[0];
if (!zone) {
  throw new Error(`Zone not found: ${zoneName}`);
}

const domains = await cloudflare("GET", `/accounts/${accountId}/pages/projects/${projectName}/domains`);
if (!domains.some((domain) => domain.name === hostName)) {
  await cloudflare("POST", `/accounts/${accountId}/pages/projects/${projectName}/domains`, { name: hostName });
  console.log(`Added Pages custom domain: ${hostName}`);
} else {
  console.log(`Pages custom domain already present: ${hostName}`);
}

const records = await cloudflare("GET", `/zones/${zone.id}/dns_records?type=CNAME&name=${encodeURIComponent(hostName)}`);
const existing = records[0];
if (existing) {
  await cloudflare("PATCH", `/zones/${zone.id}/dns_records/${existing.id}`, {
    type: "CNAME",
    name: hostName,
    content: target,
    proxied: true,
  });
  console.log(`Updated DNS CNAME: ${hostName} -> ${target}`);
} else {
  await cloudflare("POST", `/zones/${zone.id}/dns_records`, {
    type: "CNAME",
    name: hostName,
    content: target,
    proxied: true,
  });
  console.log(`Created DNS CNAME: ${hostName} -> ${target}`);
}
