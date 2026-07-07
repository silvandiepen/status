const now = new Date().toISOString();

const registry = {
  schemaVersion: "1.0.0",
  generatedAt: now,
  plugins: []
};

const revocations = {
  schemaVersion: "1.0.0",
  generatedAt: now,
  revokedPlugins: [],
  revokedVersions: [],
  revokedHashes: [],
  revokedSigningKeys: []
};

function json(body, init = {}) {
  return new Response(JSON.stringify(body, null, 2), {
    ...init,
    headers: {
      "content-type": "application/json; charset=utf-8",
      "cache-control": "public, max-age=60",
      ...init.headers
    }
  });
}

function notFound(pathname) {
  return json(
    {
      error: "not_found",
      message: `No registry route exists for ${pathname}`
    },
    { status: 404, headers: { "cache-control": "no-store" } }
  );
}

export default {
  async fetch(request) {
    const url = new URL(request.url);

    if (url.pathname === "/" || url.pathname === "/health") {
      return json({
        service: "status-registry",
        ok: true,
        generatedAt: now
      });
    }

    if (url.pathname === "/v1/plugins" || url.pathname === "/v1/registry") {
      return json(registry);
    }

    if (url.pathname === "/v1/revocations") {
      return json(revocations);
    }

    const pluginMatch = url.pathname.match(/^\/v1\/plugins\/([^/]+)$/);
    if (pluginMatch) {
      const plugin = registry.plugins.find((item) => item.id === pluginMatch[1]);
      return plugin ? json(plugin) : notFound(url.pathname);
    }

    return notFound(url.pathname);
  }
};
