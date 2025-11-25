# DMP Roadmap

[Original readme](https://github.com/DMPRoadmap/roadmap)

## Up and running

The environment runs using q docker compose setup.  
By default the docker compose starts a `postgres` server and a `roadmap` instance.  

A profile also needs to be passed.  
Currently these profiles are either `prod` or `dev`.  

```bash
docker compose --profile=dev up -d
```

The roadmap container crashing the first time it starts is normal.  

### Config

The compose setup requires 2 env files to be present:

- `.env.compose.postgres`:

This file seeds database name and credentials for both the `postgres` and the `roadmap` containers.  

```bash
POSTGRES_PASSWORD=
POSTGRES_USER=dmponline_int
POSTGRES_DB=dmponline_int

# pgadmin settings required for dev env
PGADMIN_DEFAULT_EMAIL=
PGADMIN_DEFAULT_PASSWORD=
```

- `.env.compose.roadmap`:

This file seeds several roadmap settings.  

```bash
RAILS_LOG_LEVEL=debug
RAILS_LOG_TO_STDOUT=true
# Whether or not Rails will be serving your static assets 
# RAILS_SERVE_STATIC_FILES=false
# Maximum number of Puma threads
RAILS_MAX_THREADS=5
# Maximum number of Puma workers
WEB_CONCURRENCY=2
# The port and bind address puma will use to host the Rails app
BIND_ADDRESS=127.0.0.1
PORT=3000

# Rails 6.1+ has a white-list of valid domains. You must set this for your production env!
DMPROADMAP_HOST=localhost

# Database settings.
DB_ADAPTER=postgresql
DB_HOST=postgres
DB_POOL_SIZE=16

# Translation IO variables. The Domain can be either `app` or `client` and is typically defined
# when running `bin/rails translations:sync DOMAIN=app`. `client` will use any of your 
# customized content in ./app/views/branded and `app` is for the core roadmap translations.
# Include your Translation.io API key for the appropriate domains:
#    app => TRANSLATION_API_ROADMAP
#    client => TRANSLATION_API_CLIENT
# Note: Domain = client does not work for this setup
DOMAIN=app

# Fixes a startup bug
DMP_LOCAL_LOGIN=true

# Site Credentials
SITE_KEY=""
SECRET_KEY=""
DEVISE_PEPPER=
DRAGONFLY_SECRET=
SECRET_KEY_BASE=
```

### DB Config

The db seed function from the original project have not been updated and thus currently it is recommended to request a dump of the test environment to upload to your postgres server.  

Without a configured database, the ruby-on-rails will not start.  
Once the postgres container has started.  

```bash
docker exec -i postgres bash -c "psql -U \$POSTGRES_USER -d \$POSTGRES_DB --echo-all" < /path/to/dump.sql
```

This will print the sql instructions, instruction per instruction.  
Verify the database got populated before continuing.  

After having configured all this run the docker compose up command again to relaunch the crashed roadmap container.  

```bash
docker compose --profile=dev up -d
```

It should soon be up and running.  
Finaly, configure an admin user:

```bash
docker exec -ti roadmap bash
```

```bash
bin/rails console

user = User.new(email: "testuser@testuser.be")
user.perms = Perm.all
user.password =
user.password_confirmation =

user.save!
```

NOTE: Be sure to set the users password.  

## Turning it off

To turn off the system simply run docker compose down with the same profile as it was started with:

```bash
docker compose --profile=dev down
```

The data and configuration of postgres will persist for subsequent runs, as will the roadmap configuration.  
