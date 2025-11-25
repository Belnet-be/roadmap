#!/bin/bash
EDITOR='tee' bin/rails credentials:edit <<EOF
recaptcha:
  site_key: $SITE_KEY
  secret_key: $SECRET_KEY
devise_pepper: $DEVISE_PEPPER
dragonfly_secret: $DRAGONFLY_SECRET
secret_key_base: $SECRET_KEY_BASE
EOF

# assumes config is mounted as a volume in docker
echo "Running database migrate"
bin/rails db:migrate

# This relies on the db having been set up and configured...
bin/rails assets:precompile

if [ $ENV == "prod" ]; then
    echo "Running in production mode"
    bin/puma -C config/puma.rb
else
    echo "Running in dev mode"
    bin/dev
fi
