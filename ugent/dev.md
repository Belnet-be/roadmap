# Setup development Environment with docker

* Install [Docker Desktop](https://www.docker.com/products/docker-desktop/)

* Start Docker desktop

* Clone git repository:

```
git clone git@github.com:DMPbelgium/roadmap.git
```

You might need to add your SSH public key to github

* Go to your application directory and start your docker compose:

```
cd roadmap
docker compose up
```

You can override environment variables set in [docker-compose.yml](../docker-compose.yml) using your local `.env`:

```
ORCID_CLIENT_ID="APP-ID"
ORCID_CLIENT_SECRET="APP-SECRET"
```

* On first startup rails will try to create all tables using `rails db:migrate`.

This is unfortunately not the desired situation. 

**DO NOT create a new database**, as stated in the wiki from roadmap.
This repository depends on a database, migrated from DMPOnline_v4 (with local additions),
that has more attributes than the regular one.

Stop the docker instance `roadmap-dev` in docker desktop, and keep the mysql docker instance running.

[Migrated data](https://btadoredev.ugent.be/roadmap.sql.gz) will be provided

Execute the following command from your host (given the mapped mysql port 3307):

```
gunzip -c roadmap.sql.gz | mysql --user=root --password=root --host=0.0.0.0 --port=3307
```

* Fully restart docker compose

# Login to the application

* Login into docker console `roadmap-dev`, and add  your self as user

```
$ cd /opt/roadmap
$ bin/rails console

> u = User.new(email: "reinout.koninkx@agilearchitects.be", firstname: "Reinout", surname: "Koninkx")
> u.perms = Perm.all
> u.password = u.email
> u.password_confirmation = u.email
> u.save!
```

The password is set equal to your email address, to make things easy.

`u.perms = Perm.all` gives you all special permissions, effectively making you super-admin.

* However, now you are a member of organisation "guests"

Every user needs to be assigned to a managed organization.

Because you did not set an organization (`u.org_id` is not set), the system tried to derive an organization using the email's domain (`agilearchitects.be`). When that did not work, it resorted to organization `guests`.

Organization `guests` is the default organization, and should be kept in store.
Every user assigned to that organization has only reading rights, and therefore
can never create his own plans. He can however place comments on plans, if he is added
as contributor to a plan.

Try to set the organization manually:

```
> org = Org.where(managed: true, abbreviation: "UGent").first
> u.org_id = org.id
> u.save!
```

Or add your email's domain to the list of domains automatically associated with organisation "UGent":

Create a domain assocation, and set the `org_id` back to `nil`. On save the system
will reassign the organization automatically.

```
> org = Org.where(managed: true, abbreviation: "UGent").first
> org_domain = Ugent::OrgDomain.new(name: "agilearchitects.be", org_id: org.id)
> org_domain.save!
> u.org = nil
> u.save!
```

Although you deleted your associated organisation, due to association of that email's domain,
organization "UGent" is automatically (re)assigned to your user. Note that this only happens
when `org_id` is not set.

# Used base docker image for development

Used base docker image for development is [ruby:3.1.4](https://hub.docker.com/layers/library/ruby/3.1.4/images/sha256-6a102ede67e31205667bbb2f3e9d72f5315ad7efee7b0e5e804f5ab51c605934) as stated in [../Dockerfile-dev](../Dockerfile-dev). 

Characteristics:

* OS: Debian
* Contains ruby 3.1.4 (of course)
* Contains build tools (git, make ..)

Building the docker image (indirectly by using docker compose) results into a big and bloated image (several gigabytes).

# Used base docker image for production

Used base docker image for production is [ruby:3.1.4-slim](https://hub.docker.com/layers/library/ruby/3.1.4-slim/images/sha256-f8fef2e091480e0d5e091a77ce5b4b6e0619c351e084c5ce73f265e68265c7ac) as stated in [../Dockerfile](../Dockerfile).

Characteristics:

* OS: Debian
* Contains ruby 3.1.4 (of course)
* Contains NO build tools

Building the docker image results into a smaller image (below 1G)

The docker is built in two phases:

* build phase 1:

  * uses (development) docker image `ruby:3.1.4`
  * installs (development) packages needed to build ruby dependencies
  * builds and installs ruby dependencies into folder `vendor`
  * moves pregenerated folder `ugent/public` to `public`. No asset compilation can be done (see below) here.
  * generates link to precompiled binary `wkhtmltopdf` (provided by ruby gem), and remove other binaries provided by this gem (this gem is heavy). This binary also resides in folder `vendor`

* build phase 2 (final):

  * uses production docker image `ruby:3.1.4-slim`
  * copies generated folder `vendor` from previous phase into `/opt/roadmap/vendor`.
  * installs additional packages.

# Build assets for production (during development)

```
./ugent/bin/build_assets
```

That executable not only compiles the assets for production, but also copies the generated files from folder `public` to `ugent/public`.

The folder `public` is not included in the git repository, `ugent/public` is.

When the production image is built (using `docker build -t roadmap-production .`), that `ugent/public` is moved to `public`.

The reason for this setup, is that for asset compilation (running `bin/rails assets:precompile`), you not only require node, npm or sass,
but also a working rails application with a database connection and credentials etc.

One could also run the asset compilation during the execution of the final production
container, but that would slow down the startup, require a full development
environment (in a production environment) and so generate a bloated image.

# Relation with base repository from DCC

This git repository is a fork of [roadmap](https://github.com/DMPRoadmap/roadmap) from the DCC,
with a lot of local additions, which are documented in detail in [CHANGES.txt](CHANGES.txt),
and in human terms in [CHANGES.md](CHANGES.md).

You will need to add the base repository of the DCC as a git remote.

## update to latest changes from the base repository

If you want to be up to date with the latest changes in the DCC repository,
do the following:

* add base repository as a new git remote (if you haven't already):

```
git remote add dcc https://github.com/DMPRoadmap/roadmap
```

* pull in the latest changes

```
git checkout master
git pull dcc master
```

* resolve any merge conflicts

* read [CHANGES.txt](CHANGES.txt) and see if the changes mentioned are still
  necessary, still work or need update

* always set file format to `dos` if you're using `vi(m)` because the DCC does.
  Setting this to `unix` will show unrelated differences because of different
  line endings.

* read `ugent/TODO.txt` and see if all still apply

## branding information

Necessary steps are taken to make sure that local
additions are kept separate from the files from
the base repository, or to make sure that merge
conflicts are reduced to small parts.

See also [CHANGES.txt](CHANGES.txt) for detailed information

* use of [app/views/branded](../app/views/branded)

  this directory is added to `.gitignore` by the base repo.
  We added additional `.gitignore` files in these directories directly
  to override this, and so reinclude these.

  See also https://github.com/DMPRoadmap/roadmap/wiki/Branding

  Note that any extra templates that are not in the base repository
  are ALSO added here. The mere existence of a template therefore does
  not always imply an accompanying source template

  e.g. [app/views/branded/shared/_dev_sign_in_form.html.erb](../app/views/branded/shared/_dev_sign_in_form.html.erb)

* [config/initializers/ugent.rb](../config/initializers/ugent.rb)

  Reopens existing ruby models/controllers and changes/adds methods

* [app/models/ugent/*.rb](../app/models/ugent/)

  Adds extra models under namespace `Ugent::`
  Tables have namespace `ugent_`

* [app/controllers/ugent.rb](../app/controllers/ugent.rb)

  Adds extra controllers
  Loaded from [config/routes/ugent.rb](../config/routes/ugent.rb) (see below)

* [config/routes/ugent.rb](../config/routes/ugent.rb)

  Adds additional routes
  See also load statement in `config/application.rb`

* [Gemfile.local](../Gemfile.local)

  Adds additional gems
  Loaded from [Gemfile](../Gemfile)

* [Gemfile](../Gemfile)

  File from base repository.
  We add an extra line to include [Gemfile.local](../Gemfile.local)
  Make sure this remains true when merging the upstream branch

  IMPORTANT: look at [ugent/CHANGES.txt](../ugent/CHANGES.txt) for notes about changes
             to the Gemfile. If you have merged upstream changes
             it is possible that, for example, gem "wicked_pdf"
             is loaded from the main gem repository, which is
             a problem (see notes in that file about wicked_pdf)

* [config/initializers/rails_admin.rb](../config/initializers/rails_admin.rb)

  Adds gem [RailsAdmin](https://github.com/sferik/rails_admin)

  RailsAdmin adds a CRUD interface at path `/admin` to edit/preview
  models that cannot be manipulated in any other way in 
  roadmap:
    * model `Ugent::RestUser` which adds organisational REST users
    * model `Ugent::WayflessEntity` (deprecated)
    * associate themes with question options

  Most of the models in the RailsAdmin are read only

* [ugent/public](../ugent/public)

  [ugent/bin/build_assets](../ugent/bin/build_assets) precompiles all assets
  and copies them here, so no precompilation should
  be done on the build server

  Make sure however to set environment variable `EXECJS_RUNTIME`
  to `Disabled` in production, or rails will complain about a missing
  javascript runtime, even in production mode

Old tables added when we used DMPOnline_v4:

* `ugent_org_domains`

* `ugent_logs`

* `ugent_wayfless_entities`

* `ugent_rest_users`

# Technical model overview

A handy overview of the available models, and their attributes:

* https://github.com/DMPRoadmap/roadmap/wiki/DB-Schema
* https://github.com/DMPRoadmap/roadmap/issues/1382#issuecomment-405252771

# Development within Mac OS X

* Install [RVM](https://rvm.io/) as a ruby version manager:

  ```
  \curl -sSL https://get.rvm.io | bash -s stable
  ```

  * Let RVM build ruby: `rvm install ruby-3.0.5`

  * Step into your application, and RVM will set the right ruby instance

* Install ruby dependencies:

```
gem install bundler:2.1.4
bundle _2.1.4_ config set --local path "vendor/bundle"
bundle _2.1.4_ config set --local with "mysl,puma"
bundle _2.1.4_ config set --local without pgsql
bundle _2.1.4_ install
```

* Install `yarn`

```
brew install yarn
```

* Install nodejs dependencies: `yarn install`

* Set database connection details in `config/database.yml`:

```
default: &default
  adapter: mysql2
  database: roadmap
  username: roadmap
  password: roadmap
  encoding: utf8mb4

development: *default
production: *default
```

* Add or update the encrypted `config/credentials.yml.enc` ..

```
EDITOR=vim bin/rails credentials:edit
```

and edit

```
# Used as the base secret for all MessageVerifiers in Rails, including the one protecting cookies.
secret_key_base: "replace_with_your_secret_key"

# used in config/initializers/devise.rb
devise_pepper: "replace_with_your_pepper"

#used in config/initializers/dragonfly.rb
dragonfly_secret: "replace_with_your_dregaonfly_secret"

# used in recaptcha.rb
recaptcha:
 site_key: 'replace_this_with_your_public_key'
 secret_key: 'replace_this_with_your_private_key'
```

This will generate a `config/master.key` which should NOT be included
in the git repository.

The encrypted `config/credentials.yml.enc` is a Rails 5.2 replacement
of `config/secrets.yml`. Rails expects you to include this file
(and not the master.key) in git.

* Start application

```
bin/rails server
```
