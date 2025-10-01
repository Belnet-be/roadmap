# Setup development Environment with docker

* Install [Docker Desktop](https://www.docker.com/products/docker-desktop/)

* Start Docker desktop

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

* On first startup rails with try to create all tables using `rails db:migrate`.

Stop docker compose, manually start up the mysql container individually

**DO NOT create a new database**, as stated in the wiki from roadmap.
This repository depends on a database, migrated from DMPOnline_v4 (with local additions),
that has more attributes than the regular one.

[Migrated data](https://btadoredev.ugent.be/roadmap.sql.gz) will be provided

```
gunzip -c roadmap.sql.gz | mysql --user=root --password=root --host=0.0.0.0 --port=3307
```

* Fully restart docker compose

# Login to the application

* Login into docker console `roadmap-dev`, and your self as user

```
$ cd /opt/roadmap
$ bin/rails console

> u = User.new(email: "reinout.koninkx@agilearchitects.be", firstname: "Reinout", surname: "Koninkx")
> u.perms = Perm.all
> u.password = u.email
> u.password_confirmation
> u.save!
```

* Now you are a member of organisation "guests". Add yourself to organisation "UGent":

This happens because the system could not find an association of your
email's domain with any organization. Let's fix that manually:

```
> org = Org.where(managed: true, abbreviation: "UGent").first
> u.org_id = org.id
> u.save!
```

* Or add your email domain to the list of domains automatically associated with organisation "UGent":

Create a domain assocation, and set the `org_id` back to `nil`. On save the system
will reassign the organization automatically.

```
> org = Org.where(managed: true, abbreviation: "UGent").first
> org_domain = Ugent::OrgDomain.new(name: "agilearchitects.be", org_id: org.id)
> org_domain.save!
> u.org = nil
> u.save!
```

Although you deleted your associated organisation, due to association of that email domain,
organization "UGent" is automatically (re)assigned to your user. Note that this only happens
when `org_id` is not set.

# Build assets for production

```
ugent/bin/build_assets
```

That executable not only compiles the assets for production, but also copies the files to `ugent/public`,
so that the build server does not require node, npm or sass.

# Relation with base repository from DCC

This git repository is a fork of [roadmap](https://github.com/DMPRoadmap/roadmap) from the DCC,
with a lot of local additions, which are documented in `ugent/CHANGES.txt`

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

* read ugent/CHANGES.txt and see if the changes mentioned are still
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

See also `ugent/CHANGES.txt` for detailed information

* use of `app/views/branded`

  this directory is added to `.gitignore` by the base repo.
  We add additional `.gitignore` files in these directories directly
  to override this, and so reinclude these.

  See also https://github.com/DMPRoadmap/roadmap/wiki/Branding

  Note that any extra templates that are not in the base repository
  are ALSO added here. The mere existence of a template therefore does
  not always imply an accompanying source template

  e.g. app/views/branded/shared/_dev_sign_in_form.html.erb

* `config/initializers/ugent.rb`

  Reopens existing ruby models/controllers and changes/adds methods

* `app/models/ugent/*.rb`

  Adds extra models under namespace Ugent::
  Tables have namespace ugent_

* `app/controllers/ugent.rb`

  Adds extra controllers
  Loaded from `config/routes/ugent.rb` (see below)

* `config/routes/*.rb`

  Adds additional routes
  See also load statement in `config/application.rb`

* `Gemfile.local`

  Adds additional gems
  Loaded from `Gemfile`

* `Gemfile`

  File from base repository.
  We add an extra line to include `Gemfile.local`
  Make sure this remains true when merging the upstream branch

  IMPORTANT: look at ugent/CHANGES.txt for notes about changes
             to Gemfile. If you have merged upstream changes
             it is possible that, for example, gem "wicked_pdf"
             is loaded from the main gem repository, which is
             a problem (see notes in that file about wicked_pdf)

* `config/initializers/rails_admin.rb`

  Adds [RailsAdmin](https://github.com/sferik/rails_admin)
  RailsAdmin adds a CRUD interface at path /admin to edit/preview
  models that cannot be manipulated in any other way in 
  roadmap:
    * model `Ugent::RestUser` which adds organisational REST users
    * model `Ugent::WayflessEntity` (deprecated)
    * associate themes with question options
  Most of the models in the RailsAdmin are read only

* `ugent/public`

  `ugent/bin/build_assets` precompiles all assets
  and copies them here, so no precompilation should
  be done on the build server

  Make sure however to set environment variable `EXECJS_RUNTIME`
  to `Disabled`, or rails will complain about missing
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
