# Zapbox development guide

Zapbox is a standalone Phoenix 1.8 + LiveView development tool that locally
captures WhatsApp Cloud API traffic. It has no external database: durable data
lives in Mnesia under `DATA_DIR` (normally `/data` in Docker).

## Project map

- `lib/zapbox/`: application and independent business domains
  - `messages.ex` / `messages/`: captured Cloud API requests and persistence
  - `controllers.ex` / `controllers/`: local metadata for WhatsApp phone IDs
- `lib/zapbox_web/live/`: inbox and controller-management UI
- `lib/zapbox_web/controllers/`: thin HTTP API and compatibility endpoints
- `lib/zapbox_web/components/`: reusable Phoenix components
- `assets/`: JavaScript hooks and Tailwind CSS
- `test/`: focused domain, controller, and LiveView tests

## Architecture

Keep HTTP, domain, persistence, and presentation concerns separate:

```text
LiveView / HTTP controller -> Zapbox domain facade -> domain store
domain data -> LiveView/private component or API representation
```

- `Zapbox.Messages` and `Zapbox.Controllers` are the public domain APIs.
  Web modules must not call `:mnesia` directly.
- Stores own Mnesia table access and table initialization. New tables must be
  disk-backed, idempotently initialized, and compatible with existing `/data`
  volumes.
- Domains remain independent. The inbox may resolve controller metadata from a
  message phone ID but messages must never require a controller to be accepted.
- Do not add Ecto, SQL databases, Redis, or external infrastructure.
- Preserve Meta-compatible request and response behavior. Zapbox captures
  permissively; it should not become a production WhatsApp validator.

## Web and API conventions

- Prefer LiveView for Zapbox UI. Use HEEx only and give forms and interactive
  controls stable DOM ids.
- Reuse Phoenix core components before extracting a shared component. Keep
  one-off presentation helpers private to the owning LiveView.
- API controllers are thin adapters: normalize the request, call a domain API,
  and render conventional JSON/statuses. Keep persistence and business rules in
  domains.
- Keep navigation small and maintain Inbox as the primary interface.
- Never display credentials. Sanitize sensitive headers before persistence and
  treat new request-inspection features as security-sensitive.

## Code style and documentation

- Keep directives ordered: `use`, `import`, `require`, then `alias`.
- Write functions as readable paragraphs: validate, gather context, execute,
  side effects, return. Extract a private function when a block gains more than
  one responsibility.
- Prefer self-explanatory code. Comments document a real invariant, runtime
  constraint, or external behavior; they never narrate history.
- Public modules and public domain/API functions need concise `@moduledoc`,
  `@doc`, and `@spec` documentation when added or materially changed.
- Do not call `Logger.*` from domain or store modules. Add telemetry only when
  it serves an observable product or operational need.

## Testing and validation

- Add focused tests for every changed behavior. Use `ZapboxWeb.ConnCase` for
  HTTP endpoints and LiveView tests for meaningful interaction flows.
- Mnesia tests must isolate their data directory/table state and must not depend
  on services outside the test process.
- Run targeted tests while iterating. Before finishing, run:

  ```sh
  mix format
  mix test
  ```

- When assets change, also run the relevant asset build or test command.
- Do not leave `dbg`, `IO.inspect`, or temporary debugging code behind.

## Definition of done

A change is complete when it preserves standalone Docker operation, Mnesia
persistence, Meta compatibility, and the existing domain boundaries; has focused
coverage; is formatted; and passes the relevant tests.
