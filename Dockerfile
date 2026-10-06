FROM hexpm/elixir:1.19.5-erlang-28.3-debian-bookworm-20260112

RUN apt-get update && apt-get install -y --no-install-recommends build-essential git nodejs npm && rm -rf /var/lib/apt/lists/*
WORKDIR /app
ENV MIX_ENV=prod PHX_SERVER=true PORT=4000 DATA_DIR=/data
COPY mix.exs mix.lock ./
RUN mix local.hex --force && mix local.rebar --force && mix deps.get --only prod
COPY . .
RUN mix assets.deploy
EXPOSE 4000
CMD ["mix", "phx.server"]
