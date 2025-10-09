#!/bin/bash

export BUNDLE_PATH="vendor/bundle"
export BUNDLE_WITH="mysql:puma:development:test:ci"
export BUNDLE_WITHOUT="aws"
bundle install

# cleans up previous shutdown
rm -f /opt/roadmap/tmp/pids/server.pid

# Setup credentials
EDITOR='echo "recaptcha:" >' bin/rails credentials:edit
EDITOR='echo "  site_key: \"\"" >>' bin/rails credentials:edit
EDITOR='echo "  secret_key: \"\"" >>' bin/rails credentials:edit
EDITOR='echo "devise_pepper: KJIJUIOJJeioejrerjerijrjerzerae__" >>' bin/rails credentials:edit
EDITOR='echo "dragonfly_secret: eorizjerjrzeurJJJIEI" >>' bin/rails credentials:edit
EDITOR='echo "secret_key_base: 12EJJJEHHEHEHHHEHZZYYYY9993JJDEHH__" >>' bin/rails credentials:edit

# Configures database
cat <<EOF1 > config/database.yml
production: &defaults
  adapter: <%= ENV['DB_ADAPTER'] || 'postgresql' %>
  encoding: <%= ENV['DB_ADAPTER'] == "mysql2" ? "utf8mb4" : "" %>
  username: root
  password: <%= ENV["DB_PASSWORD"] %>
  host: mysql
  database: roadmap_development
  pool: 16

development:
  <<: *defaults

test:
  <<: *defaults
EOF1

yarnpkg install
[ -f /usr/bin/yarn ] || ln -s /usr/bin/yarnpkg /usr/bin/yarn
bin/rails assets:precompile
bin/rails db:migrate
bin/rails server -p 3000 -b 0.0.0.0
