ARG ELIXIR_VERSION=1.19.4
ARG OTP_VERSION=28.3
ARG DEBIAN_VERSION=bookworm-20260610-slim
ARG BUILDER_IMAGE="hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${DEBIAN_VERSION}"
ARG NODE_VERSION=24

FROM node:${NODE_VERSION}-bookworm-slim AS assets_deps
WORKDIR /assets
COPY assets/package.json assets/pnpm-lock.yaml ./
RUN corepack enable pnpm && pnpm install --prod --frozen-lockfile

FROM ${BUILDER_IMAGE} AS builder

RUN apt-get update -y \
  && apt-get install -y build-essential git ca-certificates \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN mix local.hex --force && mix local.rebar --force

ENV MIX_ENV=prod

COPY mix.exs mix.lock ./
RUN mix deps.get --only prod

RUN mkdir config
COPY config/config.exs config/prod.exs config/
RUN mix deps.compile

COPY priv priv
COPY lib lib
COPY assets assets
COPY --from=assets_deps /assets/node_modules assets/node_modules

RUN mix assets.setup

ARG LOKA_VERSION=0.1.0
ENV LOKA_VERSION=$LOKA_VERSION

RUN mix compile

RUN mix assets.deploy

COPY config/runtime.exs config/
COPY rel rel

RUN mix release



FROM debian:${DEBIAN_VERSION} AS runner

RUN apt-get update -y \
  && apt-get install -y libstdc++6 openssl libncurses6 locales ca-certificates \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

WORKDIR /app
RUN mkdir /app/uploads && chown nobody /app /app/uploads

ENV MIX_ENV=prod \
    PHX_SERVER=true \
    UPLOADS_DIR=/app/uploads

COPY --from=builder --chown=nobody:root /app/_build/prod/rel/loka ./

USER nobody

EXPOSE 4000

CMD ["/app/bin/server"]
