FROM ruby:3.1.4

RUN apt-get update
RUN apt-get install -y autoconf \
    automake curl gawk g++ \
    imagemagick libffi-dev \
    libgdbm-dev libreadline-dev \
    libssl-dev libtool libyaml-dev \
    shared-mime-info nodejs npm
RUN npm install --global yarn

RUN useradd -ms /bin/bash roadmap
USER roadmap

WORKDIR /opt/roadmap
RUN chown roadmap /opt/roadmap

COPY --chown=roadmap:roadmap app ./app/
COPY --chown=roadmap:roadmap config ./config/
COPY --chown=roadmap:roadmap bin ./bin/
COPY --chown=roadmap:roadmap db ./db/
COPY --chown=roadmap:roadmap lib ./lib/
COPY --chown=roadmap:roadmap public ./public/
COPY --chown=roadmap:roadmap spec ./spec/
COPY --chown=roadmap:roadmap ugent ./ugent/
COPY --chown=roadmap:roadmap Gemfile .
COPY --chown=roadmap:roadmap Gemfile.local .
COPY --chown=roadmap:roadmap Gemfile.lock .

RUN gem install bundler -v 2.4.17
RUN bundle install

COPY --chown=roadmap:roadmap package.json .
COPY --chown=roadmap:roadmap yarn.lock .

COPY --chown=roadmap:roadmap config.ru .
COPY --chown=roadmap:roadmap Dangerfile .
COPY --chown=roadmap:roadmap Rakefile .
COPY --chown=roadmap:roadmap Procfile .
COPY --chown=roadmap:roadmap Procfile.dev .

RUN cat <<EOF > config/database.yml
defaults: &defaults
  adapter: <%= ENV.fetch('DB_ADAPTER', 'postgresql') %>
  encoding: <%= ENV.fetch('DB_ADAPTER', 'postgresql') == 'mysql2' ? 'utf8mb4' : '' %>
  pool: <%= ENV.fetch('DB_POOL_SIZE', 16) %>
  host: <%= ENV.fetch('DB_HOST', 'localhost') %>
  port: <%= ENV.fetch('DB_PORT', '5432') %>
  database: <%= ENV.fetch('POSTGRES_DB') %>
  username: <%= ENV.fetch('POSTGRES_USER') %>
  password: <%= ENV.fetch('POSTGRES_PASSWORD') %>

development:
  <<: *defaults

test:
  <<: *defaults
EOF

COPY --chown=roadmap:roadmap entrypoint.sh .

CMD [ "bash", "/opt/roadmap/entrypoint.sh" ]
