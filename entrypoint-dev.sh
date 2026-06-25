#!/bin/bash -e

# cleans up previous shutdown, if not done properly
rm -f ./tmp/pids/server.pid

# If running the rails server then migrate existing database if needed
### DON'T use db:prepare, we use one database per db container for now.
if [ "${@: -1:1}" == "./bin/dev" ]; then
  ./bin/rails db:migrate
fi

exec "${@}"
