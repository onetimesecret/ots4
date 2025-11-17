# Build Stage
FROM elixir:1.15-alpine AS builder

# Install build dependencies
RUN apk add --no-cache \
    build-base \
    git \
    nodejs \
    npm

WORKDIR /app

# Install hex and rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Set environment
ENV MIX_ENV=prod

# Copy mix files
COPY mix.exs mix.lock ./
RUN mix deps.get --only prod
RUN mix deps.compile

# Copy application code
COPY . .

# Install node dependencies and compile assets
RUN cd assets && npm install
RUN mix assets.deploy

# Compile and build release
RUN mix compile
RUN mix release

# Runtime Stage
FROM alpine:3.18

# Install runtime dependencies
RUN apk add --no-cache \
    openssl \
    ncurses-libs \
    libstdc++

WORKDIR /app

# Copy release from builder
COPY --from=builder /app/_build/prod/rel/onetimesecret ./

# Create mnesia directory
RUN mkdir -p /app/priv/mnesia

# Expose port
EXPOSE 4000

# Set environment
ENV MIX_ENV=prod

# Start the release
CMD ["/app/bin/onetimesecret", "start"]
