<div class="card mb-4" markdown="1">

<div class="card-header" markdown="1">
## Release Notes v5.0.0-beta-spr0021
</div>
<div class="card-body" markdown="1">

**Note:** From DMPonline.be v5.0.0 onwards Belnet will follow its own versioning, but we mention the used DMPRoadmap version.

### Main goals
- Upgrade foundation to DMPRoadmap version v5.0.2.
- Add governance features, both in the user interface (UI) and via application programming interface (API).
- Extend documentation.

### Functional changes
- Governance features:
  - The posibility to create *versions of DMP's* (read-only snapshots),
  so reviewers can work on a read-only version, while researchers can still proceed with the editable version.
    - You can find created versions under the extra **History** tab.
    - You can visual compare versions with the **Compare** button (only UI).
  - The possibility to add and change a *lifecycle stage* of a DMP.
    - You could start with it on existing DMPs without the requirement to add a version.
    - DMP versions have always a lifecycle stage attribute.
  - The possibility to *request a validation* on a DMP version on a specific topic, under the extra **Validations** tab.
  - There are default values for *lifecycle stages*, *validation topics* and *validation statuses*.  
    But they are configurable: organisations can ask Belnet to add or replace values for their organisation.
  - All these governance features, except for version compare, have an API variant. Consult the **API Reference** for more details.
- Documentation under the **Help** menu is expanded:
  * **Getting started**: The initial steps to start with DMPonline.be.
  * **Concepts**: Learn the parts of the DMPonline.be system to obtain a deeper understanding of how it works.
  * **User Guide**: More in depth guidance on how to use DMPonline.be.
  * **Admin Guide**: Guidance on how to administer DMPonline.be for your organisation.
  * **API Reference**: Reference information on the different DMPonline.be APIs.
  * **Technology stack**: Technical details on the DMPonline.be application.
  * **What's New**: What is changed with latest deployment.

### Resolved issues
- Admin panel is again accessible. Caused by timestamptz (Time Stamp Time Zone) not correctly being able to be read.
- Fix Organizations index page items query: took very long before and sometimes the application hangs.
- Fix crash when logging in via ORCID and no email address is provided (email is not made public yet).

### Other changes without functional impact
- Upgrade to latest available DMPRoadmap version: from 4.2.0 to 5.0.2 (Rails 7.1.x and Ruby 3.1.x).
- Moved code from large `module_overrides.rb` file to their own classes.
- Updated docker files for both development and production.
- Added Mailhog service to capture outgoing emails in non-production environments.
- Added script (rails task) for creating and removing test users in non-production environments.
- Added script (rails task) for creating and updating the default values for *lifecycle stages*, *validation topics* and *validation statuses*.

### Known limitations

</div>
</div>