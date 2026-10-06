# Zapbox

Local, self-hosted WhatsApp Cloud API inbox. Point an application's
`WHATSAPP_BASE_URL` at `http://zapbox:4000`; Zapbox captures
`POST /v:version/:phone_id/messages`, returns a Meta-compatible success response,
and shows the request in the LiveView inbox.

Run locally with `mix phx.server`, or use `docker compose -f docker-compose.example.yml up`.
Persist Mnesia data by mounting `/data`. Controllers are lightweight local metadata
for known sender phone IDs and can be managed at `/controllers` or through `/api/controllers`.

## Docker image

Release images are published to GitHub Container Registry. For local development:

```yaml
services:
  zapbox:
    image: ghcr.io/<owner>/zapbox:latest
    ports:
      - "4003:4000"
    volumes:
      - zapbox-data:/data

volumes:
  zapbox-data:
```

Stable or shared environments should pin a release, for example
`ghcr.io/<owner>/zapbox:0.2.4`; reserve `latest` for local development.

Merging a pull request into `main` creates a patch release by default. Apply one
of these labels to control the increment: `release:major`, `release:minor`, or
`release:patch`. If multiple labels exist, major takes precedence over minor,
which takes precedence over patch.

To start your Phoenix server:

* Run `mix setup` to install and setup dependencies
* Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

* Official website: https://www.phoenixframework.org/
* Guides: https://hexdocs.pm/phoenix/overview.html
* Docs: https://hexdocs.pm/phoenix
* Forum: https://elixirforum.com/c/phoenix-forum
* Source: https://github.com/phoenixframework/phoenix
