# syntax=docker/dockerfile:1
# check=error=true

# This Dockerfile is designed for production, not development. Use with Kamal or build'n'run by hand:
# docker build -t blog .
# docker run -d -p 80:80 -e RAILS_MASTER_KEY=<value from config/master.key> --name blog blog

# For a containerized dev environment, see Dev Containers: https://guides.rubyonrails.org/getting_started_with_devcontainer.html

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version
ARG RUBY_VERSION=3.4.5
# Pinned by digest (the multi-platform manifest list): a gem seed or a shared layer cache is only
# valid on the exact base bytes it was built on (libpq, libyaml, the Ruby ABI). The tag alone moves
# with every Debian security rebuild. Refresh together with RUBY_VERSION:
#   docker buildx imagetools inspect docker.io/library/ruby:<RUBY_VERSION>-slim   # "Digest:" line
ARG RUBY_DIGEST=sha256:f1cca61013f823406e5ec23d3b8804ee0ba916febbfee089e647db93e8e749c7
# Image whose /usr/local/bundle pre-fills the gem stage, so `bundle install` only adds the delta.
# The default is the empty `base` stage: a plain `docker build` is seed-free and needs no registry
# beyond the Ruby image. Cloud Build passes the project's own `rails8-blog:gems` (bin/cloudbuild-build-image).
ARG GEMS_SEED=base

FROM docker.io/library/ruby:$RUBY_VERSION-slim@$RUBY_DIGEST AS base

# Rails app lives here
WORKDIR /rails

# Install base packages
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libjemalloc2 libvips sqlite3 libpq5 && \
    ln -s /usr/lib/$(uname -m)-linux-gnu/libjemalloc.so.2 /usr/local/lib/libjemalloc.so && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Set production environment variables and enable jemalloc for reduced memory usage and latency.
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test" \
    LD_PRELOAD="/usr/local/lib/libjemalloc.so"

FROM ${GEMS_SEED} AS gem-seed

# Gems only: everything below depends on the seed and Gemfile*, never on the application code
FROM base AS gems
ARG RUBY_VERSION RUBY_DIGEST
# bin/cloudbuild-build-image only takes an image as a seed when this digest matches its own Dockerfile
LABEL org.opencontainers.image.base.name="docker.io/library/ruby:${RUBY_VERSION}-slim" \
      org.opencontainers.image.base.digest="${RUBY_DIGEST}"

# Install packages needed to build gems. Before the seed copy, so this layer depends only on the
# base image and stays shareable through a registry cache across projects.
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libyaml-dev pkg-config libpq-dev && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Keyed on the seed's content, not on Gemfile.lock: a lock change keeps this layer and only the
# install below runs, against gems that are already there.
COPY --from=gem-seed /usr/local/bundle /usr/local/bundle

# Install application gems
COPY Gemfile Gemfile.lock ./

# `bundle clean` drops gems the lockfile no longer lists; without it a seed that is rebuilt from
# itself would keep every gem version it has ever seen.
RUN bundle install && \
    bundle clean --force && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    # -j 1 disable parallel compilation to avoid a QEMU bug: https://github.com/rails/bootsnap/issues/495
    bundle exec bootsnap precompile -j 1 --gemfile

# Throw-away build stage to reduce size of final image
FROM gems AS build

# Copy application code
COPY . .

# Precompile bootsnap code for faster boot times.
# -j 1 disable parallel compilation to avoid a QEMU bug: https://github.com/rails/bootsnap/issues/495
RUN bundle exec bootsnap precompile -j 1 app/ lib/

# Precompiling assets for production without requiring secret RAILS_MASTER_KEY
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

# Final stage for app image
FROM base

# Run and own only the runtime files as a non-root user for security
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash
USER 1000:1000

# Copy built artifacts: gems, application
COPY --chown=rails:rails --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --chown=rails:rails --from=build /rails /rails

# Entrypoint prepares the database (runs db:prepare before server start).
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Start Puma directly (Cloud Run sets PORT=8080, Puma reads it via config/puma.rb).
# Thruster removed: Cloud Run already provides TLS, HTTP/2, and compression.
EXPOSE 8080
CMD ["./bin/rails", "server"]
