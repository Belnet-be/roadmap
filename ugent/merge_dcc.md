# Before starting ..

Before starting, it is best to merge branch `setup_dev_remove_gdpr_export` into branch `setup_dev`.
While it is not strictly necessary, it will remove a bunch of local code that will no longer apply
in the future, because we no longer need it:

```
git fetch --all
git checkout setup_dev
git merge setup_dev_remove_gdpr_export
```

Note to self: remove any references to gdpr export from `ugent/CHANGES.txt`

# Merge upstream DCC

If you want to be up to date with the latest changes in the DCC repository,
add the upstream repository as a new git remote (if you haven't already):

```
git remote add dcc https://github.com/DMPRoadmap/roadmap
```

Now merge upstream [release v5.0.0](https://github.com/DMPRoadmap/roadmap/releases/tag/v5.0.0)
into the current branch (setup_dev):

```
git pull dcc v5.0.0
```

The merge does not succeed fully, because Cyrille (from Belnet)
removed Gemfile.lock and committed, while in the dcc branch that file
is still tracked:

```
$ git show 4a5249031be8c4ce918e4be03bf979fa95915b20

commit 4a5249031be8c4ce918e4be03bf979fa95915b20
Author: Cyrille Bollu <cyrille@debian-BULLSEYE-live-builder-AMD64>
Date:   Wed Apr 24 11:25:33 2024 +0200

    No need of Gemfile.lock since everything is in docker now

    Signed-off-by: Cyrille Bollu <cyrille@debian-BULLSEYE-live-builder-AMD64>

diff --git a/Gemfile.lock b/Gemfile.lock
deleted file mode 100644
index e6a13c30..00000000
--- a/Gemfile.lock
+++ /dev/null
@@ -1,635 +0,0 @@
-GEM
-  remote: https://rubygems.org/
...
```

To fix this, abort the current merge ..

```
git merge --abort
```

and revert that faulty commit

```
git revert 4a5249031be8c4ce918e4be03bf979fa95915b20
```

Try to merge again

```
git pull dcc v5.0.0
```

The merge fails on a conflicting `db/schema.db`. This is normal due to our
extra tables. Because we never recreate the database schema using the rails
tools, checkout the upstream version:

```
git checkout --theirs db/schema.db
```

The merge is successful.

Now check if everything is ok. Check full change log between the previous roadmap version and the new one: https://github.com/DMPRoadmap/roadmap/compare/v4.2.0...v5.0.0

Because this release is only an upgrade to Rails 7, these checks sufficed:

- Is the `Gemfile.local` (our local gem dependencies) still included at the bottom of `Gemfile`? The contents of `Gemfile.lock` will be overwritten after the first `bundle install`, but that is expected

- due to upgrade to Rails 7, something like `require "plan"` no longer works, because models are no longer available in the search path during the initialization phase of rails. This breaks our overrides stored in `config/initializers/ugent.rb`. In order to fix this, do the following:

  - copy `config/initializers/ugent.rb` to `ugent/lib/module_overrides.rb` (example):
  
  ```
  mkdir ugent/lib
  cp config/initializers/ugent.rb ugent/lib/module_overrides.rb
  ```

  - replace contents of `config/initializers/ugent.rb` by

  ```
  Rails.application.config.to_prepare do
    require_relative '../../ugent/lib/module_overrides.rb'
  end
  ```

  - now remove all `require` statements from `ugent/lib/module_overrides.rb`

- change to app/controllers/api/v0/plans_controller.rb is a fix I submitted, and then fixed prematurely in the local code. This merged automatically. See https://github.com/DMPRoadmap/roadmap/pull/3325. This local change can be removed from `ugent/CHANGES.txt

- no changes to `app/views`, so not need to compare changes in the views

Clear your previous installed node modules and gems (not necessary)..

```
rm -rvf vendor modules tmp/cache
```

and restart docker compose

```
docker compose up
```

You'll notice changes made to `public/tinymce`. This is done by `config/initializers/assets.rb`. That is fixed in release 5.0.2.

# Compare branded views if needed

For every view in `views/app/branded`, see if the difference with the upstream version
is still the same as reported in `ugent/CHANGES.txt`

## example 1

```
$ diff app/views/user_mailer/_email_signature.html.erb app/views/branded/user_mailer/_email_signature.html.erb
12c12
<   <%= _('The %{tool_name} team') %{ tool_name: tool_name} %>
---
>   The DMPonline.be team
```

`ugent/CHANGES.txt` states:

```
just changes the team name
```

## example 2

```
$ diff app/views/plans/_navigation.html.erb app/views/branded/plans/_navigation.html.erb
7,10d6
<   <li role="contributors" class="nav-item <%= (active_page?(plan_contributors_path(plan)) ? "active" : "") %>">
<     <%= link_to _("Contributors"), plan_contributors_path(plan), role: "tab",
<                 aria: { controls: "content" }, class: 'nav-link' %>
<   </li>
```

`ugent/CHANGES.txt` states:

```
hide link to tab "contributors"

always show phase title (original shows "Write plan" when there is only one phase).

  cf. https://github.com/DMPbelgium/roadmap/issues/63
  cf. https://github.com/DMPbelgium/roadmap/issues/20
```

## example 3

```
$ diff app/views/org_admin/shared/_theme_selector.html.erb app/views/branded/org_admin/shared/_theme_selector.html.erb
5a6,17
> <%
>   # HIDE special themes
>   hidden_themes = []
>   visible_themes = []
>   all_themes.each { |theme|
>     if theme.title.start_with?("UGENT:") || theme.title.start_with?("https://w3id.org/GDPRtEXT#")
>       hidden_themes << theme
>     else
>       visible_themes << theme
>     end
>   }
> %>
7c19,27
<   <% if all_themes.length > 0 %>
---
>   <% hidden_themes.each do |theme| %>
>     <% next unless f.object.themes.include?(theme) %>
>     <% namespace = f.object.class.name.downcase %>
>     <input id="<%= f.object.id %>_<%= namespace %>_theme_ids_<%= theme.id %>"
>            name="<%= namespace %>[theme_ids][]"
>            type="hidden"
>            value="<%= theme.id %>">
>   <% end %>
>   <% if visible_themes.length > 0 %>
11c31
<       nbr_of_cols = (all_themes.length.to_f / per_col.to_f).ceil
---
>       nbr_of_cols = (visible_themes.length.to_f / per_col.to_f).ceil
19a40
> 
22c43
<         <% all_themes.each do |theme| %>
---
>         <% visible_themes.each do |theme| %>
34c55
<                    <%= required && (theme == all_themes.first ? ' aria-required=true ' : '') %>
---
>                    <%= required && theme == visible_themes.first ? ' aria-required=true ' : '' %>
```

`ugent/CHANGES.txt` states:

```
removes special themes from array "all_themes" so

  that these are not visible in the org admin interface.

  Those invisible themes are added of course to the form

  as hidden inputs though

  Affected:

  * edit question

  * edit guidance

  Reason:

  * themes with title  `UGENT:*` are ugent specific and are only added for the GDPR export

  * themes with title "https://w3id.org/GDPRtEXT#*" are ugent specific
```

## example 4

Do not worry about the big differences for these "static" pages. These are expected. 

* app/views/branded/static_pages/about_us.html.erb
* app/views/branded/static_pages/termsuse.html.erb
* app/views/branded/static_pages/help.html.erb
* app/views/branded/static_pages/privacy.html.erb