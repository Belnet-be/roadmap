<div class="card mb-4" markdown="1">

<div class="card-header" markdown="1">

## Release Notes v5.0.3 (Planned 15 Oct 2026)

</div>
<div class="card-body" markdown="1">

### Main goals
- Upgrade foundation to DMPRoadmap version v5.0.3, resolving two security issues.

### Resolved issues
- API: Fix time period filter being silently ignored if wrong value was provided in URL parameter.
- Documentation: Update [API Belnet v1](/help-reference-api-belnet-v1) to v1.0.1 for changed default validation topics and time period filter fix.
- Documentation: Add existing functionality that org admins can do topic validation of DMPs, see [Can Admins review validation requests?](/help-admin-guide#can-admins-review-validation-requests)
- Fix crash, caused by missing dragonfly file, when admins update organisation details and click Save button.
- Fix template duplicate bug in /plans pages for users and org admins.
- Fix more ORCID issues. Current behavior:
  - Only verified ORCID emails that are made visible ("Everyone" / "trusted parties") will count in ORCID validation.
    - If configured email in existing DMPonline account is not or no longer a verified ORCID email, the login is now refused with explanation (caused crash before, fixed in DMPonline v5.0.0).
  - If one visible verified ORCID email address, user is logged in automatically:
    - If no DMPonline account yet with that email -> account gets created with ORCID identifier linked (was already).
    - If existing DMPonline account with that email, but no ORCID linked yet -> ORCID identifier linked automatically (new).
  - If two or more visible verified ORCID email addresses, show a choice list, one option per ORCID email address (new):
    - Those that have linked DMPonline accounts, show "log in" option.
    - Those without linked DMPonline accounts, show "create new account" option.
    - The choice expires after 15 minutes.

### Other changes without functional impact
- Use dashes instead of underscores for help guides URLs, route two old URLs to new ones.
- Cleanup old documentation pages.

</div>
</div>

<div class="card mb-4" markdown="1">

<div class="card-header" markdown="1">

## Release Notes v5.0.2 (01 Oct 2026)

</div>
<div class="card-body" markdown="1">

### Resolved issues
- v5.0.2: ORCID accounts are again fully supported: registration of new accounts, link to existing accounts and ORCID login.

</div>
</div>

<div class="card mb-4" markdown="1">

<div class="card-header" markdown="1">

## Release Notes v5.0.1 (25 Sep 2026)

</div>
<div class="card-body" markdown="1">

### Resolved issues
- v5.0.1: Temporary hotfix to allow users already registered with ORCID account to log in again.

</div>
</div>

<div class="card mb-4" markdown="1">

<div class="card-header" markdown="1">

## Release Notes v5.0.0 (24 Sep 2026)

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
  so reviewers can work on a read-only version, while researchers can still proceed with the *Live Version* (editable version).
    - You can find created versions under the extra **History** tab.
    - You can visual compare versions with the **Compare** button (only UI).
  - The possibility to add and change a *lifecycle stage* of a DMP.
    - You could start with it on existing DMPs without the requirement to add a version.
    - DMP versions have always a lifecycle stage attribute.
  - The possibility to *request a validation* on a DMP version on a specific topic, under the extra **Validations** tab.
  - There are default values for *lifecycle stages*, *validation topics* and *validation statuses*.  
    But they are configurable: organisations can ask Belnet to add or replace values for their organisation.
  - All these governance features, except for version compare, have an API variant. Consult the **API Reference** for more details.
  - All these governance features are also added when you **Download** a plan:
    - For the Live Version the lifecycle stage is added.
    - For a DMP version next to the lifecycle stage also the version number, the version reason,
    and at the end of the pdf its topic validations are added.
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
- DMPonline receiving email address is changed, but also removed from UI. Users are advised to use the **Contact Us** form.

### Known limitations
- While in the user interface of the DMPonline application you can filter on *plan visibility*, this is not supported via this API endpoint because we can't inform you about the setting with the current maDMP schema.

</div>
</div>