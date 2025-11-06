#!/bin/bash

bundle install

# cleans up previous shutdown
rm -f /opt/roadmap/tmp/pids/server.pid

# Setup credentials
EDITOR='tee' bin/rails credentials:edit <<EOF
recaptcha:
  site_key: ""
  secret_key: ""
devise_pepper: KJIJUIOJJeioejrerjerijrjerzerae__
dragonfly_secret: eorizjerjrzeurJJJIEI
secret_key_base: 12EJJJEHHEHEHHHEHZZYYYY9993JJDEHH__
EOF

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
bin/rails db:migrate
bin/dev
