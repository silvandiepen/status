# Mock Operations Plugin

This example is a starter package for third-party plugin authors. It is validated by `npm run plugins:check` and can be checked directly with:

```sh
npm run plugins:validate-local -- plugins/examples/mock-operations
```

It is not published to the hosted registry or bundled into the native apps.

It demonstrates:

- declared network permissions and domains;
- native setup fields;
- request definitions for read and review-required write flows;
- resource, event, and metric mappings;
- manual and cron triggers;
- suggested rules that install disabled;
- app-owned view descriptors;
- review-required action declarations.

`fixtures/fetch_status.json` is the recorded response shape used by native mapping tests. Replace the example.com endpoints with a real HTTPS API and recorded fixtures when adapting this template.
