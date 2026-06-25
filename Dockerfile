# syntax=docker/dockerfile:1

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version and Gemfile
ARG RUBY_VERSION=3.1.4

### 1 base stage
FROM docker.io/library/ruby:${RUBY_VERSION}-slim AS base

WORKDIR /opt/roadmap

# Update RubyGems to a specific version, latest valid for Ruby version 3.1.x
ARG RUBYGEMS_VERSION=3.6.9
# Install base packages
RUN apt-get update -qq && \
  gem update --system ${RUBYGEMS_VERSION} --no-document --silent && \
  apt-get install --no-install-recommends -y \
  curl libjemalloc2 libpq-dev libmariadb-dev libvips openssl libjpeg62-turbo libpng16-16 imagemagick libxrender1 libxext6 && \
  rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Set production environment variables
ENV RAILS_ENV="production" \
  BUNDLE_DEPLOYMENT="1" \
  BUNDLE_PATH="/usr/local/bundle" \
  BUNDLE_WITH="pgsql:mysql:puma" \
  BUNDLE_WITHOUT="development:test:ci:aws"


### 2 build stage
FROM base AS build

# Install packages needed to build gems
RUN apt-get update -qq && \
  apt-get install --no-install-recommends -y \
  build-essential git pkg-config libyaml-dev libxml2-dev libssl-dev vim bison && \
  rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Install Node.js and JavaScript dependencies for asset compilation
ARG NODE_VERSION=22.22.3
ARG YARN_VERSION=1.22.22
ENV PATH=/usr/local/node/bin:$PATH
RUN curl -sL https://github.com/nodenv/node-build/archive/master.tar.gz | tar xz -C /tmp && \
  /tmp/node-build-master/bin/node-build "${NODE_VERSION}" /usr/local/node && \
  npm install -g yarn@${YARN_VERSION} && \
  rm -rf /tmp/node-build-master

# Install application gems
### Includes trick via Gemfile.local to overwrite upstream code with Belnet specific one (UGent way).
### But this creates problems to use ./bin/rails assets:precompile in the normal way.
COPY Gemfile Gemfile.lock Gemfile.local ./
RUN bundle install && \
  rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

# Install node modules
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile

# Copy application code
COPY . .

### TBC: role wkhtmltopdf here and unusual handling of assets via `ugent` directory
RUN (bin/wkhtmltopdf || true) &&\
  rm -f "${BUNDLE_PATH}"/ruby/*/gems/wkhtmltopdf-binary-0.12.6.10/bin/*.gz && \
  mv ./ugent/public/* ./public

# Precompiling assets for production without requiring secret RAILS_MASTER_KEY
# RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile
### DOES NOT WORK due to ugent/lib/module_override.rb
### Replaced by
### - `./ugent/bin/build_assets` in development
### - and `mv ./ugent/public/* ./public` in production


### 3 final stage
# Final stage for app image
FROM base

COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /opt/roadmap /opt/roadmap

# Run and own only the runtime files as a non-root user for security
### Had to add 'public' to the list, but this needs to be reviewed again.
RUN groupadd --gid 1000 rails && \
  useradd --uid 1000 --gid 1000 rails --create-home --shell /bin/bash && \
  chown -R rails:rails db log storage tmp public
USER 1000:1000

# Entrypoint prepares the database.
ENTRYPOINT [ "./bin/docker-entrypoint" ]
# Expose ports
EXPOSE 3000
# Start the application server by default
CMD [ "./bin/rails", "server" ]
